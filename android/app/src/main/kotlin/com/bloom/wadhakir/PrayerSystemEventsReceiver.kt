package com.bloom.wadhakir

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.os.UserManagerCompat

/**
 * Every system event that can invalidate the armed prayer schedule.
 *
 * ## Why a receiver of its own
 *
 * `BootReceiver` also restarts the floating-dhikr service, and that reads
 * ordinary app storage to find out whether the user enabled it — which is
 * unreadable before the first unlock. This receiver is `directBootAware` and
 * touches nothing but the alarm ledger, which now lives in device-protected
 * storage precisely so it can run that early.
 *
 * ## The triggers
 *
 *  - **`LOCKED_BOOT_COMPLETED`** — the whole point of direct boot. The window is
 *    re-armed while the lock screen is still up, so a prayer falling between a
 *    reboot and the first unlock is no longer missed.
 *  - **`BOOT_COMPLETED` / `QUICKBOOT_POWERON`** — AlarmManager forgets every
 *    alarm across a reboot. Also the OEM path for devices that skip the locked
 *    broadcast.
 *  - **`MY_PACKAGE_REPLACED`** — the one that used to lose alarms silently on
 *    every Play update.
 *  - **`TIME_SET` / `DATE_CHANGED`** — the alarms are absolute instants and do
 *    not move, but the 00:05 anchor is wall-clock and has to be recomputed.
 *  - **`TIMEZONE_CHANGED`** — see [onTimezoneChanged]. The hard one.
 *  - **`LOCALE_CHANGED`** — the copy was rendered in Dart and is now stale;
 *    re-arming costs nothing and the next app open re-renders it.
 *
 * All of them end at the same idempotent [PrayerAlarmScheduler.rearmWindow].
 */
class PrayerSystemEventsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val appContext = context.applicationContext

        val known = action in REARM_ACTIONS || action == Intent.ACTION_TIMEZONE_CHANGED
        if (!known) return

        val pending = goAsync()
        Thread {
            try {
                if (action == Intent.ACTION_TIMEZONE_CHANGED) {
                    onTimezoneChanged(appContext)
                }

                PrayerAlarmScheduler.rearmWindow(appContext, System.currentTimeMillis())

                // WorkManager keeps its database in credential-protected
                // storage, so touching it before the first unlock throws. The
                // reconciler is a repair path, not a delivery one — it can wait
                // for the unlock that BOOT_COMPLETED will bring.
                if (UserManagerCompat.isUserUnlocked(appContext)) {
                    PrayerAlarmReconcileWorker.enqueue(appContext)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to handle $action", e)
            } finally {
                pending.finish()
            }
        }.start()
    }

    /**
     * The traveller case.
     *
     * The armed alarms are absolute instants computed for wherever the user was
     * before, and nothing here can correct them: prayer times depend on
     * latitude and longitude as well as the zone, `adhan_dart` runs in Dart, and
     * the cached location is now the wrong city.
     *
     * What it does NOT do is cancel them. Going silent on someone who has just
     * landed is the exact failure this release exists to prevent, and a
     * notification they might not read is not a schedule. So the old plan keeps
     * firing as a floor, the ledger is marked stale, and the user is told once —
     * plainly — that the times need updating. Opening the app re-plans against a
     * fresh location and clears the flag.
     */
    private fun onTimezoneChanged(context: Context) {
        if (PrayerAlarmStore.all(context).isEmpty()) return
        if (PrayerAlarmStore.isLocationStale(context)) return

        PrayerAlarmStore.setLocationStale(context, true)
        PrayerNotifier.postLocationNotice(context)
        Log.i(TAG, "Timezone changed; schedule marked stale and the user notified")
    }

    companion object {
        private const val TAG = "PrayerAlarms"

        private val REARM_ACTIONS = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED,
            "android.intent.action.QUICKBOOT_POWERON",
        )
    }
}
