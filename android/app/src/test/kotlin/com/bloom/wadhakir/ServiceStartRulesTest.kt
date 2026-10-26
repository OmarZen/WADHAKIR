package com.bloom.wadhakir

import com.bloom.wadhakir.ServiceStartRules.AppLockStep
import com.bloom.wadhakir.ServiceStartRules.Delivery
import com.bloom.wadhakir.ServiceStartRules.PreviewEnd
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The start/stop rules of the app-lock and floating-dhikr services. See
 * [ServiceStartRules] for why each row fails silently when it is wrong.
 */
class ServiceStartRulesTest {

    // --- app lock: sticky restart ---------------------------------------------

    @Test
    fun `a sticky restart with a saved config restores the monitor`() {
        // The bug: this delivery matched no branch, so the service came back
        // alive, sticky and not monitoring.
        assertEquals(
            AppLockStep.RESTORE,
            ServiceStartRules.appLock(Delivery.STICKY_RESTART, isRunning = false, hasSavedConfig = true),
        )
    }

    @Test
    fun `a sticky restart with nothing saved stops instead of idling`() {
        assertEquals(
            AppLockStep.STOP,
            ServiceStartRules.appLock(Delivery.STICKY_RESTART, isRunning = false, hasSavedConfig = false),
        )
    }

    @Test
    fun `a restore the platform refuses is not sticky`() {
        // Android 12+ can refuse startForeground from the background. Asking to
        // be restarted again would only repeat the refusal.
        assertFalse(ServiceStartRules.appLockSticky(AppLockStep.RESTORE, wentForeground = false))
        assertTrue(ServiceStartRules.appLockSticky(AppLockStep.RESTORE, wentForeground = true))
    }

    // --- app lock: start, stop, update ------------------------------------------

    @Test
    fun `start always starts and is sticky only once foreground`() {
        assertEquals(
            AppLockStep.START,
            ServiceStartRules.appLock(Delivery.START, isRunning = false, hasSavedConfig = false),
        )
        assertEquals(
            AppLockStep.START,
            ServiceStartRules.appLock(Delivery.START, isRunning = true, hasSavedConfig = true),
        )
        assertTrue(ServiceStartRules.appLockSticky(AppLockStep.START, wentForeground = true))
        assertFalse(ServiceStartRules.appLockSticky(AppLockStep.START, wentForeground = false))
    }

    @Test
    fun `an update to a running monitor applies and stays sticky`() {
        val step = ServiceStartRules.appLock(Delivery.UPDATE, isRunning = true, hasSavedConfig = true)
        assertEquals(AppLockStep.APPLY_UPDATE, step)
        assertTrue(ServiceStartRules.appLockSticky(step, wentForeground = true))
    }

    @Test
    fun `an update with no monitor running saves it and stops`() {
        // Updates arrive through plain startService. With the monitor dead
        // they used to leave an empty sticky service behind.
        for (saved in listOf(true, false)) {
            val step = ServiceStartRules.appLock(Delivery.UPDATE, isRunning = false, hasSavedConfig = saved)
            assertEquals(AppLockStep.SAVE_UPDATE_AND_STOP, step)
            assertFalse(ServiceStartRules.appLockSticky(step, wentForeground = false))
        }
    }

    @Test
    fun `stop is never sticky`() {
        for (running in listOf(true, false)) {
            val step = ServiceStartRules.appLock(Delivery.STOP, isRunning = running, hasSavedConfig = true)
            assertEquals(AppLockStep.STOP, step)
            assertFalse(ServiceStartRules.appLockSticky(step, wentForeground = true))
        }
    }

    // --- floating dhikr preview ------------------------------------------------

    @Test
    fun `a preview with the feature on keeps the service`() {
        assertEquals(PreviewEnd.KEEP_RUNNING, ServiceStartRules.afterPreview(featureEnabled = true, pillShown = true))
        assertEquals(PreviewEnd.KEEP_RUNNING, ServiceStartRules.afterPreview(featureEnabled = true, pillShown = false))
    }

    @Test
    fun `a preview with the feature off always ends`() {
        // The bug: nothing ever stopped it, so "active" stayed in the shade.
        assertEquals(PreviewEnd.STOP_AFTER_PILL, ServiceStartRules.afterPreview(featureEnabled = false, pillShown = true))
        assertEquals(PreviewEnd.STOP_NOW, ServiceStartRules.afterPreview(featureEnabled = false, pillShown = false))
    }

    // --- the user's «إيقاف» -------------------------------------------------------

    @Test
    fun `only the notification button marks a user turn-off`() {
        assertTrue(ServiceStartRules.stopIsUserTurnOff(fromNotification = true))
        assertFalse(ServiceStartRules.stopIsUserTurnOff(fromNotification = false))
    }
}
