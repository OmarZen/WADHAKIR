package com.bloom.wadhakir

/**
 * What the long-running services do with one `onStartCommand` delivery.
 *
 * Android-free so the JVM tests can pin every row: the failures these rules
 * prevent are all silent. A service that answers a sticky restart with
 * START_STICKY but never starts its loop looks alive in `dumpsys` and does
 * nothing, and a preview that never stops leaves a foreground notification up
 * until the process dies.
 */
object ServiceStartRules {

    /** The intent a delivery carried, reduced to what the decision needs. */
    enum class Delivery {
        START,
        STOP,
        UPDATE,

        /** No intent at all: the system restarting a START_STICKY service. */
        STICKY_RESTART,
    }

    enum class AppLockStep {
        /** Save the new config, go foreground, start the monitoring loop. */
        START,

        /** Rebuild the saved config and start, as [START] does. */
        RESTORE,

        /** The loop is running: apply the change and keep running. */
        APPLY_UPDATE,

        /**
         * Nothing is running, so the change has nothing to apply to. Keep it in
         * the saved config (the next start picks it up) and stop again instead
         * of lingering as a service with no loop.
         */
        SAVE_UPDATE_AND_STOP,

        /** Stop, forget the saved config, and do not ask to be restarted. */
        STOP,
    }

    /**
     * App lock. Before this rule a sticky restart matched no branch and
     * returned START_STICKY: alive, never monitoring, `isRunning` false. Updates
     * sent through plain `startService` created the same kind of empty service
     * whenever the monitor had died.
     */
    fun appLock(delivery: Delivery, isRunning: Boolean, hasSavedConfig: Boolean): AppLockStep =
        when (delivery) {
            Delivery.START -> AppLockStep.START
            Delivery.STOP -> AppLockStep.STOP
            Delivery.UPDATE ->
                if (isRunning) AppLockStep.APPLY_UPDATE else AppLockStep.SAVE_UPDATE_AND_STOP
            Delivery.STICKY_RESTART ->
                // Nothing saved means the lock was turned off (STOP clears it)
                // or never started: there is nothing to restore.
                if (hasSavedConfig) AppLockStep.RESTORE else AppLockStep.STOP
        }

    /**
     * Whether a step leaves the service asking to be restarted. Only a service
     * that is actually monitoring is worth bringing back.
     */
    fun appLockSticky(step: AppLockStep, wentForeground: Boolean): Boolean = when (step) {
        AppLockStep.START, AppLockStep.RESTORE -> wentForeground
        AppLockStep.APPLY_UPDATE -> true
        AppLockStep.SAVE_UPDATE_AND_STOP, AppLockStep.STOP -> false
    }

    enum class PreviewEnd {
        /** The feature is on: the preview is one more pill from a running service. */
        KEEP_RUNNING,

        /** Feature off and no pill went up: nothing to wait for. */
        STOP_NOW,

        /** Feature off and a pill is showing: stop once it has been dismissed. */
        STOP_AFTER_PILL,
    }

    /**
     * Floating dhikr "معاينة الآن". The preview has to go foreground (it was
     * started with startForegroundService), but with the feature off nothing
     * ever stopped it again, so its "active" notification stayed until the
     * process died.
     */
    fun afterPreview(featureEnabled: Boolean, pillShown: Boolean): PreviewEnd = when {
        featureEnabled -> PreviewEnd.KEEP_RUNNING
        pillShown -> PreviewEnd.STOP_AFTER_PILL
        else -> PreviewEnd.STOP_NOW
    }

    /**
     * Whether a stop should be remembered as the user turning the feature off.
     *
     * Only the notification's own button counts. The app's stops come from its
     * switch, which has already saved "off" on the Dart side; marking those too
     * would be harmless, but it would make the marker mean two things.
     */
    fun stopIsUserTurnOff(fromNotification: Boolean): Boolean = fromNotification
}
