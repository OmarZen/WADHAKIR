package com.bloom.wadhakir

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * The fire path. No Flutter engine runs here — that is the whole point.
 *
 * `awesome_notifications` also fires natively, so this is not what changes when
 * an alarm rings. What changes is what happens *after*: this re-arms the window
 * from [PrayerAlarmStore], so the horizon walks forward on its own instead of
 * only ever extending when someone opens the app (C1).
 *
 * Since Stage 3 it also starts [AdhanPlaybackService] rather than relying on a
 * notification channel to make the sound, which is what makes the stop button
 * real.
 */
class PrayerAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext
        when (intent.action) {
            ACTION_FIRE -> onFire(appContext, intent.getIntExtra(EXTRA_ALARM_ID, -1))
            ACTION_ANCHOR -> onAnchor(appContext)
            ACTION_STOP -> onStop(appContext, intent.getIntExtra(EXTRA_ALARM_ID, -1))
            else -> Unit
        }
    }

    private fun onFire(context: Context, id: Int) {
        if (id < 0) return
        val alarm = PrayerAlarmStore.all(context).firstOrNull { it.id == id }
        if (alarm == null) {
            // The ledger was cleared between arming and firing — a reschedule
            // that switched this prayer off, or the user wiping app data. Ringing
            // an adhan the app no longer intends is worse than staying silent.
            Log.w(TAG, "Alarm $id fired but is not in the ledger; ignoring")
            // Still worth a row. One of these is noise; a run of them means the
            // two ledgers have drifted, which is a fault nothing else reports.
            // The instant is unknown here, so `due` is the arrival — a skew of
            // zero, which is honest: there is nothing to be late against.
            val orphanAt = System.currentTimeMillis()
            val pendingOrphan = goAsync()
            Thread {
                try {
                    ReminderLedgerStore.recordFired(
                        context,
                        id,
                        orphanAt,
                        ReminderRules.OUTCOME_ORPHAN,
                        orphanAt,
                    )
                } catch (e: Exception) {
                    Log.w(TAG, "Could not record orphan alarm $id", e)
                } finally {
                    // In a finally, like every other goAsync in this file. A
                    // throw that skipped this would leak the broadcast grant,
                    // and the row being written here is the least important
                    // thing in the app.
                    pendingOrphan.finish()
                }
            }.start()
            return
        }

        // Sound first. Everything below is bookkeeping, and the adhan is the
        // only part with a deadline.
        val outcome = soundAdhan(context, alarm)

        // Then walk the window forward. Done inside goAsync so a slow ledger
        // rewrite cannot be killed halfway by the 10-second receiver budget and
        // leave the chain one link short.
        val pending = goAsync()
        Thread {
            val now = System.currentTimeMillis()
            try {
                // The row Dart cannot write: this process has no Flutter engine
                // and the app may not have been opened for weeks. `fireAtEpochMs`
                // against now is the only honest measure of whether this device
                // delivers an alarm at the instant it was armed for — which is
                // the entire question the health screen answers.
                ReminderLedgerStore.recordFired(
                    context,
                    alarm.id,
                    alarm.fireAtEpochMs,
                    outcome,
                    now,
                )
            } catch (e: Exception) {
                Log.w(TAG, "Could not record alarm $id in the reminder ledger", e)
            }
            try {
                // This alarm's own id is handed over so the sweep's lapse
                // detection skips it. It is still in the armed set with an
                // instant now in the past — which is what a lapse looks like —
                // except that it plainly did arrive, and is the reason this code
                // is running at all.
                PrayerAlarmScheduler.rearmWindow(context, now, firedId = alarm.id)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to re-arm after alarm $id", e)
            }
            try {
                // Separate try block on purpose. Sharing one with the re-arm
                // meant a single throw from AlarmManager left the persistent
                // card naming a prayer that had already passed, counting
                // downwards through zero until some later alarm happened to
                // succeed.
                //
                // The threshold is the PRAYER instant, not now: a user on a
                // "15 minutes before" lead is woken by this alarm a quarter of
                // an hour early, and "the next prayer after now" would still be
                // the prayer that is about to happen — so the card would re-show
                // the same prayer and then count negative for the rest of the day.
                PersistentPrayerNotifier.rollForward(
                    context,
                    maxOf(now, alarm.prayerAtEpochMs),
                )
            } catch (e: Exception) {
                Log.e(TAG, "Could not roll the persistent card forward", e)
            }
            pending.finish()
        }.start()
    }

    /**
     * Starts the adhan, or posts the card alone when it should not sound.
     *
     * Three things can send it down the quiet path, and all three are the user's
     * own doing rather than a failure:
     *
     *  * the channel is blocked — a service playing audio behind an invisible
     *    notification is an adhan with no stop button anywhere;
     *  * the phone is silenced and they turned «يتجاوز الوضع الصامت» off;
     *  * the platform refuses the foreground start.
     *
     * Only the last is a degradation, and it is narrow: the background-start
     * exemption is granted by the exact alarm itself, and
     * [PrayerAlarmScheduler] uses `setAlarmClock` wherever it is allowed to.
     * What is left is Android 12 and 12L with `SCHEDULE_EXACT_ALARM` revoked,
     * where the alarm has already degraded to inexact. The card still posts and
     * the channel still vibrates.
     *
     * Returns which of the four happened, for the reminder ledger. The three
     * quiet outcomes are kept distinct rather than collapsed into "did not
     * sound" because only one of them is a fault: a verdict that counted a
     * user's own silenced phone as a delivery failure would tell them their
     * device is broken for doing what they asked.
     */
    private fun soundAdhan(context: Context, alarm: PrayerAlarm): String {
        PrayerNotifier.ensureChannel(context, alarm)

        // The choice between the three routes is in ReminderRules, which has no
        // Android types and is therefore the only part of this decision a JUnit
        // test can reach. Everything left here is the doing, not the deciding.
        val route = ReminderRules.adhanRoute(
            channelAllowsAlert = PrayerNotifier.channelAllowsAlert(context, alarm.channelId),
            overrideSilent = alarm.overrideSilent,
            ringerSilenced = isRingerSilenced(context),
        )

        when (route) {
            ReminderRules.AdhanRoute.MUTED -> {
                Log.i(TAG, "Channel ${alarm.channelId} is muted; not sounding alarm ${alarm.id}")
                return ReminderRules.outcomeFor(route)
            }

            ReminderRules.AdhanRoute.SILENT_CARD -> {
                PrayerNotifier.post(context, alarm)
                return ReminderRules.outcomeFor(route)
            }

            ReminderRules.AdhanRoute.PLAY -> Unit
        }

        return try {
            ContextCompat.startForegroundService(
                context,
                AdhanPlaybackService.playIntent(context, alarm),
            )
            ReminderRules.outcomeFor(route)
        } catch (e: Exception) {
            Log.e(TAG, "Foreground start refused for alarm ${alarm.id}; card only", e)
            PrayerNotifier.post(context, alarm)
            ReminderRules.OUTCOME_REFUSED
        }
    }

    /**
     * Whether the ringer is off.
     *
     * Wrapped, and defaulting to "not silenced", because this runs before the
     * first unlock: a reader that threw here would take the adhan down with it,
     * and the failure this release exists to prevent is silence.
     */
    private fun isRingerSilenced(context: Context): Boolean = try {
        when (context.getSystemService(AudioManager::class.java)?.ringerMode) {
            AudioManager.RINGER_MODE_SILENT, AudioManager.RINGER_MODE_VIBRATE -> true
            else -> false
        }
    } catch (_: Exception) {
        false
    }

    /**
     * The «إيقاف الأذان» button, and the swipe that dismisses the card.
     *
     * Stopping the service is what actually silences the adhan now. The cancel
     * that follows is for the card: the service removes its own foreground
     * notification on the way out, but the quiet path posts one no service ever
     * owned, and that one still has to go.
     */
    private fun onStop(context: Context, id: Int) {
        // Scoped to this card's own alarm. A card now outlives its playback, so
        // an old one can still be in the tray while a different prayer is
        // mid-adhan, and its stop button must not silence that.
        AdhanPlaybackService.stop(context, id)
        PrayerNotifier.cancel(context, id)
    }

    private fun onAnchor(context: Context) {
        val pending = goAsync()
        Thread {
            val now = System.currentTimeMillis()
            try {
                PrayerAlarmScheduler.rearmWindow(context, now)
            } catch (e: Exception) {
                Log.e(TAG, "Anchor rebuild failed", e)
            }
            try {
                // The daily 00:05 rebuild also repairs the persistent card.
                // Firing alarms are its main way forward, but they stop being
                // one the moment the master toggle is off or the user is on the
                // plugin escape hatch — and then the card would sit on a prayer
                // from days ago, counting further and further past zero.
                PersistentPrayerNotifier.rollForward(context, now)
            } catch (e: Exception) {
                Log.e(TAG, "Could not roll the persistent card forward", e)
            }
            pending.finish()
        }.start()
    }

    companion object {
        private const val TAG = "PrayerAlarms"

        const val ACTION_FIRE = "com.bloom.wadhakir.PRAYER_ALARM_FIRE"
        const val ACTION_ANCHOR = "com.bloom.wadhakir.PRAYER_ALARM_ANCHOR"
        const val ACTION_STOP = "com.bloom.wadhakir.PRAYER_ALARM_STOP"

        const val EXTRA_ALARM_ID = "alarm_id"
    }
}
