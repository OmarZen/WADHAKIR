package com.bloom.wadhakir

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * The fire path. No Flutter engine runs here — that is the whole point.
 *
 * `awesome_notifications` also fires natively, so this is not what changes when
 * an alarm rings. What changes is what happens *after*: this re-arms the window
 * from [PrayerAlarmStore], so the horizon walks forward on its own instead of
 * only ever extending when someone opens the app (C1).
 */
class PrayerAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext
        when (intent.action) {
            ACTION_FIRE -> onFire(appContext, intent.getIntExtra(EXTRA_ALARM_ID, -1))
            ACTION_ANCHOR -> onAnchor(appContext)
            ACTION_STOP -> PrayerNotifier.cancel(appContext, intent.getIntExtra(EXTRA_ALARM_ID, -1))
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
            return
        }

        // Post first. Everything below is bookkeeping, and the adhan is the only
        // part with a deadline.
        PrayerNotifier.post(context, alarm)

        // Then walk the window forward. Done inside goAsync so a slow ledger
        // rewrite cannot be killed halfway by the 10-second receiver budget and
        // leave the chain one link short.
        val pending = goAsync()
        Thread {
            try {
                PrayerAlarmScheduler.rearmWindow(context, System.currentTimeMillis())
            } catch (e: Exception) {
                Log.e(TAG, "Failed to re-arm after alarm $id", e)
            } finally {
                pending.finish()
            }
        }.start()
    }

    private fun onAnchor(context: Context) {
        val pending = goAsync()
        Thread {
            try {
                PrayerAlarmScheduler.rearmWindow(context, System.currentTimeMillis())
            } catch (e: Exception) {
                Log.e(TAG, "Anchor rebuild failed", e)
            } finally {
                pending.finish()
            }
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
