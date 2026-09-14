package com.bloom.wadhakir

/**
 * The two decisions on the native side that can silently mislead a user, pulled
 * out where a test can reach them.
 *
 * ## Why this file exists
 *
 * Everything else in the fire path needs a `Context`, an `AlarmManager` or a
 * live `PackageManager`, so testing it means Robolectric or a device. These two
 * do not — they are pure arithmetic over booleans and longs — and they are also
 * the two whose failure is invisible:
 *
 *  * [isLapsed] decides whether the health screen **accuses the user's phone of
 *    killing the app**. Flip the `id != firedId` comparison and every
 *    successful, perfectly on-time adhan also logs itself as missed, which
 *    trips the lapse threshold and tells a healthy device it is broken.
 *  * [adhanRoute] decides whether an alarm is recorded as heard, muted, or
 *    silent. Swap two of its arms and a user who muted a channel is told their
 *    device is at fault, or a device that never plays anything is shown a green
 *    tick.
 *
 * Neither failure would break a build, fail a Dart test, or look wrong in
 * logcat. Deliberately free of Android imports so plain JUnit can load it —
 * adding an Android type here costs the tests their reason to exist.
 */
object ReminderRules {

    /**
     * How far past its instant an alarm must still be armed before the sweep
     * calls it a lapse.
     *
     * Generous on purpose: with `SCHEDULE_EXACT_ALARM` revoked the scheduler
     * degrades to `setAndAllowWhileIdle`, which is inexact by design. (That case
     * is excluded outright by the caller; this margin covers ordinary jitter.)
     */
    const val LAPSE_GRACE_MS = 5L * 60L * 1000L

    /**
     * Whether an armed alarm's moment came and went with nothing firing.
     *
     * The inference holds because firing re-arms: when an alarm fires,
     * `PrayerAlarmReceiver` calls `rearmWindow`, whose trailing `setArmedIds`
     * drops that id at a moment when its instant is roughly now. An id that is
     * *still* armed with an instant well in the past therefore never arrived.
     *
     * [firedId] is the alarm whose firing triggered this sweep, if any. It is
     * excluded because it is still in the armed set with a past instant — which
     * is what a lapse looks like — except that it plainly did arrive, and is the
     * reason the code is running at all.
     */
    fun isLapsed(
        id: Int,
        fireAtEpochMs: Long,
        nowMs: Long,
        firedId: Int?,
        armedIds: Set<Int>,
    ): Boolean =
        id != firedId &&
            id in armedIds &&
            fireAtEpochMs < nowMs - LAPSE_GRACE_MS

    /** Which way a firing alarm goes. */
    enum class AdhanRoute {
        /** The channel is blocked; post nothing and record it. */
        MUTED,

        /** The phone is silenced and the user left the override off: card only. */
        SILENT_CARD,

        /** Start the playback service. */
        PLAY,
    }

    /**
     * Where a firing alarm should go, before anything is attempted.
     *
     * The order matters and is not arbitrary. A blocked channel wins over a
     * silenced ringer because a service playing audio behind an invisible
     * notification is an adhan with no stop button anywhere — that has to be
     * caught first, whatever the ringer says.
     *
     * Both quiet routes are the user's own doing rather than a failure, which
     * is why they are kept apart: a verdict that merged them would tell someone
     * who silenced their own phone that their channel is blocked, and send them
     * to fix a setting that was never touched.
     */
    fun adhanRoute(
        channelAllowsAlert: Boolean,
        overrideSilent: Boolean,
        ringerSilenced: Boolean,
    ): AdhanRoute = when {
        !channelAllowsAlert -> AdhanRoute.MUTED
        !overrideSilent && ringerSilenced -> AdhanRoute.SILENT_CARD
        else -> AdhanRoute.PLAY
    }

    /** The ledger's `o` value for [route], before a play attempt is made. */
    fun outcomeFor(route: AdhanRoute): String = when (route) {
        AdhanRoute.MUTED -> OUTCOME_MUTED
        AdhanRoute.SILENT_CARD -> OUTCOME_SILENT
        AdhanRoute.PLAY -> OUTCOME_SOUNDED
    }

    // The wire values. They are a contract with `ReminderFireOutcome` in
    // `reminder_ledger_entry.dart`; changing one means changing that file in
    // the same commit, and rows written by the previous build are still on disk.
    const val OUTCOME_SOUNDED = "sounded"
    const val OUTCOME_MUTED = "muted"
    const val OUTCOME_SILENT = "silent"
    const val OUTCOME_REFUSED = "refused"
    const val OUTCOME_ORPHAN = "orphan"
}
