package com.bloom.wadhakir

import android.hardware.SensorManager
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Pins [QiblaSensorRules]: the magnetometer-status scale Dart reads to decide
 * whether to show the calibration card, and the input guards in front of
 * GeomagneticField. See `CompassAccuracyLevel.fromDegrees` for the Dart half.
 */
class QiblaSensorRulesTest {

    // --- the copied constants -----------------------------------------------

    @Test
    fun `the copied status values are the SDK's`() {
        // Compile-time constants, inlined from android.jar: no Android runtime
        // is touched. If the SDK ever renumbered these, the mapping below
        // would silently invert.
        assertEquals(SensorManager.SENSOR_STATUS_NO_CONTACT, QiblaSensorRules.STATUS_NO_CONTACT)
        assertEquals(SensorManager.SENSOR_STATUS_UNRELIABLE, QiblaSensorRules.STATUS_UNRELIABLE)
        assertEquals(SensorManager.SENSOR_STATUS_ACCURACY_LOW, QiblaSensorRules.STATUS_ACCURACY_LOW)
        assertEquals(SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM, QiblaSensorRules.STATUS_ACCURACY_MEDIUM)
        assertEquals(SensorManager.SENSOR_STATUS_ACCURACY_HIGH, QiblaSensorRules.STATUS_ACCURACY_HIGH)
    }

    // --- accuracyDegrees ------------------------------------------------------

    @Test
    fun `high, medium and low map to 15, 30 and 45`() {
        assertEquals(15, QiblaSensorRules.accuracyDegrees(QiblaSensorRules.STATUS_ACCURACY_HIGH))
        assertEquals(30, QiblaSensorRules.accuracyDegrees(QiblaSensorRules.STATUS_ACCURACY_MEDIUM))
        assertEquals(45, QiblaSensorRules.accuracyDegrees(QiblaSensorRules.STATUS_ACCURACY_LOW))
    }

    @Test
    fun `unreliable asks for calibration`() {
        // The sensor saying outright it needs calibrating: the one case the
        // figure-8 card exists for.
        assertEquals(45, QiblaSensorRules.accuracyDegrees(QiblaSensorRules.STATUS_UNRELIABLE))
    }

    @Test
    fun `no contact and unknown statuses are unknown, never low`() {
        // Unknown never shows the card; nagging on a reading that may well be
        // fine is worse than saying nothing.
        assertEquals(-1, QiblaSensorRules.accuracyDegrees(QiblaSensorRules.STATUS_NO_CONTACT))
        assertEquals(-1, QiblaSensorRules.accuracyDegrees(42))
    }

    // --- shouldEmit -------------------------------------------------------------

    @Test
    fun `only changes are sent`() {
        assertTrue(QiblaSensorRules.shouldEmit(null, 45))
        assertFalse(QiblaSensorRules.shouldEmit(45, 45))
        assertTrue(QiblaSensorRules.shouldEmit(45, 15))
    }

    // --- isValidPosition --------------------------------------------------------

    @Test
    fun `real coordinates are valid, the edges included`() {
        assertTrue(QiblaSensorRules.isValidPosition(30.0444, 31.2357))
        assertTrue(QiblaSensorRules.isValidPosition(-90.0, 180.0))
        assertTrue(QiblaSensorRules.isValidPosition(90.0, -180.0))
    }

    @Test
    fun `missing, non-finite or out-of-range coordinates are refused`() {
        assertFalse(QiblaSensorRules.isValidPosition(null, 31.0))
        assertFalse(QiblaSensorRules.isValidPosition(30.0, null))
        assertFalse(QiblaSensorRules.isValidPosition(Double.NaN, 31.0))
        assertFalse(QiblaSensorRules.isValidPosition(30.0, Double.POSITIVE_INFINITY))
        assertFalse(QiblaSensorRules.isValidPosition(91.0, 31.0))
        assertFalse(QiblaSensorRules.isValidPosition(30.0, 181.0))
    }

    // --- altitudeMeters -----------------------------------------------------------

    @Test
    fun `unknown or broken altitudes become sea level`() {
        assertEquals(0f, QiblaSensorRules.altitudeMeters(null), 0f)
        assertEquals(0f, QiblaSensorRules.altitudeMeters(Double.NaN), 0f)
        assertEquals(0f, QiblaSensorRules.altitudeMeters(Double.NEGATIVE_INFINITY), 0f)
    }

    @Test
    fun `real altitudes pass through and absurd ones are clamped`() {
        assertEquals(23f, QiblaSensorRules.altitudeMeters(23.0), 0f)
        assertEquals(10_000f, QiblaSensorRules.altitudeMeters(1e7), 0f)
        assertEquals(-1_000f, QiblaSensorRules.altitudeMeters(-5_000.0), 0f)
    }

    // --- camera heading -----------------------------------------------------------

    @Test
    fun `orientation radians fold into 0 to 360 degrees`() {
        assertEquals(0.0, QiblaSensorRules.azimuthDegrees(0.0), 1e-9)
        assertEquals(90.0, QiblaSensorRules.azimuthDegrees(Math.PI / 2), 1e-9)
        // getOrientation's west half is negative; it must come back as 190°,
        // never be dropped.
        assertEquals(190.0, QiblaSensorRules.azimuthDegrees(Math.toRadians(-170.0)), 1e-9)
        assertEquals(180.0, QiblaSensorRules.azimuthDegrees(-Math.PI), 1e-9)
    }

    @Test
    fun `a heading is sent on the first reading and on real moves only`() {
        assertTrue(QiblaSensorRules.shouldEmitHeading(null, 12.0))
        assertFalse(QiblaSensorRules.shouldEmitHeading(12.0, 12.1))
        assertTrue(QiblaSensorRules.shouldEmitHeading(12.0, 12.4))
    }

    @Test
    fun `heading steps are measured the short way round north`() {
        assertFalse(QiblaSensorRules.shouldEmitHeading(359.9, 0.1))
        assertTrue(QiblaSensorRules.shouldEmitHeading(359.9, 0.5))
        assertTrue(QiblaSensorRules.shouldEmitHeading(10.0, 190.0))
    }
}
