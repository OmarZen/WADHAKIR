package com.bloom.wadhakir

import android.media.AudioManager
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The hardware-button stop rules. See [AdhanStopRules] for why each one fails
 * silently if it is wrong.
 */
class AdhanStopRulesTest {

    private val ring = 2
    private val music = 3
    private val notification = 5

    // --- screen on (the power key from a dark screen) ------------------------

    @Test
    fun `a screen that lights with the adhan is the notification, not the user`() {
        // Phones that wake for an arriving notification do it in this instant.
        // Read it as the power key and every adhan on them stops itself.
        assertFalse(AdhanStopRules.stopsOnScreenOn(sinceStartMs = 0L, chargerChanged = false))
        assertFalse(AdhanStopRules.stopsOnScreenOn(sinceStartMs = 400L, chargerChanged = false))
    }

    @Test
    fun `waking the screen after the grace window stops the adhan`() {
        assertTrue(AdhanStopRules.stopsOnScreenOn(sinceStartMs = 5_000L, chargerChanged = false))
        assertTrue(
            AdhanStopRules.stopsOnScreenOn(sinceStartMs = 3L * 60L * 1000L, chargerChanged = false),
        )
    }

    @Test
    fun `the grace boundary is two seconds, exact on both sides`() {
        // Literal values, not WAKE_GRACE_MS ± 1, so the window cannot be
        // shortened without this test noticing. Too short and a slow phone's
        // notification wake stops every adhan; too long and an early press is
        // ignored.
        assertEquals(2_000L, AdhanStopRules.WAKE_GRACE_MS)
        assertFalse(AdhanStopRules.stopsOnScreenOn(sinceStartMs = 1_999L, chargerChanged = false))
        assertTrue(AdhanStopRules.stopsOnScreenOn(sinceStartMs = 2_000L, chargerChanged = false))
    }

    @Test
    fun `a wake from plugging in the charger is not the power key`() {
        // Putting the phone on its charger at Isha lights the screen on many
        // phones, with no thought of the adhan.
        assertFalse(AdhanStopRules.stopsOnScreenOn(sinceStartMs = 30_000L, chargerChanged = true))
    }

    // --- screen off (the power key from a lit screen) ------------------------

    @Test
    fun `a screen going dark is the power key only while the service holds it on`() {
        assertTrue(AdhanStopRules.stopsOnScreenOff(screenHeld = true))
    }

    @Test
    fun `an unheld screen going dark may be a timeout and never stops the adhan`() {
        // Someone who puts the phone down mid-adhan must not have it cut off
        // thirty seconds later by the screen timing out.
        assertFalse(AdhanStopRules.stopsOnScreenOff(screenHeld = false))
    }

    // --- volume broadcast ----------------------------------------------------

    @Test
    fun `the alarm stream constant is Android's`() {
        // A compile-time constant, so this reads no Android class at runtime.
        assertEquals(AudioManager.STREAM_ALARM, AdhanStopRules.STREAM_ALARM)
    }

    @Test
    fun `an alarm slider that moved stops the adhan in either direction`() {
        val alarm = AdhanStopRules.STREAM_ALARM
        assertTrue(AdhanStopRules.stopsOnVolumeChange(alarm, previous = 6, current = 5))
        assertTrue(AdhanStopRules.stopsOnVolumeChange(alarm, previous = 5, current = 6))
    }

    @Test
    fun `other streams moving never stop the adhan`() {
        // Prayer-time auto-silent apps turn the ringer down at exactly the
        // moment the adhan sounds, and a car connecting sets the music volume.
        for (stream in listOf(ring, music, notification)) {
            assertFalse(
                "stream $stream must not stop the adhan",
                AdhanStopRules.stopsOnVolumeChange(stream, previous = 5, current = 0),
            )
        }
    }

    @Test
    fun `a broadcast with no movement does not stop the adhan`() {
        val alarm = AdhanStopRules.STREAM_ALARM
        assertFalse(AdhanStopRules.stopsOnVolumeChange(alarm, previous = 6, current = 6))
    }

    @Test
    fun `a broadcast missing any value is no information`() {
        val alarm = AdhanStopRules.STREAM_ALARM
        assertFalse(AdhanStopRules.stopsOnVolumeChange(alarm, previous = -1, current = 5))
        assertFalse(AdhanStopRules.stopsOnVolumeChange(alarm, previous = 5, current = -1))
        assertFalse(AdhanStopRules.stopsOnVolumeChange(stream = -1, previous = 6, current = 5))
    }
}
