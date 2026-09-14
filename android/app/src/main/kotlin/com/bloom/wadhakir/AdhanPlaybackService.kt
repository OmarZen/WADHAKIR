package com.bloom.wadhakir

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.ServiceCompat

/**
 * Plays the adhan, and is the reason the stop button finally works.
 *
 * ## What this replaced
 *
 * Until Stage 3 the adhan was the notification CHANNEL's sound. That plays the
 * whole mp3 with no app process alive, which is why it was chosen — but it
 * makes stopping it best-effort **by construction**. The only lever the app has
 * over a channel sound is cancelling the notification that owns it, and a
 * notification owns the sound slot only until some other app's notification
 * takes it. When that happened the «إيقاف الأذان» button dismissed the card and
 * the adhan carried on with nothing able to stop it.
 *
 * Owning a [MediaPlayer] here makes the stop button a real one: it is the same
 * object that is playing, and [stopSelf] always reaches it.
 *
 * ## Why a foreground service, and why mediaPlayback
 *
 * A bare service is killed as soon as the receiver that started it returns, and
 * a background service cannot be started at all from Oreo on. `mediaPlayback`
 * is the honest type — this plays an audio file — and unlike `specialUse` it has
 * **no timeout**, so a four-minute adhan cannot be cut off by the platform.
 *
 * Starting it from the background is legal because of a documented exemption:
 * *"the app invokes an exact alarm to complete an action the user requested"*.
 * [PrayerAlarmScheduler] arms with `setAlarmClock`, which is that exact alarm.
 * This must be declared in the Play Console alongside the exact-alarm
 * declaration. The one case where the exemption does NOT hold is the degraded
 * path — see [PrayerAlarmReceiver], which is where the refusal is caught.
 *
 * ## Volume
 *
 * `USAGE_ALARM`, so the adhan follows the ALARM slider and sounds through
 * silent and vibrate the way an alarm clock does. That is a deliberate,
 * user-visible change from the notification stream it used to ride, and
 * [PrayerAlarm.overrideSilent] is the switch that gives it back.
 */
class AdhanPlaybackService : Service() {

    private val handler = Handler(Looper.getMainLooper())

    private var player: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var focusRequest: AudioFocusRequest? = null
    private var legacyFocusListener: AudioManager.OnAudioFocusChangeListener? = null

    /** The notification this service is foregrounded on. Needed to take it down. */
    private var notificationId: Int = 0

    /** The row being played, so the card can be left behind on the way out. */
    private var currentAlarm: PrayerAlarm? = null

    private val watchdog = Runnable {
        Log.w(TAG, "Adhan exceeded ${MAX_PLAYBACK_MS}ms; stopping")
        stopSelf()
    }

    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            // Both losses stop the adhan rather than pausing it. A call is the
            // common case, and an adhan that resumes when the call ends is an
            // adhan announcing a moment that has passed.
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> stopSelf()

            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK ->
                runCatching { player?.setVolume(DUCK_VOLUME, DUCK_VOLUME) }

            AudioManager.AUDIOFOCUS_GAIN ->
                runCatching { player?.setVolume(1f, 1f) }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }

        // The alarm travels in the intent rather than being looked up again.
        // The receiver has already read the ledger, and re-reading it here
        // would repeat a disk load plus a JSON parse of up to three hundred
        // rows — and open a window where a reschedule between the two reads
        // leaves this service with nothing to play and a five-second deadline
        // to promote itself in.
        val alarm = intent?.getStringExtra(EXTRA_ALARM_JSON)?.let(PrayerAlarm::fromJsonString)
        if (alarm == null) {
            Log.w(TAG, "Started with no readable alarm; nothing to play")
            stopSelf()
            return START_NOT_STICKY
        }

        // A second adhan arriving while one plays (two prayers a minute apart
        // with a lead time, or a repeat delivery) replaces the first. Without
        // taking the old card down first, promoting onto a new id would leave
        // the previous notification behind with a stop button wired to a
        // service that has moved on.
        if (notificationId != 0 && notificationId != alarm.id) {
            PrayerNotifier.cancel(this, notificationId)
        }
        // A restart inherits nothing from the adhan it replaces. The previous
        // watchdog in particular would otherwise still be queued and would stop
        // the NEW adhan when the OLD one's five minutes were up.
        handler.removeCallbacks(watchdog)
        releasePlayer()

        currentAlarm = alarm
        runningId = alarm.id
        suppressCardOnExit = false

        if (!promote(alarm.id, PrayerNotifier.buildAdhan(this, alarm))) {
            stopSelf()
            return START_NOT_STICKY
        }
        startPlayback(alarm)
        return START_NOT_STICKY
    }

    /**
     * Leaves the adhan card behind unless the user took it away themselves.
     *
     * The card is this service's FOREGROUND notification, so stopping would
     * ordinarily delete it — and the adhan card is not a stop button with a
     * message attached, it is the reminder. Deleting it forty-five seconds after
     * the prayer would mean anyone who did not hear their phone has no idea the
     * prayer came in. Before Stage 3 the card always outlived the sound.
     *
     * So: detach it from the service, then re-post the dismissible variant over
     * the same id. Two exits skip that — the stop button and the swipe, both of
     * which go through [stop] and are the user saying they are done with it.
     */
    override fun onDestroy() {
        handler.removeCallbacks(watchdog)
        releasePlayer()
        abandonFocus()
        releaseWakeLock()

        val alarm = currentAlarm
        if (alarm != null && !suppressCardOnExit) {
            ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_DETACH)
            PrayerNotifier.postBuilt(
                this,
                alarm.id,
                PrayerNotifier.buildAdhan(this, alarm, ongoing = false),
            )
        } else {
            ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        }

        currentAlarm = null
        runningId = 0
        super.onDestroy()
    }

    /**
     * Goes foreground, declaring the manifest's `mediaPlayback` type.
     *
     * `ServiceCompat` rather than the two-branch `startForeground` the other
     * services in this app hand-write: from API 34 the type argument is
     * mandatory and omitting it throws `MissingForegroundServiceTypeException`,
     * and this is the one place where getting that wrong is silent until a
     * prayer time.
     */
    private fun promote(id: Int, notification: android.app.Notification): Boolean {
        notificationId = id
        return try {
            ServiceCompat.startForeground(
                this,
                id,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
            true
        } catch (e: Exception) {
            // Android 14 can refuse the promotion itself, not just the start,
            // when the exemption has lapsed. A service that cannot go foreground
            // will be killed mid-adhan anyway, so the caller stops — and
            // onDestroy posts the dismissible card, which is the part the user
            // still needs. Deliberately NOT posted here: the notification built
            // for the service is ongoing, and an ongoing card with a stop button
            // and no service behind it cannot be swiped away and stops nothing.
            Log.e(TAG, "Could not go foreground for alarm $id", e)
            false
        }
    }

    private fun startPlayback(alarm: PrayerAlarm) {
        val uri = soundUri(alarm)
        if (uri == null) {
            // "الصوت الافتراضي" with no system tone resolvable — before the
            // first unlock on a device whose settings provider is still
            // encrypted, or a phone whose default notification sound is "None".
            // Nothing to play, so do not hold a foreground service open; the
            // card and the channel's vibration are left behind by onDestroy.
            Log.w(TAG, "No sound for alarm ${alarm.id}; card only")
            stopSelf()
            return
        }

        acquireWakeLock()
        requestFocus()

        // Assigned BEFORE it is configured. With `player = MediaPlayer().apply {}`
        // a throw inside the block — setDataSource on a missing resource, or a
        // content URI whose provider is not up before first unlock — happens
        // before the assignment, so the instance is unreachable and its native
        // handle leaks for the life of the process.
        val media = MediaPlayer()
        player = media
        try {
            media.setAudioAttributes(alarmAttributes())
            media.setDataSource(this, uri)
            media.setOnPreparedListener { it.start() }
            media.setOnCompletionListener { stopSelf() }
            media.setOnErrorListener { _, what, extra ->
                Log.e(TAG, "MediaPlayer failed ($what/$extra) on alarm ${alarm.id}")
                stopSelf()
                true
            }
            media.prepareAsync()
        } catch (e: Exception) {
            Log.e(TAG, "Could not start the adhan for alarm ${alarm.id}", e)
            stopSelf()
            return
        }

        // Belt and braces for an mp3 that never reports completion — a
        // corrupted resource, an OEM MediaPlayer that stalls. Without it the
        // foreground notification would sit in the tray until reboot.
        handler.postDelayed(watchdog, MAX_PLAYBACK_MS)
    }

    /**
     * The adhan to play, or null if there is nothing resolvable.
     *
     * A null [PrayerAlarm.soundRes] is the "الصوت الافتراضي" option. The system
     * tone is read from the ledger's cached copy first, because
     * `RingtoneManager` is backed by the per-user settings provider and that is
     * credential-encrypted: this service now runs before the first unlock, where
     * a live lookup returns null or throws.
     */
    private fun soundUri(alarm: PrayerAlarm): Uri? {
        val res = alarm.soundRes
        if (!res.isNullOrEmpty()) {
            return Uri.parse("android.resource://$packageName/raw/$res")
        }

        PrayerAlarmStore.defaultSoundUri(this)?.let { cached ->
            runCatching { Uri.parse(cached) }.getOrNull()?.let { return it }
        }

        return try {
            // getActualDefaultRingtoneUri, not getDefaultUri: the latter returns
            // the CONSTANT content://settings/system/notification_sound, which
            // has to be read back through the settings provider at play time —
            // the very thing that is unavailable before the first unlock. This
            // resolves to the media URI the user actually chose, and returns
            // null when they chose "None".
            RingtoneManager.getActualDefaultRingtoneUri(
                this,
                RingtoneManager.TYPE_NOTIFICATION,
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun alarmAttributes(): AudioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()

    /**
     * Asks other apps to stand down, and does not care much if they refuse.
     *
     * The request is `GAIN_TRANSIENT`, so music and podcasts pause and resume
     * around the adhan rather than being stopped. A refusal is logged and
     * ignored: a prayer alert that declined to sound because a media player
     * would not yield is a failed reminder, and alarm-stream audio is allowed to
     * be assertive.
     */
    private fun requestFocus() {
        val manager = getSystemService(AudioManager::class.java) ?: return
        val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(alarmAttributes())
                .setOnAudioFocusChangeListener(focusListener, handler)
                .build()
            focusRequest = request
            manager.requestAudioFocus(request)
        } else {
            legacyFocusListener = focusListener
            @Suppress("DEPRECATION")
            manager.requestAudioFocus(
                focusListener,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            )
        }

        if (granted != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            Log.i(TAG, "Audio focus refused; playing anyway")
        }
    }

    private fun abandonFocus() {
        val manager = getSystemService(AudioManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { manager.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            legacyFocusListener?.let {
                @Suppress("DEPRECATION")
                manager.abandonAudioFocus(it)
            }
            legacyFocusListener = null
        }
    }

    /**
     * Keeps the CPU up for the length of the adhan.
     *
     * The wake lock AlarmManager hands a broadcast receiver lasts only as long
     * as `onReceive`, and a foreground service does not imply one. Without this
     * the device can suspend mid-adhan on a screen that was already off — which
     * is every Fajr.
     */
    private fun acquireWakeLock() {
        if (wakeLock != null) return
        val power = getSystemService(PowerManager::class.java) ?: return
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKE_LOCK_TAG).apply {
            setReferenceCounted(false)
            // The timeout is the real guarantee. onDestroy releases it in every
            // path this file controls, but a process death is not one of them.
            acquire(MAX_PLAYBACK_MS)
        }
    }

    private fun releaseWakeLock() {
        runCatching { wakeLock?.takeIf { it.isHeld }?.release() }
        wakeLock = null
    }

    private fun releasePlayer() {
        val current = player ?: return
        player = null
        runCatching {
            if (current.isPlaying) current.stop()
        }
        runCatching { current.reset() }
        runCatching { current.release() }
    }

    companion object {
        private const val TAG = "PrayerAlarms"
        private const val WAKE_LOCK_TAG = "wadhakir:adhan"

        /** Longest any bundled adhan runs is ~45s; this is a stuck-player guard. */
        private const val MAX_PLAYBACK_MS = 5 * 60 * 1000L

        private const val DUCK_VOLUME = 0.25f

        const val ACTION_PLAY = "com.bloom.wadhakir.ADHAN_PLAY"
        const val ACTION_STOP = "com.bloom.wadhakir.ADHAN_STOP"

        const val EXTRA_ALARM_JSON = "alarm_json"

        /**
         * The alarm id currently sounding, or 0.
         *
         * Process-global because the only reader is [stop], which runs in a
         * BroadcastReceiver in this same process, on this same main thread.
         */
        @Volatile
        private var runningId: Int = 0

        /**
         * Set when the user is the one ending the adhan, so `onDestroy` takes
         * the card away instead of leaving it behind.
         */
        @Volatile
        private var suppressCardOnExit: Boolean = false

        fun playIntent(context: Context, alarm: PrayerAlarm): Intent =
            Intent(context, AdhanPlaybackService::class.java).apply {
                action = ACTION_PLAY
                putExtra(EXTRA_ALARM_JSON, alarm.toJson().toString())
            }

        /**
         * Stops the adhan [id] is sounding, if it is the one sounding.
         *
         * The id check matters now that a card outlives its playback. Yesterday's
         * Maghrib card can still be sitting in the tray when today's Fajr rings,
         * and its stop button must take its own card away without silencing a
         * different prayer that is mid-adhan.
         *
         * `stopService` rather than a stop Intent: stopping is allowed from the
         * background on every API level, and starting is not. Safe when nothing
         * is running — it is then a no-op.
         *
         * Returns true when a sounding adhan was actually stopped.
         */
        fun stop(context: Context, id: Int = -1): Boolean {
            if (id >= 0 && runningId != 0 && runningId != id) {
                Log.i(TAG, "Stop for $id ignored; $runningId is the one playing")
                return false
            }
            suppressCardOnExit = true
            runCatching {
                context.stopService(Intent(context, AdhanPlaybackService::class.java))
            }
            return true
        }
    }
}
