package com.bloom.wadhakir

/**
 * The decisions behind [QiblaBridge], kept free of Android types so plain JVM
 * tests can pin them.
 *
 * The one that matters is the accuracy mapping. It is the only thing that
 * decides whether a user is asked to wave their phone in a figure 8, and a
 * wrong mapping fails silently in both directions: a nag on a calibrated phone,
 * or no help on a compass that is pointing the wrong way.
 */
object QiblaSensorRules {

    // SensorManager.SENSOR_STATUS_* — copied as literals so this object loads
    // without android.jar; QiblaSensorRulesTest checks them against the SDK.
    const val STATUS_NO_CONTACT = -1
    const val STATUS_UNRELIABLE = 0
    const val STATUS_ACCURACY_LOW = 1
    const val STATUS_ACCURACY_MEDIUM = 2
    const val STATUS_ACCURACY_HIGH = 3

    // The scale Dart reads (CompassAccuracyLevel.fromDegrees): the same
    // numbers flutter_compass uses for its own accuracy field.
    const val HIGH_DEGREES = 15
    const val MEDIUM_DEGREES = 30
    const val LOW_DEGREES = 45
    const val UNKNOWN_DEGREES = -1

    /**
     * A magnetometer status as an error estimate in degrees.
     *
     * UNRELIABLE counts as LOW, not unknown: it is the sensor saying outright
     * that it needs calibrating, which is exactly when the figure-8 card helps.
     * NO_CONTACT and anything unrecognised are unknown, and unknown never shows
     * the card.
     */
    fun accuracyDegrees(status: Int): Int = when (status) {
        STATUS_ACCURACY_HIGH -> HIGH_DEGREES
        STATUS_ACCURACY_MEDIUM -> MEDIUM_DEGREES
        STATUS_ACCURACY_LOW, STATUS_UNRELIABLE -> LOW_DEGREES
        else -> UNKNOWN_DEGREES
    }

    /**
     * Send only changes. Every magnetometer event carries its accuracy, at UI
     * rate; forwarding each one would wake Dart dozens of times a second to
     * say nothing new.
     */
    fun shouldEmit(lastSent: Int?, next: Int): Boolean = lastSent != next

    /** A finite latitude and longitude inside their ranges. */
    fun isValidPosition(latitude: Double?, longitude: Double?): Boolean =
        latitude != null && longitude != null &&
            latitude.isFinite() && longitude.isFinite() &&
            latitude in -90.0..90.0 && longitude in -180.0..180.0

    /**
     * The altitude to hand GeomagneticField. Unknown or absurd values become
     * sea level: the declination changes by hundredths of a degree per
     * kilometre of height, so a wrong altitude costs nothing, while NaN would
     * poison the whole result.
     */
    fun altitudeMeters(altitude: Double?): Float {
        if (altitude == null || !altitude.isFinite()) return 0f
        return altitude.coerceIn(-1_000.0, 10_000.0).toFloat()
    }

    /** The smallest camera-heading change worth sending to Dart. */
    const val CAMERA_HEADING_STEP_DEGREES = 0.3

    /** Folds radians from getOrientation (−π..π) into 0..360 degrees. */
    fun azimuthDegrees(radians: Double): Double {
        val degrees = Math.toDegrees(radians) % 360.0
        return if (degrees < 0) degrees + 360.0 else degrees
    }

    /**
     * Whether a camera heading moved enough to send, measured the short way
     * round so 359.9 → 0.1 is a 0.2° step, not 359.8°.
     */
    fun shouldEmitHeading(lastSent: Double?, next: Double): Boolean {
        if (lastSent == null) return true
        var delta = Math.abs(next - lastSent) % 360.0
        if (delta > 180.0) delta = 360.0 - delta
        return delta >= CAMERA_HEADING_STEP_DEGREES
    }
}
