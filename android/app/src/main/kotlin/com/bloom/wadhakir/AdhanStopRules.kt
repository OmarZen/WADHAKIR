package com.bloom.wadhakir

/**
 * When a press of the phone's own buttons should silence the adhan.
 *
 * The listening lives in [AdhanStopTriggers]; the deciding lives here, with no
 * Android types, for the same reason [ReminderRules] exists: these decisions
 * fail silently, in both directions.
 *
 *  * Too eager, and the adhan cuts itself off a second in on every phone that
 *    lights its screen for an arriving notification, or thirty seconds in on
 *    every phone whose screen simply timed out, or the moment a prayer-time
 *    auto-silent app turns the ringer down.
 *  * Too timid, and the volume and power keys go back to doing nothing — the
 *    complaint this exists to answer, and the reason people were uninstalling:
 *    an alarm-stream adhan they could only stop by opening the app and killing
 *    it.
 */
object AdhanStopRules {

    /**
     * How long after the adhan starts a screen turning on is not read as the
     * user.
     *
     * Several Android skins wake the screen for an arriving high-priority
     * notification, and the adhan card arrives in the same instant the sound
     * starts. Without this window every adhan on such a phone would silence
     * itself within a second of beginning. A wake inside the window is not
     * ignored outright: the service holds that screen on, so the user's power
     * press on it — the natural reaction to a lit card — still stops the adhan.
     */
    const val WAKE_GRACE_MS = 2_000L

    /**
     * `AudioManager.STREAM_ALARM`, the stream the adhan plays on. Mirrored here
     * so this file stays free of Android types; the test pins it to the real
     * constant.
     */
    const val STREAM_ALARM = 4

    /**
     * The screen came on while the adhan was sounding.
     *
     * The power button from a dark screen is exactly what someone does when
     * their phone starts calling the adhan in their pocket or on the nightstand
     * at Fajr, so after the grace window a wake is read as the user — unless the
     * charger was just plugged in or pulled out, which lights the screen on
     * many phones and is something people do at Isha with no thought of the
     * adhan.
     *
     * Known false stop, accepted: on a skin that wakes the screen for EVERY
     * notification, another app's notification arriving mid-adhan reads the
     * same way, and Android gives apps no way to tell the two apart — the wake
     * reason is not exposed. The alternative, ignoring wakes, would give up the
     * one-press power key in the common case to protect an opt-in setting on
     * some skins. Lift-to-wake and double-tap-to-wake also count, which is
     * intended: they are the user reaching for the phone.
     */
    fun stopsOnScreenOn(sinceStartMs: Long, chargerChanged: Boolean): Boolean =
        sinceStartMs >= WAKE_GRACE_MS && !chargerChanged

    /**
     * The screen went off while the adhan was sounding.
     *
     * Only when the service is holding the screen on. Without that hold the
     * ordinary screen timeout is indistinguishable from the power button — both
     * arrive as the same broadcast with nothing to tell them apart — and an
     * adhan that stopped itself every time the user put their phone down would
     * be a new bug in place of the old one. With the hold, the timeout cannot
     * happen, so a screen going dark is the user.
     */
    fun stopsOnScreenOff(screenHeld: Boolean): Boolean = screenHeld

    /**
     * A volume slider moved while the adhan was sounding.
     *
     * The alarm stream only. That is the one a volume press moves when the
     * adhan's own local session catches it, which is the only case this
     * broadcast is listened to for. Every other stream moves for reasons that
     * have nothing to do with the adhan and cluster at exactly the wrong moment:
     * prayer-time auto-silent apps turning the ringer down, a car or earbuds
     * connecting and setting the music volume, a ringer-mode change.
     *
     * Either value is -1 when the broadcast omits it, which is read as "no
     * information" rather than as a change.
     */
    fun stopsOnVolumeChange(stream: Int, previous: Int, current: Int): Boolean =
        stream == STREAM_ALARM && previous >= 0 && current >= 0 && previous != current
}
