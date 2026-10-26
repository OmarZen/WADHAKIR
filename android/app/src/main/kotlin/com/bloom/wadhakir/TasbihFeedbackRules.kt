package com.bloom.wadhakir

/**
 * What the tasbih's buzz and click do on a given phone.
 *
 * The doing lives in [TasbihFeedbackBridge]; the deciding lives here, with no
 * Android types, for the same reason [ReminderRules] and [AdhanStopRules]
 * exist: a wrong answer here fails silently. A haptic API called on a release
 * that lacks it throws (and the count still lands, so nobody notices the buzz
 * is gone), and a click played over a call or a silent ringer is the app
 * making noise the user has asked the phone not to make.
 */
object TasbihFeedbackRules {

    /** `Build.VERSION_CODES.O`: `VibrationEffect` exists from here. */
    const val API_O = 26

    /** `Build.VERSION_CODES.Q`: `VibrationEffect.createPredefined` from here. */
    const val API_Q = 29

    /**
     * `VibrationEffect.EFFECT_TICK` and `EFFECT_DOUBLE_CLICK`, mirrored so this
     * file stays free of Android types; the test pins them to the real
     * constants.
     */
    const val EFFECT_TICK = 2
    const val EFFECT_DOUBLE_CLICK = 1

    /** A tap's buzz before predefined effects: short enough to read as a tick. */
    const val TICK_MS = 12L

    /**
     * A finished round before predefined effects: off, on, off, on — two short
     * pulses, so it is felt as different from a tap without looking.
     */
    val ROUND_PATTERN_MS = longArrayOf(0L, 18L, 90L, 28L)

    /**
     * Clicks that may overlap. A fast thumb taps faster than the 50 ms click
     * lasts; with one stream each new tap would cut the last one off.
     */
    const val MAX_STREAMS = 4

    enum class Pulse { TICK, ROUND }

    enum class HapticPlan {
        /** `VibrationEffect.createPredefined`, API 29+. */
        PREDEFINED,

        /** `VibrationEffect.createOneShot`, API 26–28. */
        ONE_SHOT,

        /** `VibrationEffect.createWaveform`, API 26–28. */
        WAVEFORM,

        /** `Vibrator.vibrate(long)`, below 26. */
        LEGACY_ONE_SHOT,

        /** `Vibrator.vibrate(long[], int)`, below 26. */
        LEGACY_PATTERN,
    }

    fun hapticPlan(sdkInt: Int, pulse: Pulse): HapticPlan = when {
        sdkInt >= API_Q -> HapticPlan.PREDEFINED
        sdkInt >= API_O ->
            if (pulse == Pulse.TICK) HapticPlan.ONE_SHOT else HapticPlan.WAVEFORM
        else ->
            if (pulse == Pulse.TICK) HapticPlan.LEGACY_ONE_SHOT else HapticPlan.LEGACY_PATTERN
    }

    /** The predefined effect for [pulse], for [HapticPlan.PREDEFINED]. */
    fun predefinedEffect(pulse: Pulse): Int = when (pulse) {
        Pulse.TICK -> EFFECT_TICK
        Pulse.ROUND -> EFFECT_DOUBLE_CLICK
    }

    /**
     * Whether a click may sound. Dart only asks when the user has the click
     * switched on; this is the phone's veto on top of that.
     *
     * * Not until the sample is loaded — `SoundPool.play` on an unloaded id
     *   fails, and the first tap after opening is not worth blocking for.
     * * Not on silent, vibrate or Do Not Disturb ([PhoneQuiet.isSilenced]):
     *   the switch's own subtitle promises «لا يُسمع والهاتف على الصامت», and
     *   people count in the masjid.
     * * Not during a call ([PhoneQuiet.isInCall]), ringing or connected.
     */
    fun shouldPlayClick(loaded: Boolean, silenced: Boolean, inCall: Boolean): Boolean =
        loaded && !silenced && !inCall
}
