package com.bloom.wadhakir

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * DEBUG BUILDS ONLY — rings a real adhan on demand, so the stop paths can be
 * exercised on a device or emulator without waiting for a prayer.
 *
 * It arms with `setAlarmClock`, exactly like [PrayerAlarmScheduler], so the
 * service is started under the same background-start exemption a real prayer
 * gets. That matters: an adhan started from an open app is foreground-started
 * and would hide the screen-off case, which is the one users hit at Fajr.
 *
 *     adb shell am broadcast -n com.bloom.wadhakir/.AdhanTestReceiver \
 *         -a com.bloom.wadhakir.debug.ADHAN_TEST --ei delay_s 15
 *
 * Optional: `--es sound adhan_makkah_haram` (a `res/raw` name).
 *
 * Plays on the "other four" channel with a fixed id far outside every real
 * range, and never touches the alarm ledger, so it cannot disturb the
 * schedule the app has armed.
 */
class AdhanTestReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext
        when (intent.action) {
            ACTION_ARM -> arm(appContext, intent)
            ACTION_FIRE -> fire(appContext, intent)
        }
    }

    private fun arm(context: Context, intent: Intent) {
        val delayMs = intent.getIntExtra(EXTRA_DELAY_S, 10).coerceAtLeast(1) * 1000L
        val fireAt = System.currentTimeMillis() + delayMs
        val alarm = PrayerAlarm(
            id = TEST_ID,
            fireAtEpochMs = fireAt,
            prayerKey = "Dhuhr",
            dayIndex = 0,
            channelId = PrayerNotifier.ADHAN_CHANNEL_ID,
            groupKey = "wadhakir_debug_adhan",
            title = "اختبار الأذان",
            body = "أذان تجريبي من أداة الاختبار",
            vibrate = true,
            soundRes = intent.getStringExtra(EXTRA_SOUND) ?: "adhan_makkah_haram",
            prayerAtEpochMs = fireAt,
            prayerName = "الظهر",
            overrideSilent = true,
            payload = emptyMap(),
        )

        val fire = Intent(context, AdhanTestReceiver::class.java).apply {
            action = ACTION_FIRE
            putExtra(AdhanPlaybackService.EXTRA_ALARM_JSON, alarm.toJson().toString())
        }
        val operation = PendingIntent.getBroadcast(
            context,
            TEST_ID,
            fire,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val manager = context.getSystemService(AlarmManager::class.java) ?: return
        manager.setAlarmClock(AlarmManager.AlarmClockInfo(fireAt, null), operation)
        Log.i(TAG, "Test adhan armed for +${delayMs}ms")
    }

    private fun fire(context: Context, intent: Intent) {
        val alarm = intent.getStringExtra(AdhanPlaybackService.EXTRA_ALARM_JSON)
            ?.let(PrayerAlarm::fromJsonString) ?: return
        PrayerNotifier.ensureChannel(context, alarm)
        try {
            ContextCompat.startForegroundService(
                context,
                AdhanPlaybackService.playIntent(context, alarm),
            )
            Log.i(TAG, "Test adhan fired")
        } catch (e: Exception) {
            Log.e(TAG, "Test adhan could not start the service", e)
        }
    }

    companion object {
        private const val TAG = "PrayerAlarms"

        const val ACTION_ARM = "com.bloom.wadhakir.debug.ADHAN_TEST"
        private const val ACTION_FIRE = "com.bloom.wadhakir.debug.ADHAN_TEST_FIRE"

        private const val EXTRA_DELAY_S = "delay_s"
        private const val EXTRA_SOUND = "sound"

        /** Outside every documented id range; see PrayerNotifier.LOCATION_NOTICE_ID. */
        private const val TEST_ID = 4242
    }
}
