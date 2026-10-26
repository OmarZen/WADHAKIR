package com.bloom.wadhakir

import android.os.Build
import android.os.VibrationEffect
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The tasbih's buzz and click. See [TasbihFeedbackRules] for why these
 * decisions live apart from the bridge.
 */
class TasbihFeedbackRulesTest {

    private val tick = TasbihFeedbackRules.Pulse.TICK
    private val round = TasbihFeedbackRules.Pulse.ROUND

    // --- the mirrored constants ------------------------------------------------

    @Test
    fun `mirrored constants match the platform`() {
        // Compile-time constants, inlined from the SDK stubs, so this runs on
        // the JVM. If a mirror drifted, the wrong effect would play — or a
        // haptic API would be called on a release that does not have it.
        assertEquals(Build.VERSION_CODES.O, TasbihFeedbackRules.API_O)
        assertEquals(Build.VERSION_CODES.Q, TasbihFeedbackRules.API_Q)
        assertEquals(VibrationEffect.EFFECT_TICK, TasbihFeedbackRules.EFFECT_TICK)
        assertEquals(
            VibrationEffect.EFFECT_DOUBLE_CLICK,
            TasbihFeedbackRules.EFFECT_DOUBLE_CLICK,
        )
    }

    // --- hapticPlan --------------------------------------------------------------

    @Test
    fun `API 29 and up use predefined effects`() {
        for (sdk in listOf(29, 31, 34, 37)) {
            assertEquals(
                TasbihFeedbackRules.HapticPlan.PREDEFINED,
                TasbihFeedbackRules.hapticPlan(sdk, tick),
            )
            assertEquals(
                TasbihFeedbackRules.HapticPlan.PREDEFINED,
                TasbihFeedbackRules.hapticPlan(sdk, round),
            )
        }
    }

    @Test
    fun `API 26 to 28 build their own effects`() {
        for (sdk in 26..28) {
            assertEquals(
                TasbihFeedbackRules.HapticPlan.ONE_SHOT,
                TasbihFeedbackRules.hapticPlan(sdk, tick),
            )
            assertEquals(
                TasbihFeedbackRules.HapticPlan.WAVEFORM,
                TasbihFeedbackRules.hapticPlan(sdk, round),
            )
        }
    }

    @Test
    fun `below API 26 the legacy calls are used`() {
        // VibrationEffect does not exist on these releases at all; touching it
        // would throw NoClassDefFoundError on the first tap.
        assertEquals(
            TasbihFeedbackRules.HapticPlan.LEGACY_ONE_SHOT,
            TasbihFeedbackRules.hapticPlan(24, tick),
        )
        assertEquals(
            TasbihFeedbackRules.HapticPlan.LEGACY_PATTERN,
            TasbihFeedbackRules.hapticPlan(24, round),
        )
        assertEquals(
            TasbihFeedbackRules.HapticPlan.LEGACY_PATTERN,
            TasbihFeedbackRules.hapticPlan(25, round),
        )
    }

    @Test
    fun `a tap ticks and a round double-clicks`() {
        assertEquals(TasbihFeedbackRules.EFFECT_TICK, TasbihFeedbackRules.predefinedEffect(tick))
        assertEquals(
            TasbihFeedbackRules.EFFECT_DOUBLE_CLICK,
            TasbihFeedbackRules.predefinedEffect(round),
        )
    }

    @Test
    fun `the round pattern is two pulses and starts at once`() {
        val pattern = TasbihFeedbackRules.ROUND_PATTERN_MS
        assertEquals(4, pattern.size)
        assertEquals(0L, pattern[0])
        assertTrue(pattern.all { it >= 0 })
        // Short enough to read as feedback, not a notification buzz.
        assertTrue(pattern.sum() < 250L)
    }

    // --- shouldPlayClick ---------------------------------------------------------

    @Test
    fun `a loaded click on a normal ringer plays`() {
        assertTrue(
            TasbihFeedbackRules.shouldPlayClick(loaded = true, silenced = false, inCall = false),
        )
    }

    @Test
    fun `silent, vibrate or Do Not Disturb keep it quiet`() {
        assertFalse(
            TasbihFeedbackRules.shouldPlayClick(loaded = true, silenced = true, inCall = false),
        )
    }

    @Test
    fun `a call keeps it quiet`() {
        assertFalse(
            TasbihFeedbackRules.shouldPlayClick(loaded = true, silenced = false, inCall = true),
        )
    }

    @Test
    fun `nothing plays before the sample has loaded`() {
        assertFalse(
            TasbihFeedbackRules.shouldPlayClick(loaded = false, silenced = false, inCall = false),
        )
    }

    @Test
    fun `rapid clicks can overlap`() {
        assertTrue(TasbihFeedbackRules.MAX_STREAMS >= 2)
    }
}
