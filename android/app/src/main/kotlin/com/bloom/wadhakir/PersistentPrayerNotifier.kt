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
 * The ongoing "next prayer" notification, with the countdown rendered by
 * Android instead of by a timer.
 *
 * ## What this replaced
 *
 * `PersistentNotificationManager` ran `Timer.periodic(Duration(seconds: 1))`
 * and posted a whole notification across the platform channel on every tick —
 * **86,400 posts a day**, every day, for a card that shows a countdown. It was
 * the largest single battery cost in the app, and battery drain is the most
 * common reason a prayer app gets uninstalled.
 *
 * It was also wrong. A Dart timer only runs while the app does, so the number
 * froze the moment the user left — the one time they would look at it.
 *
 * `setUsesChronometer` + `setWhen(theInstant)` + `setChronometerCountDown` hands
 * the counting to the system, which renders it live in the shade with **zero**
 * updates from the app and keeps counting with no process alive. Both
 * chronometer flags are API 24+, which is this app's minSdk.
 *
 * ## Why Kotlin
 *
 * `awesome_notifications` does not expose either chronometer flag, which is why
 * this was blocked until R2 built a native notification path. There is no way
 * to do it on the plugin.
 *
 * ## How it stays correct
 *
 * One post per prayer, not one per second. Dart posts when prayer times change;
 * [PrayerAlarmReceiver] rolls it forward to the following prayer as each alarm
 * fires, straight off the ledger, so it keeps up while the app is closed.
 */
object PersistentPrayerNotifier {

    /**
     * Must match `_channelKeyPersistent` in `notification_repository_impl.dart`.
     *
     * Reused rather than re-keyed: that channel was already silent, so nothing
     * about it is immutable in a way Stage 3 needed to change. Dart still
     * declares it — `initialize()` replaces the whole channel set at every cold
     * start, and a channel only this file created would be deleted there.
     */
    const val CHANNEL_ID = "persistent_prayer_channel"

    /** Documented at `PrayerNotifier`: prayers 100–694, notice 900, this 999. */
    const val NOTIFICATION_ID = 999

    private const val CHANNEL_NAME = "تنبيه دائم لأوقات الصلاة"

    /** The token Dart leaves in its title format for the prayer's name. */
    private const val PRAYER_TOKEN = "{prayer}"

    /**
     * Shows, or replaces, the ongoing card.
     *
     * [titleFormat] is authored in Dart and carries [PRAYER_TOKEN]. Substituting
     * is the only thing this file does to user-facing copy — composing it here
     * would put a second author of Arabic on the native side, which is the drift
     * the whole wire format exists to prevent.
     *
     * [prayerAtEpochMs] is the prayer itself, never the notification's fire
     * instant: a user on a "15 minutes before" lead still wants the countdown to
     * reach zero at the adhan.
     */
    fun show(
        context: Context,
        titleFormat: String,
        prayerName: String,
        body: String,
        prayerAtEpochMs: Long,
    ) {
        if (prayerName.isEmpty() || prayerAtEpochMs <= 0L) return
        ensureChannel(context)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(titleFormat.replace(PRAYER_TOKEN, prayerName))
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setOngoing(true)
            .setAutoCancel(false)
            .setBadgeIconType(NotificationCompat.BADGE_ICON_NONE)
            // The three lines that removed 86,400 posts a day. `setWhen` is the
            // target instant rather than "now", and the chronometer counts down
            // to it in the system's own text view.
            .setWhen(prayerAtEpochMs)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setShowWhen(true)
            // Nothing about this card is new information arriving; without it
            // every roll-forward would re-alert.
            .setOnlyAlertOnce(true)
            .setContentIntent(tapIntent(context))
            .build()

        try {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS revoked. Nothing to recover; the prayer
            // schedule itself is unaffected.
        }
    }

    fun hide(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    /**
     * Rolls the card forward to the prayer after [nowMs], from the ledger.
     *
     * Called as each alarm fires — the moment the "next" prayer changes — and
     * from the 00:05 anchor and the boot receiver, which are what keep the card
     * honest when no alarm is firing at all: the master toggle off, the user on
     * the plugin escape hatch, or a phone that has just rebooted.
     *
     * Returns quietly when the feature is off, when the ledger has nothing
     * ahead, or when the row predates Stage 3 and therefore carries no Arabic
     * prayer name — showing the wire's `prayerKey` instead would put "Fajr" on
     * an Arabic-first card.
     *
     * ## Two known imprecisions, both deliberate
     *
     * **A disabled prayer is skipped.** The ledger holds only prayers the user
     * left switched on, so someone who turned Dhuhr's notification off sees the
     * card name Asr after Fajr. Dart, which has the full prayer table, names
     * Dhuhr — so the two disagree until the app is next opened, which corrects
     * it. Fixing it properly means giving the native side a prayer table of its
     * own, separate from the alarm ledger; not worth that for a card.
     *
     * **With a lead time the card turns over early.** [after] is the fired
     * alarm's PRAYER instant, so the prayer that is about to happen is excluded
     * and the card moves to the one following it. On a "15 minutes before"
     * setting that is fifteen minutes early. The alternative — re-showing the
     * prayer that is about to happen — leaves nothing to roll the card at the
     * prayer instant itself, so the chronometer would sail through zero and
     * count upward for hours. Early beats wrong, and the shipped default
     * ("on time") has no gap at all.
     */
    fun rollForward(context: Context, after: Long) {
        if (!PrayerAlarmStore.isPersistentEnabled(context)) return
        val format = PrayerAlarmStore.persistentTitleFormat(context) ?: return

        val next = PrayerAlarmStore.all(context)
            .filter { it.prayerAtEpochMs > after && it.prayerName.isNotEmpty() }
            .minByOrNull { it.prayerAtEpochMs }
            ?: return

        show(
            context = context,
            titleFormat = format,
            prayerName = next.prayerName,
            body = next.body,
            prayerAtEpochMs = next.prayerAtEpochMs,
        )
    }

    /**
     * Safety net for a channel the plugin has not created yet — a cleared-data
     * install, or a roll-forward that lands before the app's first launch after
     * a restore. A notification posted to an unknown channel is dropped by
     * Android with no error anywhere.
     */
    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            },
        )
    }

    private fun tapIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            data = Uri.parse("wadhakir://next-prayer")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            NOTIFICATION_ID,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
