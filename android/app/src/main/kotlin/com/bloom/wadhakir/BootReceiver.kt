package com.bloom.wadhakir

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Restarts the native floating-dhikr foreground service after a device reboot
 * or an app update, if the user had it enabled.
 *
 * The prayer alarms are NOT re-armed here. They belong to
 * [PrayerSystemEventsReceiver], which is `directBootAware` and can run before
 * the first unlock — this one cannot, because the check below reads ordinary
 * app storage. Two receivers re-arming the same window would be harmless
 * (`rearmWindow` is idempotent) but it would leave nobody obviously in charge.
 *
 * Fasting/wird/azkar reminders are still rescheduled by awesome_notifications'
 * own boot receiver.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val isBoot = action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED
        if (!isBoot) return
        if (!FloatingDhikrService.isEnabled(context)) return

        val service = Intent(context, FloatingDhikrService::class.java).apply {
            this.action = FloatingDhikrService.ACTION_START
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(service)
            } else {
                context.startService(service)
            }
        } catch (e: Exception) {
            // Android 12+ can refuse the start — seen on Android 17 when the app
            // leaves the force-stopped state and the boot broadcast arrives
            // without its usual exemption. Uncaught, that refusal crashed the
            // whole process, and any adhan an alarm had just woken it for died
            // with it. The overlay comes back the next time the app opens.
            Log.w("BootReceiver", "Could not restart the floating dhikr", e)
        }
    }
}
