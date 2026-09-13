package com.bloom.wadhakir

import android.content.Context
import android.media.RingtoneManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
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
                        cacheDefaultSoundUri(appContext)
                        PrayerAlarmStore.replaceAll(appContext, snapshot)
                        PrayerAlarmScheduler.rearmWindow(appContext, System.currentTimeMillis())
                        if (snapshot.isEmpty()) {
                            PrayerAlarmReconcileWorker.cancel(appContext)
                        } else {
                            PrayerAlarmReconcileWorker.enqueue(appContext)
                        }
                    }
                }

                // --- the persistent "next prayer" card (roadmap #13) ---------
                //
                // Posted from Kotlin because `awesome_notifications` exposes
                // neither chronometer flag, and the chronometer is the entire
                // point: it is what turns 86,400 posts a day into one per
                // prayer. See PersistentPrayerNotifier.
                "showPersistent" -> {
                    val format = call.argument<String>("titleFormat")
                    val prayerName = call.argument<String>("prayerName")
                    val body = call.argument<String>("body") ?: ""
                    val at = (call.argument<Number>("prayerAtEpochMs"))?.toLong()
                    if (format == null || prayerName == null || at == null) {
                        result.error("PRAYER_ALARM_BAD_ARGS", "showPersistent needs a format, a name and an instant", null)
                    } else {
                        // Off the platform thread like every other write here:
                        // PrayerAlarmStore opens device-protected storage, and
                        // the first open in a process can run the one-time
                        // moveSharedPreferencesFrom migration.
                        runOffThread(result) {
                            // Stored as well as shown: the receiver rolls this
                            // card forward as each alarm fires, with no engine
                            // alive to ask Dart what the title should say.
                            PrayerAlarmStore.setPersistentConfig(appContext, enabled = true, titleFormat = format)
                            PersistentPrayerNotifier.show(appContext, format, prayerName, body, at)
                        }
                    }
                }

                "hidePersistent" -> {
                    runOffThread(result) {
                        PrayerAlarmStore.setPersistentConfig(appContext, enabled = false, titleFormat = null)
                        PersistentPrayerNotifier.hide(appContext)
                    }
                }

                "purge" -> {
                    synchronized(lock) { pending.clear() }
                    runOffThread(result) {
                        PrayerAlarmScheduler.cancelAll(appContext)
                        PrayerAlarmReconcileWorker.cancel(appContext)
                    }
                }

                // The Settings "send a test notification" button, on the native
                // path. It exists so a user can prove the adhan works before
                // trusting it, and a probe that takes a different route than the
                // real thing proves nothing: this deliberately goes through the
                // same channel, the same notification builder and the same
                // playback service an actual prayer does.
                //
                // Starting the foreground service from here is unrestricted —
                // the app is in the foreground, since the user just tapped a
                // button in it.
                "testAdhan" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<String, Any?>
                    val alarm = args?.let { PrayerAlarm.fromChannel(it) }
                    if (alarm == null) {
                        result.error("PRAYER_ALARM_BAD_ARGS", "testAdhan needs a renderable alarm", null)
                    } else {
                        PrayerNotifier.ensureChannel(appContext, alarm)
                        try {
                            ContextCompat.startForegroundService(
                                appContext,
                                AdhanPlaybackService.playIntent(appContext, alarm),
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Test adhan could not start the service", e)
                            PrayerNotifier.post(appContext, alarm)
                            result.success(false)
                        }
                    }
                }

                "consumePendingTap" -> result.success(PrayerAlarmStore.consumePendingTap(appContext))

                // Deliberately a peek, not a consume. Reading and clearing in
                // one call would drop the flag the moment Dart ASKS, and the
                // re-plan that answers it can still fail — no location fix, the
                // reschedule listener skipping because settings had not loaded
                // yet. The flag is cleared by "clearLocationStale" instead,
                // once the ledger has actually been rewritten, so anything that
                // goes wrong in between just means the next resume tries again.
                "isLocationStale" -> result.success(PrayerAlarmStore.isLocationStale(appContext))

                "clearLocationStale" -> {
                    PrayerAlarmStore.setLocationStale(appContext, false)
                    // The notice and the flag have one lifetime between them.
                    // Leaving the card up after the times were fixed tells the
                    // user to do something they have already done.
                    PrayerNotifier.cancelLocationNotice(appContext)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        // A tap that cold-started the app may already be waiting; Dart collects
        // it with consumePendingTap once its router exists.
    }

    /**
     * Resolves the system notification tone while the user is certainly
     * unlocked, and leaves it in device-protected storage.
     *
     * `RingtoneManager` reads the per-user settings provider, which is
     * credential-encrypted. [AdhanPlaybackService] can run before the first
     * unlock after a reboot, and a live lookup there returns null — which for a
     * user on the "الصوت الافتراضي" option would be a completely silent prayer
     * alert. A commit only happens with a Flutter engine alive, so this is the
     * safe moment to ask.
     */
    private fun cacheDefaultSoundUri(context: Context) {
        val uri = try {
            // getActualDefaultRingtoneUri, NOT getDefaultUri. The latter returns
            // the constant content://settings/system/notification_sound, which
            // is resolved through the settings provider at PLAY time — so
            // caching it would store a value that still needs the one thing
            // direct boot cannot give you. This resolves to the media URI the
            // user actually picked, which is what there is any point in caching.
            RingtoneManager.getActualDefaultRingtoneUri(
                context,
                RingtoneManager.TYPE_NOTIFICATION,
            )?.toString()
        } catch (e: Exception) {
            Log.w(TAG, "Could not resolve the default notification tone", e)
            null
        }
        if (uri != null) PrayerAlarmStore.setDefaultSoundUri(context, uri)
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
