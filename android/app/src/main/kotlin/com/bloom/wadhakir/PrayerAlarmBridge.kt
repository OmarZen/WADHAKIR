package com.bloom.wadhakir

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * The Dart → Kotlin transport for the prayer schedule.
 *
 * A sweep is a transaction: `clear` opens it, `arm` buffers one alarm, `commit`
 * applies the whole thing. Nothing touches storage or AlarmManager until the
 * commit, for two reasons.
 *
 * **Cost.** Sixty days is three hundred alarms. Persisting on each one would
 * rewrite a growing JSON document three hundred times — quadratic work and
 * three hundred disk writes for one reschedule.
 *
 * **Safety.** Until the commit lands, the previously committed schedule is
 * still armed and still in the ledger. A sweep interrupted halfway — the app
 * killed, the engine torn down — costs nothing at all. The alternative, where
 * `clear` cancels immediately, has a window in which the user has no adhan
 * armed and no app running to arm one.
 */
object PrayerAlarmBridge {

    const val CHANNEL_NAME = "com.bloom.wadhakir/prayer_alarms"

    private const val TAG = "PrayerAlarms"

    /**
     * Applies commits off the platform thread.
     *
     * Single-threaded on purpose: two commits interleaving would race on the
     * ledger, and a reschedule can be triggered from several listeners at once.
     */
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    /** The sweep being built. Guarded by [lock]; written from the platform thread. */
    private val pending = mutableListOf<PrayerAlarm>()
    private val lock = Any()

    fun register(context: Context, messenger: BinaryMessenger) {
        val appContext = context.applicationContext
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                // Reaching this handler at all is the proof. A build without the
                // native side raises MissingPluginException on the Dart side,
                // which is what the gateway treats as "not available".
                "isAvailable" -> result.success(true)

                "clear" -> {
                    synchronized(lock) { pending.clear() }
                    result.success(null)
                }

                "arm" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<String, Any?>
                    val alarm = args?.let { PrayerAlarm.fromChannel(it) }
                    if (alarm == null) {
                        // One unreadable row costs one adhan. Failing the call
                        // would degrade the whole session to the plugin path.
                        Log.w(TAG, "Dropped an unreadable alarm from Dart")
                    } else {
                        synchronized(lock) { pending.add(alarm) }
                    }
                    result.success(null)
                }

                "commit" -> {
                    val snapshot = synchronized(lock) { pending.toList().also { pending.clear() } }
                    runOffThread(result) {
                        PrayerAlarmStore.replaceAll(appContext, snapshot)
                        PrayerAlarmScheduler.rearmWindow(appContext, System.currentTimeMillis())
                        if (snapshot.isEmpty()) {
                            PrayerAlarmReconcileWorker.cancel(appContext)
                        } else {
                            PrayerAlarmReconcileWorker.enqueue(appContext)
                        }
                    }
                }

                "purge" -> {
                    synchronized(lock) { pending.clear() }
                    runOffThread(result) {
                        PrayerAlarmScheduler.cancelAll(appContext)
                        PrayerAlarmReconcileWorker.cancel(appContext)
                    }
                }

                "consumePendingTap" -> result.success(PrayerAlarmStore.consumePendingTap(appContext))

                else -> result.notImplemented()
            }
        }

        // A tap that cold-started the app may already be waiting; Dart collects
        // it with consumePendingTap once its router exists.
    }

    /**
     * Runs [work] on the executor and answers on the platform thread.
     *
     * A failure is reported as an error rather than swallowed: the Dart gateway
     * uses it to fall back to the plugin path, and a commit that silently did
     * nothing would leave the user with no alarms and no signal that anything
     * was wrong.
     */
    private fun runOffThread(result: MethodChannel.Result, work: () -> Unit) {
        executor.execute {
            try {
                work()
                mainHandler.post { result.success(null) }
            } catch (e: Exception) {
                Log.e(TAG, "Prayer alarm operation failed", e)
                mainHandler.post { result.error("PRAYER_ALARM_FAILED", e.message, null) }
            }
        }
    }
}
