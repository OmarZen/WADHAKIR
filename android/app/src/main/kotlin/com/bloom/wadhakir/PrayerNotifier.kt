package com.bloom.wadhakir

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Posts the adhan notification when an alarm fires.
 *
 * Renders nothing of its own: the title, body, channel and payload were all
 * decided in Dart and carried across in [PrayerAlarm]. This turns them into a
 * `Notification` and hands it to the OS.
 *
 * ## Where the sound comes from
 *
 * From Oreo it is the CHANNEL, never the notification. The adhan channels are
 * created with the mp3 baked in as their sound, which is what makes the full
 * adhan play with no app process alive — and channel sound is immutable once
 * created, hence one channel per adhan and the `_v1` suffix on the keys.
 *
 * On 24 and 25 there are no channels, so the sound is set on the notification
 * instead. That path is easy to forget and impossible to notice in testing on a
 * modern device: the notification appears, and it is silent.
 */
object PrayerNotifier {

    /** Extra carried to MainActivity so a tap can be routed to the right screen. */
    const val EXTRA_PAYLOAD_PREFIX = "wadhakir_payload_"

    fun post(context: Context, alarm: PrayerAlarm) {
        ensureChannel(context, alarm)

        val builder = NotificationCompat.Builder(context, alarm.channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(alarm.title)
            .setContentText(alarm.body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(alarm.body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            // CATEGORY_ALARM is what tells Do Not Disturb, Battery Saver and the
            // heads-up ranker that this is a time-critical alert rather than a
            // content nudge.
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setGroup(alarm.groupKey)
            .setWhen(alarm.fireAtEpochMs)
            .setShowWhen(true)
            .setAutoCancel(true)
            .setContentIntent(tapIntent(context, alarm))
            .addAction(
                0,
                STOP_LABEL,
                stopIntent(context, alarm.id),
            )

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            // Pre-channel Android. Without this the adhan is silent on 24/25 —
            // and the fallback matters as much as the adhan itself: a user on
            // the "Default" sound option has no raw resource, and setting no
            // sound at all would give them a completely silent prayer alert
            // rather than the system notification tone they expect.
            val sound = soundUri(context, alarm) ?: defaultNotificationSound()
            sound?.let { builder.setSound(it, AudioManagerStreamAlarm) }
            if (alarm.vibrate) {
                builder.setVibrate(longArrayOf(0, 500, 250, 500))
            }
        }

        try {
            NotificationManagerCompat.from(context).notify(alarm.id, builder.build())
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS was revoked between arming and firing. Nothing
            // to recover here; the reminder-health screen (R3) is where the user
            // finds out.
        }
    }

    /** Dismisses a sounding adhan. Cancelling the notification stops the sound. */
    fun cancel(context: Context, id: Int) {
        NotificationManagerCompat.from(context).cancel(id)
    }

    /**
     * Tells the user their prayer times need updating after a timezone change.
     *
     * Quiet on purpose — `IMPORTANCE_DEFAULT`, no adhan, no full-screen intent.
     * The schedule is still armed and still ringing; this is a correction
     * notice, not an alert, and dressing it up like one would train people to
     * dismiss the thing that actually matters.
     */
    fun postLocationNotice(context: Context) {
        ensureNoticeChannel(context)

        val intent = Intent(context, MainActivity::class.java).apply {
            data = Uri.parse("wadhakir://prayer-location-notice")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val tap = PendingIntent.getActivity(
            context,
            LOCATION_NOTICE_ID,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, NOTICE_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("تغيّرت المنطقة الزمنية")
            .setContentText("افتح وذكّر لتحديث مواقيت الصلاة على مكانك الجديد.")
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    "التنبيهات ما زالت تعمل، لكنها محسوبة على موقعك السابق. " +
                        "افتح التطبيق مرة واحدة لتحديث المواقيت.",
                ),
            )
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setAutoCancel(true)
            .setContentIntent(tap)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(LOCATION_NOTICE_ID, notification)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS revoked. The schedule is unaffected.
        }
    }

    private fun ensureNoticeChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(NOTICE_CHANNEL_ID) != null) return
        manager.createNotificationChannel(
            NotificationChannel(
                NOTICE_CHANNEL_ID,
                "تنبيهات مواقيت الصلاة",
                NotificationManager.IMPORTANCE_DEFAULT,
            ),
        )
    }

    /**
     * Guarantees the channel exists before posting to it.
     *
     * From Oreo a notification posted to an unknown channel id is dropped with
     * no error and nothing in logcat. The channels are normally created by
     * `awesome_notifications` at app init, but this receiver can fire long after
     * the user cleared the app's data or after a restore onto a new device — and
     * a missing channel would turn every remaining adhan into silence.
     *
     * Creating one that already exists is a no-op, and Android ignores changes
     * to an existing channel's settings, so this can never override what the
     * plugin (or the user) configured.
     */
    private fun ensureChannel(context: Context, alarm: PrayerAlarm) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(alarm.channelId) != null) return

        val channel = NotificationChannel(
            alarm.channelId,
            FALLBACK_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_MAX,
        ).apply {
            enableVibration(alarm.vibrate)
            soundUri(context, alarm)?.let { uri ->
                setSound(
                    uri,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
            }
        }
        manager.createNotificationChannel(channel)
    }

    /**
     * The user's system notification tone, or null if it cannot be read.
     *
     * Wrapped because this receiver now runs in direct boot, and the settings
     * provider that backs it is per-user: on an API 24/25 device with
     * file-based encryption it can be unavailable before the first unlock. A
     * throw here would take the whole adhan down, which is a far worse outcome
     * than falling back to a silent card on two old API levels.
     */
    private fun defaultNotificationSound(): Uri? = try {
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
    } catch (_: Exception) {
        null
    }

    /**
     * Takes the "your timezone changed" notice out of the tray.
     *
     * Called when the schedule stops being stale. `setAutoCancel` only fires if
     * the user TAPS the notice, so someone who instead opened the app from the
     * launcher — the common case, since the app is what they were told to open —
     * would fix their prayer times and still be looking at a card telling them
     * to fix their prayer times.
     */
    fun cancelLocationNotice(context: Context) {
        NotificationManagerCompat.from(context).cancel(LOCATION_NOTICE_ID)
    }

    /** The bundled adhan, or null for the "Default" option's system beep. */
    private fun soundUri(context: Context, alarm: PrayerAlarm): Uri? {
        val res = alarm.soundRes ?: return null
        if (res.isEmpty()) return null
        return Uri.parse("android.resource://${context.packageName}/raw/$res")
    }

    private fun tapIntent(context: Context, alarm: PrayerAlarm): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            // Distinct data per id so two pending intents can never collapse into
            // one: extras are not part of Intent.filterEquals, so without this a
            // tap on Asr could route as Fajr.
            data = Uri.parse("wadhakir://prayer-alarm/${alarm.id}")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            alarm.payload.forEach { (key, value) ->
                putExtra("$EXTRA_PAYLOAD_PREFIX$key", value)
            }
        }
        return PendingIntent.getActivity(
            context,
            alarm.id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun stopIntent(context: Context, id: Int): PendingIntent {
        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            action = PrayerAlarmReceiver.ACTION_STOP
            data = Uri.parse("wadhakir://prayer-alarm-stop/$id")
            putExtra(PrayerAlarmReceiver.EXTRA_ALARM_ID, id)
        }
        return PendingIntent.getBroadcast(
            context,
            STOP_REQUEST_BASE + id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * `Notification.STREAM_ALARM`, spelled out because the constant is
     * deprecated on the AndroidX builder and only reachable pre-Oreo anyway.
     */
    private const val AudioManagerStreamAlarm = 4

    private const val STOP_LABEL = "إيقاف الأذان"

    /**
     * Offset so a stop action's PendingIntent can never share a request code
     * with the alarm PendingIntent for the same id.
     */
    private const val STOP_REQUEST_BASE = 900_000

    private const val FALLBACK_CHANNEL_NAME = "تنبيه الصلاة"

    /**
     * Must match `PrayerNotificationContent.locationNoticeChannelKey` in Dart.
     *
     * `AwesomeNotifications().initialize()` REPLACES the entire channel set on
     * every cold start, so a channel this file creates but Dart does not declare
     * would be deleted the next time the app opens — and the notice would then
     * be silently dropped for having no channel.
     */
    const val NOTICE_CHANNEL_ID = "prayer_location_notice_channel"

    /**
     * Outside every documented range: prayers 100–694, diagnostic 998,
     * persistent 999, fasting 5001–5999, wird 6001/6099, azkar 7100+.
     */
    private const val LOCATION_NOTICE_ID = 900
}
