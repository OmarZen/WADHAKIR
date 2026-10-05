package com.bloom.wadhakir

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.VolumeProvider
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.BatteryManager
import android.os.Handler
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * Lets the phone's own buttons stop a sounding adhan: volume up, volume down
 * and power.
 *
 * ## Why this is needed at all
 *
 * The adhan plays on the ALARM stream from a service with no window, so until
 * this existed none of those buttons reached it. With the screen off a volume
 * press went nowhere — Android only forwards it when a music stream or a media
 * session is playing — and the power button only toggled the screen. People
 * hit the buttons first, as they would for a ringing call, then had to tap the
 * card, open the app and kill it. A loud adhan that will not stop is what was
 * being uninstalled.
 *
 * ## Volume keys: two media sessions
 *
 * A playing media session is what Android hands volume keys to when nothing in
 * the foreground claims them, screen on or off. There are two, because neither
 * covers every phone on its own:
 *
 *  * **Remote**, opened last so it ranks first. Its [VolumeProvider] is called
 *    on every press, including volume-up at the top of the slider and
 *    volume-down at the bottom, and the alarm volume the user chose is left
 *    alone. But Android 12+ will skip a remote session that has no
 *    MediaRouter2 route behind it when the build sets
 *    `config_volumeAdjustmentForRemoteGroupSessions` false, which some vendors
 *    do.
 *  * **Local**, on the adhan's own alarm attributes. Android never skips one of
 *    these, so a press always moves the alarm volume — the resulting
 *    `VOLUME_CHANGED_ACTION` is what stops the adhan, and the slider is then
 *    put back. Its blind spot is a press that cannot move the slider:
 *    volume-up already at maximum.
 *
 * Together: every press on a phone that honours remote sessions; every press
 * that moves the slider on one that does not.
 *
 * In-app windows are different. While this app is in front, audio_service has
 * attached the Quran player's session to the window and every volume key goes
 * there; [AdhanPlaybackService.interceptVolumeKey] covers that case. Another
 * app in front with its own session attached gets the keys the same way, and
 * there the card's stop button — on screen, since the phone is in use — is the
 * way to stop it.
 *
 * ## Power key: the screen broadcasts
 *
 * No app ever sees the power key itself, only the screen turning on or off,
 * which other things also do. See [AdhanStopRules] for how the two are told
 * apart, and [holdScreen] for why a lit screen is held on.
 *
 * ## Costs, accepted knowingly
 *
 *  * While the adhan plays, one of these sessions is the system's media-button
 *    session, so a headset's play/pause does nothing — it is not a stop,
 *    because earbuds and car head units send pause on their own. Android does
 *    not hand that role back when the sessions are released: a player that was
 *    PLAYING when the adhan began resumes on its own afterwards and takes it
 *    back, but one the user had already paused does not answer a headset's
 *    play button until it is next started from its own UI. This app's Quran
 *    session claimed the same role during an adhan before these existed.
 *  * Some screen wakes that are not the user read as the user — see
 *    [AdhanStopRules.stopsOnScreenOn].
 *
 * Every piece is optional. A failure to open a session or register a receiver
 * is logged and the adhan plays on regardless: the one outcome worse than an
 * adhan that ignores the volume key is an adhan that never sounds.
 */
class AdhanStopTriggers(
    private val context: Context,
    private val handler: Handler,
    private val attributes: AudioAttributes,
    private val onStop: (trigger: String) -> Unit,
) {

    private val sessions = mutableListOf<MediaSession>()
    private var receiver: BroadcastReceiver? = null
    private var screenLock: PowerManager.WakeLock? = null

    private var armedAt = 0L
    private var armed = false

    /** The charger state last seen, to tell a plug-in wake from the user's. */
    private var plugged = UNKNOWN

    /**
     * Starts listening, for an adhan that has just begun.
     *
     * Safe to call again for a replacing adhan: everything the previous one set
     * up is released first, and the grace window restarts with the new sound.
     */
    fun arm() {
        release()
        armed = true
        armedAt = SystemClock.elapsedRealtime()
        plugged = chargerState()

        if (isScreenOn()) holdScreen()

        // Order matters. The volume-key router takes the first playing session
        // that will accept keys, and a session that starts playing goes to the
        // front — so the remote one opens second to be asked first.
        openSession(remote = false)
        openSession(remote = true)
        listen()
    }

    /** Stops listening. Idempotent; called from the service's onDestroy. */
    fun release() {
        armed = false
        receiver?.let { runCatching { context.unregisterReceiver(it) } }
        receiver = null
        sessions.forEach { session ->
            runCatching { session.isActive = false }
            runCatching { session.release() }
        }
        sessions.clear()
        runCatching { screenLock?.takeIf { it.isHeld }?.release() }
        screenLock = null
    }

    /** Returns true for the one call that actually stopped the adhan. */
    private fun fire(trigger: String): Boolean {
        if (!armed) return false
        armed = false
        Log.i(TAG, "Adhan stopped by $trigger")
        onStop(trigger)
        return true
    }

    private fun openSession(remote: Boolean) {
        val session = try {
            MediaSession(context, if (remote) "wadhakir-adhan-keys" else "wadhakir-adhan")
        } catch (e: Exception) {
            Log.w(TAG, "Could not open the ${if (remote) "remote" else "local"} adhan session", e)
            return
        }
        try {
            // Registered before anything else can reach the session: without a
            // callback, MediaSession drops volume adjustments before they reach
            // the VolumeProvider. Empty, and one per session — setCallback
            // stores the session inside it, so a shared one would be left
            // pointing at whichever session was released last.
            session.setCallback(object : MediaSession.Callback() {}, handler)
            if (remote) {
                session.setPlaybackToRemote(StopOnAdjust())
            } else {
                session.setPlaybackToLocal(attributes)
            }
            session.setPlaybackState(PLAYING)
            session.isActive = true
            sessions += session
        } catch (e: Exception) {
            Log.w(TAG, "Could not activate the ${if (remote) "remote" else "local"} adhan session", e)
            runCatching { session.release() }
        }
    }

    private fun listen() {
        val listener = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                // A sticky replay describes the past, not a press.
                if (isInitialStickyBroadcast) return
                when (intent.action) {
                    Intent.ACTION_SCREEN_ON -> onScreenOn()

                    Intent.ACTION_SCREEN_OFF -> {
                        // isHeld, not != null: a hold that has run out lets the
                        // screen time out again, and that must not read as a press.
                        val held = screenLock?.isHeld == true
                        if (AdhanStopRules.stopsOnScreenOff(held)) fire("power key")
                    }

                    VOLUME_CHANGED_ACTION -> {
                        val stream = intent.getIntExtra(EXTRA_STREAM_TYPE, -1)
                        val previous = intent.getIntExtra(EXTRA_PREV_VOLUME, -1)
                        val current = intent.getIntExtra(EXTRA_VOLUME, -1)
                        if (AdhanStopRules.stopsOnVolumeChange(stream, previous, current) &&
                            fire("volume key")
                        ) {
                            restoreAlarmVolume(previous)
                        }
                    }
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(VOLUME_CHANGED_ACTION)
        }
        try {
            // NOT_EXPORTED still receives all three: they are protected
            // broadcasts, which only the system can send, and the system's are
            // always delivered.
            ContextCompat.registerReceiver(
                context,
                listener,
                filter,
                null,
                handler,
                ContextCompat.RECEIVER_NOT_EXPORTED,
            )
            receiver = listener
        } catch (e: Exception) {
            Log.w(TAG, "Could not listen for the screen and volume broadcasts", e)
        }
    }

    private fun onScreenOn() {
        // Already stopped and waiting for onDestroy: hold nothing on the way out.
        if (!armed) return
        val since = SystemClock.elapsedRealtime() - armedAt
        val now = chargerState()
        val chargerChanged = now != UNKNOWN && plugged != UNKNOWN && now != plugged
        plugged = now

        if (AdhanStopRules.stopsOnScreenOn(since, chargerChanged)) {
            fire("power key")
        } else {
            // Lit, but not by the user — the adhan card on a skin that wakes for
            // notifications, or the charger. Hold it, so that the user's power
            // press on that lit screen, the natural reaction to it, stops the
            // adhan instead of only putting the screen back to sleep.
            holdScreen()
        }
    }

    /**
     * Puts the alarm slider back where it was before the press that stopped
     * the adhan.
     *
     * That press only moved it because the local session was the one that
     * caught it, and the remote session, which catches the same press without
     * touching any slider, was refused on this phone. Left alone, every adhan
     * stopped this way would leave the alarm a step quieter — up to five steps a
     * day, until the adhan and the user's own alarm clock were barely audible,
     * and volume-down at the bottom of the slider no longer stopped anything.
     */
    private fun restoreAlarmVolume(previous: Int) {
        try {
            context.getSystemService(AudioManager::class.java)
                ?.setStreamVolume(AudioManager.STREAM_ALARM, previous, 0)
        } catch (e: Exception) {
            Log.w(TAG, "Could not restore the alarm volume to $previous", e)
        }
    }

    private fun isScreenOn(): Boolean = try {
        context.getSystemService(PowerManager::class.java)?.isInteractive == true
    } catch (_: Exception) {
        false
    }

    /**
     * Whether the phone is on a charger, from the sticky battery broadcast.
     * Readable before the first unlock, unlike most of the settings provider.
     */
    private fun chargerState(): Int = try {
        ContextCompat.registerReceiver(
            context,
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )?.getIntExtra(BatteryManager.EXTRA_PLUGGED, UNKNOWN) ?: UNKNOWN
    } catch (_: Exception) {
        UNKNOWN
    }

    /**
     * Keeps a lit screen from timing out for the first minute of the adhan.
     *
     * Without it a screen-off is ambiguous — the user's power press, or the
     * phone simply timing out after they put it down — and only one of those
     * should stop the adhan. While the screen is held a timeout cannot happen,
     * so a screen going dark is the power key, in one press. It may dim; it is
     * never turned on if it was off.
     *
     * A minute, not the whole adhan: that is when people reach for a loud phone,
     * and a phone pocketed unlocked mid-adhan should not stay lit and touchable
     * for four more. After it lapses the screen times out as normal, a
     * screen-off is no longer read as the power key, and stopping a lit screen
     * takes two presses — off, then on — rather than risking a false stop.
     *
     * The deprecated level is the only one a windowless service can hold;
     * FLAG_KEEP_SCREEN_ON needs a window. Where the platform says it is not
     * supported, nothing is held, with the same two-press result.
     */
    @Suppress("DEPRECATION")
    private fun holdScreen() {
        if (screenLock?.isHeld == true) return
        val power = context.getSystemService(PowerManager::class.java) ?: return
        try {
            if (!power.isWakeLockLevelSupported(PowerManager.SCREEN_DIM_WAKE_LOCK)) return
            screenLock = power.newWakeLock(PowerManager.SCREEN_DIM_WAKE_LOCK, SCREEN_LOCK_TAG).apply {
                setReferenceCounted(false)
                acquire(SCREEN_HOLD_MS)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not hold the screen for the adhan", e)
            screenLock = null
        }
    }

    /** Any press of a volume key, or any drag of this session's slider, stops the adhan. */
    private inner class StopOnAdjust : VolumeProvider(VOLUME_CONTROL_ABSOLUTE, MAX_VOLUME, MAX_VOLUME) {
        override fun onAdjustVolume(direction: Int) {
            fire("volume key")
        }

        override fun onSetVolumeTo(volume: Int) {
            fire("volume key")
        }
    }

    private companion object {
        const val TAG = "PrayerAlarms"
        const val SCREEN_LOCK_TAG = "wadhakir:adhan-screen"
        const val SCREEN_HOLD_MS = 60_000L

        const val MAX_VOLUME = 10
        const val UNKNOWN = -1

        // Hidden in AudioManager, stable since API 1 and on every protected-
        // broadcast list since. Spelled out because there is no public alias.
        const val VOLUME_CHANGED_ACTION = "android.media.VOLUME_CHANGED_ACTION"
        const val EXTRA_STREAM_TYPE = "android.media.EXTRA_VOLUME_STREAM_TYPE"
        const val EXTRA_VOLUME = "android.media.EXTRA_VOLUME_STREAM_VALUE"
        const val EXTRA_PREV_VOLUME = "android.media.EXTRA_PREV_VOLUME_STREAM_VALUE"

        // No transport actions: a headset's play/pause lands on these sessions
        // while the adhan plays and is deliberately ignored, not read as a stop.
        val PLAYING: PlaybackState = PlaybackState.Builder()
            .setState(PlaybackState.STATE_PLAYING, PlaybackState.PLAYBACK_POSITION_UNKNOWN, 1f)
            .build()
    }
}
