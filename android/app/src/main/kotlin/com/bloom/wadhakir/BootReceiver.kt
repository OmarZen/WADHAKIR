package com.bloom.wadhakir

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Restarts the native floating-dhikr foreground service after a device reboot
 * or an app update, if the user had it enabled. (Prayer/fasting/wird
 * notifications are rescheduled by awesome_notifications' own boot receiver.)
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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(service)
        } else {
            context.startService(service)
        }
    }
}
