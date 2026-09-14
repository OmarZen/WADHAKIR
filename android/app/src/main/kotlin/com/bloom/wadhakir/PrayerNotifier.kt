package com.bloom.wadhakir

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Builds and posts the adhan notification when an alarm fires.
 *
 * Renders nothing of its own: the title, body, channel and payload were all
 * decided in Dart and carried across in [PrayerAlarm]. This turns them into a
 * `Notification` and hands it to the OS — or, on the normal path, to
 * [AdhanPlaybackService], which posts it as its foreground notification.
 *
 * ## Where the sound comes from
 *
 * [AdhanPlaybackService], since Stage 3. It used to be the CHANNEL, which is
 * why the keys carried a `_v1` suffix — channel sound is immutable once
 * created, so one channel per adhan was the only way to let the user choose
 * one. That bought a full adhan with no app process alive, at the cost of a
 * stop button that was best-effort by construction.
 *
 * The channels this file creates are now **silent**, and there are two of them:
 * Fajr, and the other four. New keys, because the `_v1` channels can never stop
 * sounding. Both are declared on the Dart side as well —
 * `AwesomeNotifications().initialize()` replaces the whole channel set at every
 * cold start, so a channel only Kotlin creates is deleted the next time the app
 * opens and every notification posted to it is silently dropped.
 */
object PrayerNotifier {

    /** Extra carried to MainActivity so a tap can be routed to the right screen. */
    const val EXTRA_PAYLOAD_PREFIX = "wadhakir_payload_"

    /**
     * Posts the adhan card on its own, with no playback service behind it.
     *
     * Two paths reach this: the user asked the adhan to respect a silenced
     * phone, and the foreground service could not be started. Both want the
     * card — dismissible, because nothing is playing that a stop button would
     * have to reach.
     */
    fun post(context: Context, alarm: PrayerAlarm) {
        ensureChannel(context, alarm)
        postBuilt(context, alarm.id, buildAdhan(context, alarm, ongoing = false))
    }

    /** Hands an already-built notification to the OS. */
    fun postBuilt(context: Context, id: Int, notification: android.app.Notification) {
        try {
            NotificationManagerCompat.from(context).notify(id, notification)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS was revoked between arming and firing. Nothing
            // to recover here; the reminder-health screen (R3) is where the user
            // finds out.
        }
    }

    /**
     * The adhan card.
     *
     * [ongoing] is true when [AdhanPlaybackService] is about to foreground
     * itself on this notification. That case must not auto-cancel: a tap opens
     * the app — which people do *because* they heard the adhan — and dismissing
     * the card there would take the stop button away from an adhan that is
     * still playing. The service takes it down itself when the mp3 ends.
     *
     * The delete intent matters for the same reason. From Android 14 a
     * foreground-service notification can be swiped away without stopping the
     * service, which would otherwise leave the adhan sounding with no visible
     * way to stop it.
     */
    fun buildAdhan(
        context: Context,
        alarm: PrayerAlarm,
        ongoing: Boolean = true,
    ): android.app.Notification {
        val stop = stopIntent(context, alarm.id)
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
            .setOngoing(ongoing)
            .setAutoCancel(!ongoing)
            .setContentIntent(tapIntent(context, alarm))
            .addAction(0, STOP_LABEL, stop)
            // Without this the platform is allowed to hold a foreground
            // service's notification back for ten seconds. Ten seconds of adhan
            // with no visible stop button is the whole defect this stage exists
            // to fix.
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)

        if (ongoing) {
            builder.setDeleteIntent(stop)
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O && alarm.vibrate) {
            // Pre-channel Android has nowhere else to put this. From Oreo the
            // channel carries the vibration pattern, and setting it here too
            // would buzz twice.
            builder.setVibrate(longArrayOf(0, 500, 250, 500))
        }

        return builder.build()
    }

    /**
     * Takes the adhan card out of the tray.
     *
     * This used to be how the adhan was stopped — cancelling the notification
     * that owned the channel sound. It is now only the card: the sound belongs
     * to [AdhanPlaybackService], and [PrayerAlarmReceiver] stops that too.
     */
    fun cancel(context: Context, id: Int) {
        if (id < 0) return
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
     * `awesome_notifications` at app init, but this can fire long after the user
     * cleared the app's data or after a restore onto a new device — and a
     * missing channel would turn every remaining adhan into a dropped one.
     *
     * Creating one that already exists is a no-op, and Android ignores changes
     * to an existing channel's settings, so this can never override what the
     * plugin (or the user) configured.
     *
     * **Silent, deliberately.** [AdhanPlaybackService] owns the audio now.
     * Leaving a sound on the channel as well would play the adhan twice, out of
     * step with itself, on two different volume sliders.
     */
    fun ensureChannel(context: Context, alarm: PrayerAlarm) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(alarm.channelId) != null) return

        val isFajr = alarm.channelId == FAJR_ADHAN_CHANNEL_ID
        val channel = NotificationChannel(
            alarm.channelId,
            if (isFajr) FAJR_CHANNEL_NAME else ADHAN_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_MAX,
        ).apply {
            setSound(null, null)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 500, 250, 500)
            setShowBadge(true)
        }
        manager.createNotificationChannel(channel)
    }

    /**
     * Whether the user has left this channel able to speak.
     *
     * Checked before starting playback, because a blocked channel makes the
     * foreground notification invisible while the service keeps running — an
     * adhan with no stop button anywhere, which is strictly worse than the
     * best-effort one Stage 3 replaced. A muted channel is read as "the user
     * muted the adhan", and nothing plays.
     */
    fun channelAllowsAlert(context: Context, channelId: String): Boolean {
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return true
        val manager = context.getSystemService(NotificationManager::class.java) ?: return true
        val channel = manager.getNotificationChannel(channelId) ?: return true
        return channel.importance != NotificationManager.IMPORTANCE_NONE
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

    private const val STOP_LABEL = "إيقاف الأذان"

    /**
     * Offset so a stop action's PendingIntent can never share a request code
     * with the alarm PendingIntent for the same id.
     */
    private const val STOP_REQUEST_BASE = 900_000

    /**
     * The two silent adhan channels, replacing the fifteen sounding `_v1` keys.
     *
     * **Must match `PrayerNotificationContent` in Dart**, which declares them to
     * `AwesomeNotifications().initialize()`. Split Fajr from the rest because a
     * channel's importance, vibration and lock-screen visibility are the user's
     * to change, and the one prayer people most often want treated differently
     * is Fajr — the split also leaves room for the Fajr-only DND bypass without
     * minting keys a second time.
     */
    const val ADHAN_CHANNEL_ID = "prayer_adhan_v2"
    const val FAJR_ADHAN_CHANNEL_ID = "prayer_adhan_fajr_v2"

    private const val ADHAN_CHANNEL_NAME = "الأذان"
    private const val FAJR_CHANNEL_NAME = "أذان الفجر"

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
