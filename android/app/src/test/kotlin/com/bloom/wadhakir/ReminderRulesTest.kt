package com.bloom.wadhakir

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The first Kotlin tests in this project.
 *
 * They exist because the native side owns two decisions whose failure is
 * completely silent — it breaks no build, fails no Dart test, and looks correct
 * in logcat — and both of them end up as a sentence telling a user whether
 * their phone is at fault. See [ReminderRules].
 */
class ReminderRulesTest {

    private val armed = setOf(100, 101, 102)
    private val now = 1_757_800_000_000L
    private val hourAgo = now - 60L * 60L * 1000L

    // --- isLapsed ------------------------------------------------------------

    @Test
    fun `an armed alarm long past its instant is a lapse`() {
        assertTrue(
            ReminderRules.isLapsed(
                id = 100,
                fireAtEpochMs = hourAgo,
                nowMs = now,
                firedId = null,
                armedIds = armed,
            ),
        )
    }

    @Test
    fun `the alarm that is firing right now is never a lapse`() {
        // It IS still armed with an instant in the past — that is exactly what a
        // lapse looks like — and it plainly arrived, since its own firing is why
        // this code is running. Invert the comparison behind this and every
        // healthy device starts accusing itself.
        assertFalse(
            ReminderRules.isLapsed(
                id = 100,
                fireAtEpochMs = hourAgo,
                nowMs = now,
                firedId = 100,
                armedIds = armed,
            ),
        )
    }

    @Test
    fun `an alarm that was never armed is not a lapse`() {
        // A row in the plan the OS was never asked to hold cannot have been
        // dropped by the OS.
        assertFalse(
            ReminderRules.isLapsed(
                id = 999,
                fireAtEpochMs = hourAgo,
                nowMs = now,
                firedId = null,
                armedIds = armed,
            ),
        )
    }

    @Test
    fun `a future alarm is not a lapse`() {
        assertFalse(
            ReminderRules.isLapsed(
                id = 100,
                fireAtEpochMs = now + 60_000L,
                nowMs = now,
                firedId = null,
                armedIds = armed,
            ),
        )
    }

    @Test
    fun `an alarm inside the grace window is not yet a lapse`() {
        // Ordinary jitter, not a kill. The boundary is asserted on both sides so
        // a change to LAPSE_GRACE_MS has to be deliberate.
        assertFalse(
            ReminderRules.isLapsed(
                id = 100,
                fireAtEpochMs = now - ReminderRules.LAPSE_GRACE_MS + 1,
                nowMs = now,
                firedId = null,
                armedIds = armed,
            ),
        )
        assertTrue(
            ReminderRules.isLapsed(
                id = 100,
                fireAtEpochMs = now - ReminderRules.LAPSE_GRACE_MS - 1,
                nowMs = now,
                firedId = null,
                armedIds = armed,
            ),
        )
    }

    @Test
    fun `an alarm exactly at the grace boundary is not a lapse`() {
        assertFalse(
            ReminderRules.isLapsed(
                id = 100,
                fireAtEpochMs = now - ReminderRules.LAPSE_GRACE_MS,
                nowMs = now,
                firedId = null,
                armedIds = armed,
            ),
        )
    }

    // --- adhanRoute ----------------------------------------------------------

    @Test
    fun `a healthy alarm plays`() {
        assertEquals(
            ReminderRules.AdhanRoute.PLAY,
            ReminderRules.adhanRoute(
                channelAllowsAlert = true,
                overrideSilent = true,
                ringerSilenced = false,
            ),
        )
    }

    @Test
    fun `a blocked channel wins over everything else`() {
        // A service playing audio behind an invisible notification is an adhan
        // with no stop button anywhere, so this has to be caught first whatever
        // the ringer says.
        for (overrideSilent in listOf(true, false)) {
            for (silenced in listOf(true, false)) {
                assertEquals(
                    "channelAllowsAlert=false must always mute",
                    ReminderRules.AdhanRoute.MUTED,
                    ReminderRules.adhanRoute(
                        channelAllowsAlert = false,
                        overrideSilent = overrideSilent,
                        ringerSilenced = silenced,
                    ),
                )
            }
        }
    }

    @Test
    fun `a silenced phone without the override posts the card only`() {
        assertEquals(
            ReminderRules.AdhanRoute.SILENT_CARD,
            ReminderRules.adhanRoute(
                channelAllowsAlert = true,
                overrideSilent = false,
                ringerSilenced = true,
            ),
        )
    }

    @Test
    fun `the override is what makes a silenced phone still sound`() {
        // «يتجاوز الوضع الصامت», on by default. This is the whole point of it.
        assertEquals(
            ReminderRules.AdhanRoute.PLAY,
            ReminderRules.adhanRoute(
                channelAllowsAlert = true,
                overrideSilent = true,
                ringerSilenced = true,
            ),
        )
    }

    @Test
    fun `the override alone does nothing on an unsilenced phone`() {
        assertEquals(
            ReminderRules.AdhanRoute.PLAY,
            ReminderRules.adhanRoute(
                channelAllowsAlert = true,
                overrideSilent = false,
                ringerSilenced = false,
            ),
        )
    }

    // --- the wire contract ---------------------------------------------------

    @Test
    fun `each route maps to its own ledger outcome`() {
        assertEquals(
            ReminderRules.OUTCOME_MUTED,
            ReminderRules.outcomeFor(ReminderRules.AdhanRoute.MUTED),
        )
        assertEquals(
            ReminderRules.OUTCOME_SILENT,
            ReminderRules.outcomeFor(ReminderRules.AdhanRoute.SILENT_CARD),
        )
        assertEquals(
            ReminderRules.OUTCOME_SOUNDED,
            ReminderRules.outcomeFor(ReminderRules.AdhanRoute.PLAY),
        )
    }

    @Test
    fun `the outcome values are the ones Dart parses`() {
        // A contract with `ReminderFireOutcome` in reminder_ledger_entry.dart.
        // Nothing else connects the two files, and a rename on either side turns
        // every row into an outcome the reader does not recognise.
        assertEquals("sounded", ReminderRules.OUTCOME_SOUNDED)
        assertEquals("muted", ReminderRules.OUTCOME_MUTED)
        assertEquals("silent", ReminderRules.OUTCOME_SILENT)
        assertEquals("refused", ReminderRules.OUTCOME_REFUSED)
        assertEquals("orphan", ReminderRules.OUTCOME_ORPHAN)
    }

    @Test
    fun `every route has a distinct outcome`() {
        val outcomes = ReminderRules.AdhanRoute.values()
            .map { ReminderRules.outcomeFor(it) }
        assertEquals(
            "two routes sharing an outcome makes them indistinguishable in the ledger",
            outcomes.size,
            outcomes.toSet().size,
        )
    }
}
