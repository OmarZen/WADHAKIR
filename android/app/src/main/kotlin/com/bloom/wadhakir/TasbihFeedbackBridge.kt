package com.bloom.wadhakir

import android.app.Activity
import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

/**
 * The tasbih's hands on the phone: keep the screen on, click, vibrate.
 *
 * Methods on [CHANNEL_NAME] (all return null):
 *  * `setKeepScreenOn(Boolean)` — hold the window awake, or let it sleep.
 *  * `prepare()` — load the click. Idempotent.
 *  * `click()` — one click, unless the phone says otherwise.
 *  * `tick()` — a tap's buzz.
 *  * `roundComplete()` — a finished round's double buzz.
 *  * `release()` — free the click; the screen is closing.
 *
 * Why native, when Flutter has `HapticFeedback` and `SystemSound`: both follow
 * system switches ("Touch feedback", "Touch sounds") that many people turn off
 * for the keyboard, and the tasbih's own switches would then look broken.
 * [Vibrator] and a [SoundPool] answer to the tasbih's switches alone — and to
 * the ringer, through [TasbihFeedbackRules.shouldPlayClick].
 *
 * Why [SoundPool] and not the app's audio player: it starts in well under
 * 20 ms, overlaps rapid clicks, and takes no audio focus, so the Quran or the
 * radio keeps playing under the click instead of pausing for it.
 */
object TasbihFeedbackBridge {

    const val CHANNEL_NAME = "com.bloom.wadhakir/tasbih_feedback"

    private const val TAG = "TasbihFeedback"

    /**
     * Weak, so a destroyed activity is never kept alive by this object, which
     * outlives every activity.
     */
    private var activityRef: WeakReference<Activity>? = null
    private var appContext: Context? = null

    /**
     * What Dart last asked for, kept here rather than only on the window.
     *
     * MainActivity is an `AudioServiceActivity`, which runs on a cached
     * engine: the Dart screen (and its wish to stay awake) outlives the
     * activity. A recreated activity — rotation, a theme change, coming back
     * from the recents after the system reclaimed it — starts with a fresh
     * window and no flag, so [register] puts the flag back.
     */
    private var wantKeepScreenOn = false

    private var soundPool: SoundPool? = null
    private var clickId = 0
    private var clickLoaded = false

    /**
     * Called from `MainActivity.configureFlutterEngine`, which runs for every
     * activity that attaches to the engine.
     */
    fun register(activity: Activity, messenger: BinaryMessenger) {
        activityRef = WeakReference(activity)
        appContext = activity.applicationContext
        applyKeepScreenOn(activity)

        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "setKeepScreenOn" -> {
                    wantKeepScreenOn = call.arguments as? Boolean ?: false
                    activityRef?.get()?.let { applyKeepScreenOn(it) }
                    result.success(null)
                }
                "prepare" -> {
                    prepare()
                    result.success(null)
                }
                "click" -> {
                    click()
                    result.success(null)
                }
                "tick" -> {
                    vibrate(TasbihFeedbackRules.Pulse.TICK)
                    result.success(null)
                }
                "roundComplete" -> {
                    vibrate(TasbihFeedbackRules.Pulse.ROUND)
                    result.success(null)
                }
                "release" -> {
                    release()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // --- keep the screen on ---------------------------------------------------

    /** On the main thread: the channel handler and configureFlutterEngine both are. */
    private fun applyKeepScreenOn(activity: Activity) {
        try {
            val window = activity.window ?: return
            if (wantKeepScreenOn) {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        } catch (e: Exception) {
            Log.w(TAG, "keep-screen-on not applied", e)
        }
    }

    // --- click ------------------------------------------------------------------

    private fun prepare() {
        if (soundPool != null) return
        val context = appContext ?: return
        try {
            val pool = SoundPool.Builder()
                .setMaxStreams(TasbihFeedbackRules.MAX_STREAMS)
                .setAudioAttributes(
                    // Sonification: a UI sound, on the system stream, so it
                    // follows the ringer's volume rather than the media
                    // volume someone turned up for a recitation.
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                .build()
            clickLoaded = false
            // Posted to this (main) thread's looper, so it cannot run before
            // `clickId` below is assigned. One sample, so any success is it.
            pool.setOnLoadCompleteListener { _, _, status -> clickLoaded = status == 0 }
            // Named through R so resource shrinking sees the reference and
            // keeps the file; keep.xml needs no entry for it.
            clickId = pool.load(context, R.raw.tasbih_click, 1)
            soundPool = pool
        } catch (e: Exception) {
            Log.w(TAG, "click not prepared", e)
        }
    }

    private fun click() {
        val context = appContext ?: return
        val pool = soundPool
        if (pool == null) {
            // Switched on mid-session before prepare landed: load for the next
            // tap rather than block this one.
            prepare()
            return
        }
        val play = TasbihFeedbackRules.shouldPlayClick(
            loaded = clickLoaded,
            silenced = PhoneQuiet.isSilenced(context),
            inCall = PhoneQuiet.isInCall(context),
        )
        if (!play) return
        try {
            pool.play(clickId, 1f, 1f, 1, 0, 1f)
        } catch (e: Exception) {
            Log.w(TAG, "click failed", e)
        }
    }

    private fun release() {
        try {
            soundPool?.release()
        } catch (e: Exception) {
            Log.w(TAG, "release failed", e)
        }
        soundPool = null
        clickId = 0
        clickLoaded = false
    }

    // --- vibrate ----------------------------------------------------------------

    private fun vibrator(context: Context): Vibrator? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            legacyVibrator(context)
        }
    } catch (_: Exception) {
        null
    }

    @Suppress("DEPRECATION")
    private fun legacyVibrator(context: Context): Vibrator? =
        context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator

    /**
     * Straight to [Vibrator], not `View.performHapticFeedback`: that one is
     * dropped when the system's touch-feedback setting is off, even with the
     * tasbih's own vibrate switch on. `VIBRATE` is already in the manifest.
     */
    private fun vibrate(pulse: TasbihFeedbackRules.Pulse) {
        val context = appContext ?: return
        val v = vibrator(context) ?: return
        try {
            if (!v.hasVibrator()) return
            when (TasbihFeedbackRules.hapticPlan(Build.VERSION.SDK_INT, pulse)) {
                TasbihFeedbackRules.HapticPlan.PREDEFINED ->
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        v.vibrate(
                            VibrationEffect.createPredefined(
                                TasbihFeedbackRules.predefinedEffect(pulse),
                            ),
                        )
                    }
                TasbihFeedbackRules.HapticPlan.ONE_SHOT ->
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        v.vibrate(
                            VibrationEffect.createOneShot(
                                TasbihFeedbackRules.TICK_MS,
                                VibrationEffect.DEFAULT_AMPLITUDE,
                            ),
                        )
                    }
                TasbihFeedbackRules.HapticPlan.WAVEFORM ->
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        v.vibrate(
                            VibrationEffect.createWaveform(
                                TasbihFeedbackRules.ROUND_PATTERN_MS,
                                -1,
                            ),
                        )
                    }
                TasbihFeedbackRules.HapticPlan.LEGACY_ONE_SHOT -> legacyOneShot(v)
                TasbihFeedbackRules.HapticPlan.LEGACY_PATTERN -> legacyPattern(v)
            }
        } catch (e: Exception) {
            Log.w(TAG, "vibrate failed", e)
        }
    }

    @Suppress("DEPRECATION")
    private fun legacyOneShot(v: Vibrator) = v.vibrate(TasbihFeedbackRules.TICK_MS)

    @Suppress("DEPRECATION")
    private fun legacyPattern(v: Vibrator) = v.vibrate(TasbihFeedbackRules.ROUND_PATTERN_MS, -1)
}
