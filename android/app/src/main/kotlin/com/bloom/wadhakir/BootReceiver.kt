package com.bloom.wadhakir

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Re-establishes everything the OS drops on a reboot or an app update.
 *
 * Two jobs, in order of importance:
 *
 *  1. **The prayer alarms.** AlarmManager forgets every alarm across a reboot,
 *     and `MY_PACKAGE_REPLACED` covers the case that used to lose them
 *     silently on every Play update. The ledger survives in SharedPreferences,
 *     so re-arming is just replaying it. Fasting/wird/azkar reminders are still
 *     rescheduled by awesome_notifications' own boot receiver.
 *  2. The floating-dhikr foreground service, if the user had it enabled.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val isBoot = action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED
        if (!isBoot) return

        // Before the floating-dhikr check below, which returns early for the
        // vast majority of users who never enabled it — and used to take the
        // whole receiver with it.
        val pending = goAsync()
        val appContext = context.applicationContext
        Thread {
            try {
                PrayerAlarmScheduler.rearmWindow(appContext, System.currentTimeMillis())
                PrayerAlarmReconcileWorker.enqueue(appContext)
            } catch (_: Exception) {
                // Nothing to recover here; the next app open re-plans.
            } finally {
                pending.finish()
            }
        }.start()

        if (!FloatingDhikrService.isEnabled(context)) return

        val service = Intent(context, FloatingDhikrService::class.java).apply {
            this.action = FloatingDhikrService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(service)
        } else {
            context.startService(service)
        }
    }
}
