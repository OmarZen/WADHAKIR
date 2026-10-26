package com.bloom.wadhakir

import android.app.Activity
import android.content.Context
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * The native half of the Qibla compass: two things no Flutter plugin in this
 * app provides.
 *
 * **Declination.** flutter_compass on Android reports a heading from MAGNETIC
 * north and never corrects it, while the qibla bearing is from TRUE north. The
 * gap is the local declination — about 5° in Cairo, more than 10° across much
 * of North America — and without it every Android user's arrow is off by that
 * much. [GeomagneticField] is the OS's own World Magnetic Model: no data table
 * to ship, no network, updated with the OS.
 *
 * **Calibration.** flutter_compass's accuracy is whichever of the accelerometer
 * and the magnetometer reported last, so a perfectly calibrated accelerometer
 * routinely hides a magnetometer that needs a figure 8. The accuracy stream
 * here listens to the magnetometer alone, and only while Dart listens.
 *
 * **The camera's heading (AR).** flutter_compass changes what its heading
 * means at 45° of tilt: below that it is where the camera points, above it
 * where the phone's top edge points. With the camera aimed at the floor, a
 * slight sideways tilt then turns the top edge, so the virtual rug swung and
 * "aligned" flickered while the user stood still. The camera stream here is
 * always where the camera points.
 *
 * Dart treats every failure here as soft (declination 0, magnetometer assumed,
 * accuracy unknown, compass heading instead of the camera's), so nothing in
 * this file can take the compass down.
 *
 * Channels: method `com.bloom.wadhakir/qibla` (`declination`,
 * `hasMagnetometer`), event `com.bloom.wadhakir/qibla_mag_accuracy`
 * (15 / 30 / 45 / -1, see [QiblaSensorRules.accuracyDegrees]) and event
 * `com.bloom.wadhakir/qibla_camera_heading` (degrees from magnetic north).
 */
object QiblaBridge {

    const val CHANNEL_NAME = "com.bloom.wadhakir/qibla"
    const val ACCURACY_CHANNEL_NAME = "com.bloom.wadhakir/qibla_mag_accuracy"
    const val CAMERA_HEADING_CHANNEL_NAME = "com.bloom.wadhakir/qibla_camera_heading"

    private const val TAG = "QiblaBridge"

    /**
     * Application context only: the stream outlives any one Activity when the
     * cached engine is reattached, and holding an Activity here would leak it.
     */
    @Volatile
    private var appContext: Context? = null

    fun register(activity: Activity, messenger: BinaryMessenger) {
        val context = activity.applicationContext
        appContext = context

        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "declination" -> {
                    // Read as Number: Dart sends doubles, but a whole-number
                    // coordinate must not turn into a ClassCastException.
                    val latitude = call.argument<Number>("latitude")?.toDouble()
                    val longitude = call.argument<Number>("longitude")?.toDouble()
                    val altitude = call.argument<Number>("altitude")?.toDouble()
                    if (!QiblaSensorRules.isValidPosition(latitude, longitude)) {
                        result.error("bad_args", "latitude/longitude missing or out of range", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val field = GeomagneticField(
                            latitude!!.toFloat(),
                            longitude!!.toFloat(),
                            QiblaSensorRules.altitudeMeters(altitude),
                            System.currentTimeMillis(),
                        )
                        result.success(field.declination.toDouble())
                    } catch (e: Exception) {
                        Log.w(TAG, "GeomagneticField failed", e)
                        result.error("declination_failed", e.message, null)
                    }
                }

                "hasMagnetometer" -> result.success(hasMagnetometer(context))

                else -> result.notImplemented()
            }
        }

        // One handler object for the life of the process: if the Activity is
        // recreated on the same engine, Dart's existing subscription keeps its
        // sink and its sensor listener instead of being orphaned.
        EventChannel(messenger, ACCURACY_CHANNEL_NAME).setStreamHandler(AccuracyStream)
        EventChannel(messenger, CAMERA_HEADING_CHANNEL_NAME).setStreamHandler(CameraHeadingStream)
    }

    /**
     * True unless the phone positively has no magnetometer. An error asking
     * counts as true: hiding a working compass is the worse mistake.
     */
    private fun hasMagnetometer(context: Context): Boolean = try {
        context.getSystemService(SensorManager::class.java)
            ?.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) != null
    } catch (e: Exception) {
        Log.w(TAG, "hasMagnetometer failed, assuming yes", e)
        true
    }

    /**
     * Streams the magnetometer's accuracy, changes only, while Dart listens.
     *
     * Sensor callbacks arrive on the main looper (no Handler is passed to
     * registerListener), which is the thread an EventSink must be called on.
     */
    private object AccuracyStream : EventChannel.StreamHandler, SensorEventListener {

        private var sink: EventChannel.EventSink? = null
        private var manager: SensorManager? = null
        private var lastSent: Int? = null

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            stopSensor()
            sink = events
            lastSent = null
            val sensorManager = try {
                appContext?.getSystemService(SensorManager::class.java)
            } catch (e: Exception) {
                Log.w(TAG, "SensorManager unavailable", e)
                null
            }
            val sensor = sensorManager?.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
            if (sensorManager == null || sensor == null) {
                emit(QiblaSensorRules.STATUS_NO_CONTACT)
                return
            }
            // UI rate is plenty: only the accuracy field of each event is read.
            val registered = try {
                sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
            } catch (e: Exception) {
                Log.w(TAG, "registerListener failed", e)
                false
            }
            if (registered) {
                manager = sensorManager
            } else {
                emit(QiblaSensorRules.STATUS_NO_CONTACT)
            }
        }

        override fun onCancel(arguments: Any?) {
            stopSensor()
            sink = null
            lastSent = null
        }

        override fun onSensorChanged(event: SensorEvent) {
            emit(event.accuracy)
        }

        override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
            emit(accuracy)
        }

        private fun emit(status: Int) {
            val degrees = QiblaSensorRules.accuracyDegrees(status)
            if (!QiblaSensorRules.shouldEmit(lastSent, degrees)) return
            lastSent = degrees
            try {
                sink?.success(degrees)
            } catch (e: Exception) {
                // A sink whose engine has gone away; stop paying for the sensor.
                Log.w(TAG, "accuracy sink failed, stopping", e)
                stopSensor()
                sink = null
            }
        }

        private fun stopSensor() {
            try {
                manager?.unregisterListener(this)
            } catch (e: Exception) {
                Log.w(TAG, "unregisterListener failed", e)
            }
            manager = null
        }
    }

    /**
     * Streams where the back camera points, degrees from magnetic north, while
     * Dart listens.
     *
     * The rotation vector remapped with (AXIS_X, AXIS_Z) is Android's own
     * recipe for a camera held up at the world: its azimuth follows the
     * camera's axis at every tilt up to nearly straight down, which the AR
     * step never reaches (it wants 30°–75°). A phone without the sensor gets
     * an error instead, and Dart falls back to the compass heading.
     */
    private object CameraHeadingStream : EventChannel.StreamHandler, SensorEventListener {

        private var sink: EventChannel.EventSink? = null
        private var manager: SensorManager? = null
        private var lastSent: Double? = null
        private val rotation = FloatArray(9)
        private val remapped = FloatArray(9)
        private val orientation = FloatArray(3)

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            stopSensor()
            sink = events
            lastSent = null
            val sensorManager = try {
                appContext?.getSystemService(SensorManager::class.java)
            } catch (e: Exception) {
                Log.w(TAG, "SensorManager unavailable", e)
                null
            }
            val sensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
            if (sensorManager == null || sensor == null) {
                events?.error("no_rotation_vector", "No rotation vector sensor", null)
                return
            }
            val registered = try {
                sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
            } catch (e: Exception) {
                Log.w(TAG, "registerListener failed", e)
                false
            }
            if (registered) {
                manager = sensorManager
            } else {
                events?.error("no_rotation_vector", "Rotation vector unavailable", null)
            }
        }

        override fun onCancel(arguments: Any?) {
            stopSensor()
            sink = null
            lastSent = null
        }

        override fun onSensorChanged(event: SensorEvent) {
            try {
                SensorManager.getRotationMatrixFromVector(rotation, event.values)
                SensorManager.remapCoordinateSystem(
                    rotation,
                    SensorManager.AXIS_X,
                    SensorManager.AXIS_Z,
                    remapped,
                )
                SensorManager.getOrientation(remapped, orientation)
            } catch (e: Exception) {
                Log.w(TAG, "camera heading maths failed", e)
                return
            }
            val degrees = QiblaSensorRules.azimuthDegrees(orientation[0].toDouble())
            if (!QiblaSensorRules.shouldEmitHeading(lastSent, degrees)) return
            lastSent = degrees
            try {
                sink?.success(degrees)
            } catch (e: Exception) {
                Log.w(TAG, "camera heading sink failed, stopping", e)
                stopSensor()
                sink = null
            }
        }

        override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) = Unit

        private fun stopSensor() {
            try {
                manager?.unregisterListener(this)
            } catch (e: Exception) {
                Log.w(TAG, "unregisterListener failed", e)
            }
            manager = null
        }
    }
}
