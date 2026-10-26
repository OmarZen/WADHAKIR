package com.bloom.wadhakir

import android.app.AppOpsManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
// Removed RenderEffect-based blur to prevent overlay content from becoming unreadable.
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.CopyOnWriteArraySet

class AppLockMonitorService : Service() {
    private data class OverlayPalette(
        val rootTop: String,
        val rootBottom: String,
        val cardTop: String,
        val cardBottom: String,
        val border: String,
        val heading: String,
        val title: String,
        val body: String,
        val reference: String,
        val accent: String,
        val primaryStart: String,
        val primaryEnd: String,
        val primaryText: String,
        val secondaryText: String,
        val secondaryFill: String,
        val secondaryBorder: String,
    )
    companion object {
        const val ACTION_START = "com.bloom.wadhakir.APP_LOCK_START"
        const val ACTION_STOP = "com.bloom.wadhakir.APP_LOCK_STOP"
        const val ACTION_UPDATE_PACKAGES = "com.bloom.wadhakir.APP_LOCK_UPDATE_PACKAGES"
        const val ACTION_UPDATE_CONFIG = "com.bloom.wadhakir.APP_LOCK_UPDATE_CONFIG"
        const val ACTION_UPDATE_PRAYER_WINDOW = "com.bloom.wadhakir.APP_LOCK_UPDATE_PRAYER_WINDOW"

        const val EXTRA_LOCKED_PACKAGES = "locked_packages"
        const val EXTRA_OVERLAY_MESSAGE = "overlay_message"
        const val EXTRA_OVERLAY_TITLE_TEXT = "overlay_title_text"
        const val EXTRA_OVERLAY_REFERENCE_TEXT = "overlay_reference_text"
        const val EXTRA_OVERLAY_MESSAGES = "overlay_messages"
        const val EXTRA_OVERLAY_REFERENCES = "overlay_references"
        const val EXTRA_OVERLAY_IS_DARK = "overlay_is_dark"
        const val EXTRA_OVERLAY_PRAYER_NAME = "overlay_prayer_name"
        const val EXTRA_PRAYER_WINDOW_START_MS = "prayer_window_start_ms"
        const val EXTRA_NEXT_PRAYER_START_MS = "next_prayer_start_ms"
        const val EXTRA_GO_HOME_BUTTON_TEXT = "go_home_button_text"
        const val EXTRA_COMPLETED_PRAYER_BUTTON_TEXT = "completed_prayer_button_text"
        const val EXTRA_HOLD_BYPASS_TEXT = "hold_bypass_text"
        const val EXTRA_KEEP_HOLDING_TEXT = "keep_holding_text"
        const val EXTRA_HOLD_READY_TEXT = "hold_ready_text"
        const val EXTRA_CONFIRM_BYPASS_TEXT = "confirm_bypass_text"
        const val EXTRA_CANCEL_TEXT = "cancel_text"
        const val EXTRA_LOCK_DURATION_MINUTES = "lock_duration_minutes"
        const val EXTRA_EMERGENCY_BYPASS_ENABLED = "emergency_bypass_enabled"

        /** Set on the notification's "Turn Off" only; see [hasUserStop]. */
        const val EXTRA_FROM_NOTIFICATION = "from_notification"

        /**
         * A START that carries no config of its own: rebuild it from the saved
         * one when the service handles it. See [restoreStartIntent].
         */
        const val EXTRA_RESTORE = "restore_saved_config"

        private const val CHANNEL_ID = "app_lock_monitor_channel"
        private const val NOTIFICATION_ID = 8011
        private const val UNTIL_CONFIRM_SAFETY_CAP_MINUTES = 60
        private const val BYPASS_GRACE_SECONDS = 10
        private const val BYPASS_HOLD_MS = 3_000L
        private const val BYPASS_DEBOUNCE_MS = 1_000L
        private const val FOREGROUND_GRACE_MS = 3_500L

        @Volatile
        var isRunning: Boolean = false
            private set

        private const val TAG = "AppLockMonitorService"
        private const val PREFS = "app_lock_native"
        private const val KEY_CONFIG = "start_config"
        private const val KEY_USER_STOP = "stoppedByUser"
        private const val KEY_PRAYER_COMPLETED_UNTIL = "prayerCompletedUntilMs"

        private val STRING_EXTRAS = listOf(
            EXTRA_OVERLAY_MESSAGE,
            EXTRA_OVERLAY_TITLE_TEXT,
            EXTRA_OVERLAY_REFERENCE_TEXT,
            EXTRA_OVERLAY_PRAYER_NAME,
            EXTRA_GO_HOME_BUTTON_TEXT,
            EXTRA_COMPLETED_PRAYER_BUTTON_TEXT,
            EXTRA_HOLD_BYPASS_TEXT,
            EXTRA_KEEP_HOLDING_TEXT,
            EXTRA_HOLD_READY_TEXT,
            EXTRA_CONFIRM_BYPASS_TEXT,
            EXTRA_CANCEL_TEXT,
        )
        private val LIST_EXTRAS = listOf(
            EXTRA_LOCKED_PACKAGES,
            EXTRA_OVERLAY_MESSAGES,
            EXTRA_OVERLAY_REFERENCES,
        )
        private val BOOLEAN_EXTRAS = listOf(EXTRA_OVERLAY_IS_DARK, EXTRA_EMERGENCY_BYPASS_ENABLED)
        private val LONG_EXTRAS = listOf(EXTRA_PRAYER_WINDOW_START_MS, EXTRA_NEXT_PRAYER_START_MS)

        /**
         * Whether a START config is saved, i.e. the lock was started and not
         * turned off since. Only START creates one and STOP removes it, so a
         * late update can never bring back a lock the user switched off.
         */
        fun hasSavedConfig(context: Context): Boolean =
            prefs(context).getString(KEY_CONFIG, null) != null

        /**
         * An ACTION_START intent rebuilt from the saved config, or null when
         * nothing is saved.
         *
         * The config only ever arrived as intent extras, so when Android killed
         * the process and restarted this START_STICKY service it came back with
         * a null intent and nothing to monitor. The texts in it are the
         * localized ones Dart built from `context.l10n`; native code cannot
         * build them, so they are kept rather than recomputed.
         */
        fun restoredStartIntent(context: Context): Intent? {
            val raw = prefs(context).getString(KEY_CONFIG, null) ?: return null
            val json = try {
                JSONObject(raw)
            } catch (e: Exception) {
                Log.w(TAG, "Discarding unreadable saved config", e)
                return null
            }
            return Intent(context, AppLockMonitorService::class.java).apply {
                action = ACTION_START
                for (key in STRING_EXTRAS) {
                    if (json.has(key)) putExtra(key, json.optString(key))
                }
                for (key in LIST_EXTRAS) {
                    val array = json.optJSONArray(key) ?: continue
                    putStringArrayListExtra(
                        key,
                        ArrayList((0 until array.length()).map { array.optString(it) }),
                    )
                }
                for (key in BOOLEAN_EXTRAS) {
                    if (json.has(key)) putExtra(key, json.optBoolean(key))
                }
                for (key in LONG_EXTRAS) {
                    if (json.has(key)) putExtra(key, json.optLong(key))
                }
                if (json.has(EXTRA_LOCK_DURATION_MINUTES)) {
                    // 0 is how "until I confirm" travels; see the START branch.
                    putExtra(EXTRA_LOCK_DURATION_MINUTES, json.optInt(EXTRA_LOCK_DURATION_MINUTES))
                }
            }
        }

        /**
         * The intent that brings the monitor back from its saved config.
         *
         * Deliberately empty: the service reads the saved config when it
         * handles this, not when the app sends it. Reading it here raced the
         * prayer-window update the app sends just before; whichever reached
         * the service second decided which window the lock used.
         */
        fun restoreStartIntent(context: Context): Intent =
            Intent(context, AppLockMonitorService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_RESTORE, true)
            }

        /**
         * True once the user has pressed "Turn Off" on the notification, until
         * Dart acknowledges it. Same contract as
         * [FloatingDhikrService.hasUserStop]: the switch lives in Dart's
         * settings, which native code must not write, so Dart saves "off" and
         * then calls [clearUserStop].
         */
        fun hasUserStop(context: Context): Boolean =
            prefs(context).getBoolean(KEY_USER_STOP, false)

        fun clearUserStop(context: Context) {
            prefs(context).edit().remove(KEY_USER_STOP).apply()
        }

        private fun prefs(context: Context) =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        /** Writes the extras [intent] carries over the saved config. */
        private fun saveExtras(context: Context, intent: Intent, base: JSONObject) {
            for (key in STRING_EXTRAS) {
                intent.getStringExtra(key)?.let { base.put(key, it) }
            }
            for (key in LIST_EXTRAS) {
                intent.getStringArrayListExtra(key)?.let { base.put(key, JSONArray(it)) }
            }
            for (key in BOOLEAN_EXTRAS) {
                if (intent.hasExtra(key)) base.put(key, intent.getBooleanExtra(key, false))
            }
            for (key in LONG_EXTRAS) {
                if (intent.hasExtra(key)) base.put(key, intent.getLongExtra(key, 0L))
            }
            if (intent.hasExtra(EXTRA_LOCK_DURATION_MINUTES)) {
                base.put(EXTRA_LOCK_DURATION_MINUTES, intent.getIntExtra(EXTRA_LOCK_DURATION_MINUTES, 0))
            }
            prefs(context).edit().putString(KEY_CONFIG, base.toString()).apply()
        }

        private fun saveStartConfig(context: Context, intent: Intent) {
            saveExtras(context, intent, JSONObject())
            // Turned on again: an earlier "Turn Off" no longer speaks for the
            // user. Left set, Dart would read it later and switch the lock
            // the user just turned on back off.
            prefs(context).edit().remove(KEY_USER_STOP).apply()
        }

        /** Folds an update into the saved config. Never creates one. */
        private fun mergeIntoSavedConfig(context: Context, intent: Intent) {
            val raw = prefs(context).getString(KEY_CONFIG, null) ?: return
            val base = try {
                JSONObject(raw)
            } catch (_: Exception) {
                return
            }
            saveExtras(context, intent, base)
        }

        private fun forgetConfig(context: Context, userTurnedOff: Boolean) {
            val edit = prefs(context).edit()
                .remove(KEY_CONFIG)
                .remove(KEY_PRAYER_COMPLETED_UNTIL)
            if (userTurnedOff) edit.putBoolean(KEY_USER_STOP, true)
            edit.apply()
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private val lockedPackages = CopyOnWriteArraySet<String>()

    private var overlayMessage: String = "Take this time for something beneficial."
    private var overlayTitleText: String = "Valuable time"
    private var overlayReferenceText: String = ""
    private var overlayPrayerName: String = "Prayer time"
    private var goHomeButtonText: String = "Return to home"
    private var completedPrayerButtonText: String = "I completed prayer"
    private var holdBypassText: String = "Hold 3 seconds for emergency bypass"
    private var keepHoldingText: String = "Keep holding..."
    private var holdReadyText: String = "Hold complete. Confirm to unlock for 10 seconds."
    private var confirmBypassText: String = "Confirm emergency bypass"
    private var cancelText: String = "Cancel"
    private var overlayIsDark: Boolean = false
    private var currentBlockedPackage: String? = null
    private var lockDurationMinutes: Int? = 15
    private var emergencyBypassEnabled: Boolean = true
    private var lockStartedAtMs: Long = 0L
    private var lockExpiresAtMs: Long = 0L
    private var prayerWindowStartMs: Long = 0L
    private var nextPrayerStartMs: Long = 0L
    private var prayerCompletedUntilMs: Long = 0L
    private var globallyBypassedUntilMs: Long = 0L
    private var temporarilyAllowedPackage: String? = null
    private var lastBypassTriggeredAtMs: Long = 0L
    private var quoteCursor = -1
    private var lastForegroundPackage: String? = null
    private var lastForegroundTimestampMs: Long = 0L

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var overlayVisible = false
    private var overlayPinned = false

    private var bypassConfirmButton: Button? = null
    private var bypassCancelButton: Button? = null
    private var bypassHintText: TextView? = null
    private var bypassHoldRunnable: Runnable? = null
    private var bypassReadyForConfirmation = false

    private val overlayMessages = mutableListOf<String>()
    private val overlayReferences = mutableListOf<String>()

    private val blockedPackagePrefixes = listOf(
        "com.android.systemui",
        "com.android.launcher",
        "com.google.android.launcher",
        "com.sec.android.app.launcher",
        "com.miui.home",
        "com.huawei.android.launcher",
        "com.oppo.launcher",
        "com.coloros.launcher",
        "com.vivo.launcher",
    )

    private val blockedPackageExact = setOf(
        "com.android.settings",
        "com.google.android.permissioncontroller",
        "com.android.permissioncontroller",
    )

    private val monitorRunnable = object : Runnable {
        override fun run() {
            try {
                if (hasUsageAccessPermission()) {
                    val topPackage = getForegroundPackageName()
                    val now = System.currentTimeMillis()

                    if (prayerCompletedUntilMs > 0L) {
                        if (now < prayerCompletedUntilMs) {
                            if (overlayVisible) {
                                hideOverlayIfNeeded()
                            }
                            return
                        }
                        prayerCompletedUntilMs = 0L
                    }

                    val inPrayerWindow = isPrayerWindowActive(now)
                    if (!inPrayerWindow && !overlayPinned) {
                        hideOverlayIfNeeded()
                        return
                    }

                    // continue monitoring

                    if (lockExpiresAtMs > 0L && now >= lockExpiresAtMs) {
                        temporarilyAllowedPackage = currentBlockedPackage
                        lockExpiresAtMs = 0L
                        lockStartedAtMs = 0L
                        hideOverlayIfNeeded()
                        return
                    }

                    if (now >= globallyBypassedUntilMs) {
                        globallyBypassedUntilMs = 0L
                    }

                    if (!temporarilyAllowedPackage.isNullOrBlank() && topPackage != temporarilyAllowedPackage) {
                        temporarilyAllowedPackage = null
                    }

                    if (
                        !topPackage.isNullOrBlank() &&
                        !shouldSkipBlockingPackage(topPackage) &&
                        lockedPackages.contains(topPackage)
                    ) {
                        if (globallyBypassedUntilMs > now) {
                            hideOverlayIfNeeded()
                            return
                        }

                        if (temporarilyAllowedPackage == topPackage) {
                            hideOverlayIfNeeded()
                            return
                        }

                        if (!(overlayVisible && currentBlockedPackage == topPackage)) {
                            lockStartedAtMs = now
                            lockExpiresAtMs = lockDurationMinutes
                                ?.coerceAtMost(UNTIL_CONFIRM_SAFETY_CAP_MINUTES)
                                ?.let { now + it * 60_000L }
                                ?: 0L
                        }

                        showOverlay(topPackage)
                    } else {
                        if (overlayPinned) {
                            return
                        }
                        if (overlayVisible && currentBlockedPackage != null && topPackage == packageName) {
                            return
                        }
                        hideOverlayIfNeeded()
                        lockExpiresAtMs = 0L
                        lockStartedAtMs = 0L
                    }
                } else {
                    hideOverlayIfNeeded()
                }
            } finally {
                handler.postDelayed(this, 1100)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val restoreStart = intent?.action == ACTION_START &&
            intent.getBooleanExtra(EXTRA_RESTORE, false)
        val delivery = when (intent?.action) {
            null -> ServiceStartRules.Delivery.STICKY_RESTART
            // The app asking for the saved config: the same as the system's
            // restart, decided against the config as it is now.
            ACTION_START ->
                if (restoreStart) {
                    ServiceStartRules.Delivery.STICKY_RESTART
                } else {
                    ServiceStartRules.Delivery.START
                }
            ACTION_STOP -> ServiceStartRules.Delivery.STOP
            ACTION_UPDATE_PACKAGES, ACTION_UPDATE_CONFIG, ACTION_UPDATE_PRAYER_WINDOW ->
                ServiceStartRules.Delivery.UPDATE
            // Nothing sends anything else. Treat it like a restart rather than
            // reaching the old fall-through that returned START_STICKY.
            else -> ServiceStartRules.Delivery.STICKY_RESTART
        }
        val step = ServiceStartRules.appLock(delivery, isRunning, hasSavedConfig(this))

        return when (step) {
            ServiceStartRules.AppLockStep.START -> {
                saveStartConfig(this, intent!!)
                startMonitoring(intent, startId, step)
            }

            ServiceStartRules.AppLockStep.RESTORE -> {
                val restored = restoredStartIntent(this)
                    ?: return stopStartedForeground(startId, restoreStart)
                startMonitoring(restored, startId, step)
            }

            ServiceStartRules.AppLockStep.APPLY_UPDATE -> {
                mergeIntoSavedConfig(this, intent!!)
                applyUpdate(intent)
                START_STICKY
            }

            ServiceStartRules.AppLockStep.SAVE_UPDATE_AND_STOP -> {
                // The app pushes its next start from this config (Dart's
                // ensureLockMonitor on resume), so the change is not lost.
                mergeIntoSavedConfig(this, intent!!)
                stopWithoutRestart(startId)
            }

            ServiceStartRules.AppLockStep.STOP -> {
                if (delivery == ServiceStartRules.Delivery.STOP) {
                    forgetConfig(
                        this,
                        userTurnedOff = ServiceStartRules.stopIsUserTurnOff(
                            intent!!.getBooleanExtra(EXTRA_FROM_NOTIFICATION, false),
                        ),
                    )
                }
                stopMonitoringLoop()
                hideOverlayIfNeeded()
                lockExpiresAtMs = 0L
                stopStartedForeground(startId, restoreStart)
            }
        }
    }

    /**
     * Stops; first goes foreground if this start came through
     * startForegroundService (the app's restore). Android requires that
     * call even from a service that is about to stop, and crashes the app
     * when it is missing.
     */
    private fun stopStartedForeground(startId: Int, startedForeground: Boolean): Int {
        if (startedForeground) startInForeground()
        stopForeground(STOP_FOREGROUND_REMOVE)
        return stopWithoutRestart(startId)
    }

    /** Applies a START config, goes foreground and starts the loop. */
    private fun startMonitoring(
        intent: Intent,
        startId: Int,
        step: ServiceStartRules.AppLockStep,
    ): Int {
        val packages = intent.getStringArrayListExtra(EXTRA_LOCKED_PACKAGES) ?: arrayListOf()
        lockedPackages.clear()
        lockedPackages.addAll(packages.filterNot(::shouldSkipBlockingPackage))
        overlayMessage = intent.getStringExtra(EXTRA_OVERLAY_MESSAGE)
            ?: overlayMessage
        applyOverlayTextConfig(intent)
        applyOverlayTheme(intent)
        applyPrayerWindowConfig(intent)
        applyOverlayQuotes(intent)
        lockDurationMinutes =
            if (intent.hasExtra(EXTRA_LOCK_DURATION_MINUTES)) {
                val rawDuration = intent.getIntExtra(EXTRA_LOCK_DURATION_MINUTES, 0)
                if (rawDuration > 0) rawDuration else null
            } else {
                lockDurationMinutes
            }
        emergencyBypassEnabled =
            intent.getBooleanExtra(
                EXTRA_EMERGENCY_BYPASS_ENABLED,
                emergencyBypassEnabled,
            )
        globallyBypassedUntilMs = 0L
        temporarilyAllowedPackage = null
        lockStartedAtMs = 0L
        lockExpiresAtMs = 0L
        // "I completed prayer" lasts until the next prayer. Kept on disk so a
        // monitor restored after a kill does not lock the apps again.
        val completedUntil = prefs(this).getLong(KEY_PRAYER_COMPLETED_UNTIL, 0L)
        prayerCompletedUntilMs =
            if (completedUntil > System.currentTimeMillis()) completedUntil else 0L

        val wentForeground = startInForeground()
        if (!ServiceStartRules.appLockSticky(step, wentForeground)) {
            // The config stays saved: the app restarts the monitor from it
            // the next time it is opened (ensureLockMonitor).
            return stopWithoutRestart(startId)
        }
        startMonitoringLoop()
        isRunning = true
        return START_STICKY
    }

    private fun applyUpdate(intent: Intent) {
        when (intent.action) {
            ACTION_UPDATE_PACKAGES -> {
                val packages = intent.getStringArrayListExtra(EXTRA_LOCKED_PACKAGES) ?: arrayListOf()
                lockedPackages.clear()
                lockedPackages.addAll(packages.filterNot(::shouldSkipBlockingPackage))
            }

            ACTION_UPDATE_CONFIG -> {
                val packages = intent.getStringArrayListExtra(EXTRA_LOCKED_PACKAGES) ?: arrayListOf()
                lockedPackages.clear()
                lockedPackages.addAll(packages.filterNot(::shouldSkipBlockingPackage))
                applyOverlayTextConfig(intent)
                applyOverlayTheme(intent)
                applyPrayerWindowConfig(intent)
                applyOverlayQuotes(intent)

                lockDurationMinutes =
                    if (intent.hasExtra(EXTRA_LOCK_DURATION_MINUTES)) {
                        val rawDuration = intent.getIntExtra(EXTRA_LOCK_DURATION_MINUTES, 0)
                        if (rawDuration > 0) rawDuration else null
                    } else {
                        lockDurationMinutes
                    }
                emergencyBypassEnabled =
                    intent.getBooleanExtra(
                        EXTRA_EMERGENCY_BYPASS_ENABLED,
                        emergencyBypassEnabled,
                    )
            }

            ACTION_UPDATE_PRAYER_WINDOW -> {
                applyPrayerWindowConfig(intent)
            }
        }
    }

    /**
     * Goes foreground, or returns false when the platform refuses.
     *
     * A restart after Android killed the process happens with no activity
     * visible, and Android 12+ refuses startForeground from the background
     * with ForegroundServiceStartNotAllowedException. Holding
     * SYSTEM_ALERT_WINDOW (which the lock needs anyway) exempts the app on
     * 12-14 but not on 15+. Uncaught, the refusal crashes the process, as it
     * did for [FloatingDhikrService] on 3.4.3.
     */
    private fun startInForeground(): Boolean = try {
        // Android 14+ (API 34) requires a foreground-service type to be
        // supplied (matching the manifest's specialUse type), else
        // startForeground throws MissingForegroundServiceTypeException.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                buildNotification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, buildNotification())
        }
        true
    } catch (e: Exception) {
        Log.w(TAG, "Could not go foreground", e)
        false
    }

    /**
     * Stops without asking to be restarted. `stopSelf(startId)`, not
     * `stopSelf()`: a START the app queued meanwhile keeps the service alive
     * to handle it, instead of being torn down under it.
     */
    private fun stopWithoutRestart(startId: Int): Int {
        stopMonitoringLoop()
        isRunning = false
        stopSelf(startId)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopMonitoringLoop()
        hideOverlayIfNeeded()
        isRunning = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startMonitoringLoop() {
        handler.removeCallbacks(monitorRunnable)
        handler.post(monitorRunnable)
    }

    private fun stopMonitoringLoop() {
        handler.removeCallbacks(monitorRunnable)
    }

    private fun showOverlay(blockedPackage: String) {
        if (!Settings.canDrawOverlays(this)) {
            // If overlay permission is missing/revoked, best-effort fallback.
            forceHomeScreen()
            return
        }

        if (overlayVisible && currentBlockedPackage == blockedPackage) {
            return
        }

        overlayPinned = true

        lockStartedAtMs = if (currentBlockedPackage == blockedPackage && lockStartedAtMs > 0L) {
            lockStartedAtMs
        } else {
            System.currentTimeMillis()
        }
        val selectedQuote = pickNextQuote()
        overlayMessage = selectedQuote.first
        overlayReferenceText = selectedQuote.second

        val wm = windowManager ?: getSystemService(Context.WINDOW_SERVICE) as WindowManager
        windowManager = wm

        hideOverlayIfNeeded()
        currentBlockedPackage = blockedPackage

        val palette = if (overlayIsDark) {
            OverlayPalette(
                rootTop = "#F20B1320",
                rootBottom = "#E0121C2A",
                cardTop = "#FF121C2A",
                cardBottom = "#FF0B1320",
                border = "#335D7BFF",
                heading = "#FFAFC3FF",
                title = "#FFFFFFFF",
                body = "#FFE4EEFF",
                reference = "#FF9CB0CF",
                accent = "#FF2A3B58",
                primaryStart = "#FF4B6BFF",
                primaryEnd = "#FF6A90FF",
                primaryText = "#FFFFFFFF",
                secondaryText = "#FFCBD8FF",
                secondaryFill = "#192A3B55",
                secondaryBorder = "#334B6BFF",
            )
        } else {
            OverlayPalette(
                rootTop = "#F7F4EEE8",
                rootBottom = "#F2EFE6DD",
                cardTop = "#FFFDFBF8",
                cardBottom = "#FFF4EFE9",
                border = "#33B0916B",
                heading = "#FF8B5E2E",
                title = "#FF2B1C12",
                body = "#FF4B3427",
                reference = "#FF7E5B45",
                accent = "#FFDFCBB6",
                primaryStart = "#FFB5834E",
                primaryEnd = "#FFD2A76B",
                primaryText = "#FF2B1C12",
                secondaryText = "#FF4B3427",
                secondaryFill = "#1FC7B099",
                secondaryBorder = "#33A77B58",
            )
        }

        val rootGradient = GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            intArrayOf(
                Color.parseColor(palette.rootTop),
                Color.parseColor(palette.rootBottom),
            ),
        )

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            background = rootGradient
            setPadding(22, 24, 22, 24)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.MATCH_PARENT,
            )
        }

        val cardGradient = GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            intArrayOf(
                Color.parseColor(palette.cardTop),
                Color.parseColor(palette.cardBottom),
            ),
        ).apply {
            cornerRadius = 36f
            setStroke(2, Color.parseColor(palette.border))
        }

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(26, 28, 26, 24)
            background = cardGradient
            elevation = 18f
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply {
                marginStart = 8
                marginEnd = 8
            }
        }

        // Note: Previously a RenderEffect blur was applied to the card on Android S+.
        // That blurred the card and its child views (making text unreadable). To
        // keep overlay content sharp and readable, the blur is removed.

        val scroll = ScrollView(this).apply {
            isFillViewport = true
            overScrollMode = View.OVER_SCROLL_NEVER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1f,
            )
        }

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }

        val logo = ImageView(this).apply {
            setImageResource(R.mipmap.launcher_icon)
            layoutParams = LinearLayout.LayoutParams(120, 120).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = 10
            }
        }

        val headingChip = TextView(this).apply {
            text = "WADHAKIR"
            textSize = 11f
            setTextColor(Color.parseColor(palette.heading))
            setTypeface(typeface, Typeface.BOLD)
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(0, 0, 0, 8)
            letterSpacing = 0.10f
        }

        val title = TextView(this).apply {
            text = overlayTitleText
            textSize = 26f
            setTextColor(Color.parseColor(palette.title))
            gravity = Gravity.CENTER
            setTypeface(typeface, Typeface.BOLD)
        }

        val subtitle = TextView(this).apply {
            text = "Focus. Salah time."
            textSize = 13f
            setTextColor(Color.parseColor(palette.reference))
            gravity = Gravity.CENTER
            setPadding(0, 6, 0, 0)
        }

        val prayerChip = TextView(this).apply {
            text = overlayPrayerName
            textSize = 12f
            setTextColor(Color.parseColor(palette.secondaryText))
            setTypeface(typeface, Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(18, 8, 18, 8)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 20f
                setColor(Color.parseColor(palette.secondaryFill))
                setStroke(2, Color.parseColor(palette.secondaryBorder))
            }
        }

        val iconRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(0, 12, 0, 4)
        }

        fun iconBubble(iconRes: Int): View {
            return ImageView(this).apply {
                setImageResource(iconRes)
                layoutParams = LinearLayout.LayoutParams(44, 44).apply {
                    marginStart = 8
                    marginEnd = 8
                }
                setPadding(10, 10, 10, 10)
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.parseColor(palette.secondaryFill))
                    setStroke(2, Color.parseColor(palette.secondaryBorder))
                }
                setColorFilter(Color.parseColor(palette.secondaryText))
            }
        }

        iconRow.addView(iconBubble(android.R.drawable.ic_lock_lock))
        iconRow.addView(iconBubble(android.R.drawable.ic_menu_recent_history))
        iconRow.addView(iconBubble(android.R.drawable.ic_menu_compass))

        val accentLine = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                2,
            ).apply {
                topMargin = 14
                bottomMargin = 16
            }
            setBackgroundColor(Color.parseColor(palette.accent))
        }

        val body = TextView(this).apply {
            text = overlayMessage
            textSize = 19f
            setTextColor(Color.parseColor(palette.body))
            gravity = Gravity.CENTER
            setPadding(0, 16, 0, 16)
            setLineSpacing(8f, 1.15f)
        }

        val reference = TextView(this).apply {
            text = overlayReferenceText
            textSize = 13f
            setTextColor(Color.parseColor(palette.reference))
            gravity = Gravity.CENTER
            visibility = if (overlayReferenceText.isBlank()) View.GONE else View.VISIBLE
            setPadding(0, 0, 0, 16)
        }

        val action = Button(this).apply {
            text = goHomeButtonText
            textSize = 17f
            isAllCaps = false
            setTextColor(Color.parseColor(palette.primaryText))
            background = GradientDrawable(
                GradientDrawable.Orientation.LEFT_RIGHT,
                intArrayOf(
                    Color.parseColor(palette.primaryStart),
                    Color.parseColor(palette.primaryEnd),
                ),
            ).apply { cornerRadius = 20f }
            setPadding(26, 18, 26, 18)
            setOnClickListener {
                hideOverlayIfNeeded()
                forceHomeScreen()
            }
        }

        val completionAction = Button(this).apply {
            text = completedPrayerButtonText
            textSize = 16f
            isAllCaps = false
            setTextColor(Color.parseColor(palette.secondaryText))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 18f
                setColor(Color.parseColor(palette.secondaryFill))
                setStroke(2, Color.parseColor(palette.secondaryBorder))
            }
            setPadding(20, 14, 20, 14)
            setOnClickListener {
                temporarilyAllowedPackage = currentBlockedPackage
                val now = System.currentTimeMillis()
                prayerCompletedUntilMs = if (nextPrayerStartMs > now) nextPrayerStartMs else 0L
                prefs(this@AppLockMonitorService).edit()
                    .putLong(KEY_PRAYER_COMPLETED_UNTIL, prayerCompletedUntilMs)
                    .apply()
                hideOverlayIfNeeded()
            }
        }

        val bypassHoldAction = Button(this).apply {
            text = holdBypassText
            textSize = 16f
            visibility = if (emergencyBypassEnabled) View.VISIBLE else View.GONE
            setPadding(20, 12, 20, 12)
            setOnTouchListener { _, event ->
                if (!emergencyBypassEnabled) {
                    return@setOnTouchListener false
                }

                when (event.actionMasked) {
                    MotionEvent.ACTION_DOWN -> {
                        startBypassHold()
                    }

                    MotionEvent.ACTION_UP,
                    MotionEvent.ACTION_CANCEL -> {
                        if (!bypassReadyForConfirmation) {
                            cancelBypassHold(resetHint = true)
                        }
                    }
                }
                true
            }
        }

        val bypassHint = TextView(this).apply {
            text = ""
            textSize = 14f
            setTextColor(Color.parseColor(palette.body))
            gravity = Gravity.CENTER
            visibility = View.GONE
        }

        val bypassConfirm = Button(this).apply {
            text = confirmBypassText
            textSize = 16f
            visibility = View.GONE
            isAllCaps = false
            setPadding(18, 12, 18, 12)
            setOnClickListener {
                val now = System.currentTimeMillis()
                if (now - lastBypassTriggeredAtMs < BYPASS_DEBOUNCE_MS) {
                    return@setOnClickListener
                }

                lastBypassTriggeredAtMs = now
                globallyBypassedUntilMs = now + BYPASS_GRACE_SECONDS * 1_000L
                temporarilyAllowedPackage = null
                hideOverlayIfNeeded()
            }
        }

        val bypassCancel = Button(this).apply {
            text = cancelText
            textSize = 15f
            visibility = View.GONE
            isAllCaps = false
            setPadding(18, 12, 18, 12)
            setOnClickListener {
                cancelBypassHold(resetHint = true)
            }
        }

        bypassConfirmButton = bypassConfirm
        bypassCancelButton = bypassCancel
        bypassHintText = bypassHint

        content.addView(headingChip)
        content.addView(logo)
        content.addView(title)
        content.addView(subtitle)
        content.addView(prayerChip)
        content.addView(iconRow)
        content.addView(accentLine)
        content.addView(body)
        content.addView(reference)
        content.addView(action)
        content.addView(completionAction)
        content.addView(bypassHoldAction)
        content.addView(bypassHint)
        content.addView(bypassConfirm)
        content.addView(bypassCancel)

        scroll.addView(content)
        card.addView(scroll)
        root.addView(card)

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            android.graphics.PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.CENTER
        }

        try {
            wm.addView(root, params)
            overlayView = root
            overlayVisible = true
        } catch (_: Exception) {
            overlayView = null
            overlayVisible = false
            forceHomeScreen()
        }
    }

    private fun hideOverlayIfNeeded() {
        val wm = windowManager ?: return
        val view = overlayView ?: return

        cancelBypassHold(resetHint = false)

        try {
            wm.removeView(view)
        } catch (_: Exception) {
            // View might already be detached.
        } finally {
            overlayView = null
            overlayVisible = false
            currentBlockedPackage = null
            overlayPinned = false
            bypassConfirmButton = null
            bypassCancelButton = null
            bypassHintText = null
        }
    }

    private fun startBypassHold() {
        if (bypassReadyForConfirmation) return

        cancelBypassHold(resetHint = false)
        bypassHintText?.apply {
            text = keepHoldingText
            visibility = View.VISIBLE
        }

        val runnable = Runnable {
            bypassReadyForConfirmation = true
            bypassHintText?.text = holdReadyText
            bypassConfirmButton?.visibility = View.VISIBLE
            bypassCancelButton?.visibility = View.VISIBLE
        }
        bypassHoldRunnable = runnable
        handler.postDelayed(runnable, BYPASS_HOLD_MS)
    }

    private fun cancelBypassHold(resetHint: Boolean) {
        bypassHoldRunnable?.let { handler.removeCallbacks(it) }
        bypassHoldRunnable = null
        bypassReadyForConfirmation = false
        bypassConfirmButton?.visibility = View.GONE
        bypassCancelButton?.visibility = View.GONE
        if (resetHint) {
            bypassHintText?.apply {
                text = ""
                visibility = View.GONE
            }
        }
    }

    private fun applyOverlayTextConfig(intent: Intent) {
        overlayTitleText = intent.getStringExtra(EXTRA_OVERLAY_TITLE_TEXT) ?: overlayTitleText
        overlayReferenceText = intent.getStringExtra(EXTRA_OVERLAY_REFERENCE_TEXT) ?: overlayReferenceText
        overlayPrayerName = intent.getStringExtra(EXTRA_OVERLAY_PRAYER_NAME) ?: overlayPrayerName
        goHomeButtonText = intent.getStringExtra(EXTRA_GO_HOME_BUTTON_TEXT) ?: goHomeButtonText
        completedPrayerButtonText =
            intent.getStringExtra(EXTRA_COMPLETED_PRAYER_BUTTON_TEXT) ?: completedPrayerButtonText
        holdBypassText = intent.getStringExtra(EXTRA_HOLD_BYPASS_TEXT) ?: holdBypassText
        keepHoldingText = intent.getStringExtra(EXTRA_KEEP_HOLDING_TEXT) ?: keepHoldingText
        holdReadyText = intent.getStringExtra(EXTRA_HOLD_READY_TEXT) ?: holdReadyText
        confirmBypassText = intent.getStringExtra(EXTRA_CONFIRM_BYPASS_TEXT) ?: confirmBypassText
        cancelText = intent.getStringExtra(EXTRA_CANCEL_TEXT) ?: cancelText
    }

    private fun applyOverlayTheme(intent: Intent) {
        overlayIsDark = intent.getBooleanExtra(EXTRA_OVERLAY_IS_DARK, overlayIsDark)
    }

    private fun applyPrayerWindowConfig(intent: Intent) {
        prayerWindowStartMs = intent.getLongExtra(EXTRA_PRAYER_WINDOW_START_MS, prayerWindowStartMs)
        nextPrayerStartMs = intent.getLongExtra(EXTRA_NEXT_PRAYER_START_MS, nextPrayerStartMs)
    }

    private fun isPrayerWindowActive(now: Long): Boolean {
        if (prayerWindowStartMs <= 0L || nextPrayerStartMs <= 0L) return false
        return now in prayerWindowStartMs until nextPrayerStartMs
    }

    private fun applyOverlayQuotes(intent: Intent) {
        val messages = intent.getStringArrayListExtra(EXTRA_OVERLAY_MESSAGES)
        val references = intent.getStringArrayListExtra(EXTRA_OVERLAY_REFERENCES)

        if (messages.isNullOrEmpty()) return

        overlayMessages.clear()
        overlayMessages.addAll(messages.map { it.trim() }.filter { it.isNotEmpty() })

        overlayReferences.clear()
        if (!references.isNullOrEmpty()) {
            overlayReferences.addAll(references.map { it.trim() })
        }

        while (overlayReferences.size < overlayMessages.size) {
            overlayReferences.add("")
        }

        quoteCursor = -1
    }

    private fun pickNextQuote(): Pair<String, String> {
        if (overlayMessages.isEmpty()) {
            return Pair(overlayMessage, overlayReferenceText)
        }

        if (overlayMessages.size == 1) {
            val ref = overlayReferences.firstOrNull().orEmpty()
            return Pair(overlayMessages.first(), ref)
        }

        var nextIndex = (overlayMessages.indices).random()
        if (nextIndex == quoteCursor) {
            nextIndex = (nextIndex + 1) % overlayMessages.size
        }
        quoteCursor = nextIndex

        val message = overlayMessages[nextIndex]
        val reference = overlayReferences.getOrNull(nextIndex).orEmpty()
        return Pair(message, reference)
    }

    private fun shouldSkipBlockingPackage(packageNameToCheck: String): Boolean {
        if (packageNameToCheck.isBlank()) return true
        if (packageNameToCheck == packageName) return true
        if (blockedPackageExact.contains(packageNameToCheck)) return true
        return blockedPackagePrefixes.any { packageNameToCheck.startsWith(it) }
    }

    private fun forceHomeScreen() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        try {
            startActivity(homeIntent)
        } catch (_: Exception) {
            // Ignore; service will continue monitoring and retry on next tick.
        }
    }

    private fun getForegroundPackageName(): String? {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 12_000

        val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()
        var packageName: String? = null

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            if (
                event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                event.eventType == UsageEvents.Event.ACTIVITY_RESUMED
            ) {
                packageName = event.packageName
                lastForegroundTimestampMs = event.timeStamp
            }
        }

        if (!packageName.isNullOrBlank()) {
            lastForegroundPackage = packageName
            return packageName
        }

        val now = System.currentTimeMillis()
        if (lastForegroundPackage != null && now - lastForegroundTimestampMs <= FOREGROUND_GRACE_MS) {
            return lastForegroundPackage
        }

        return null
    }

    private fun hasUsageAccessPermission(): Boolean {
        val appOps = getSystemService(APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName,
            )
        } else {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName,
            )
        }

        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "App Lock Monitor",
            NotificationManager.IMPORTANCE_LOW,
        )
        channel.description = "Monitors selected apps and shows lock screen"
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val stopIntent = Intent(this, AppLockMonitorService::class.java).apply {
            action = ACTION_STOP
            putExtra(EXTRA_FROM_NOTIFICATION, true)
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle("Wadhakir App Lock")
            .setContentText("App lock protection is active")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .addAction(R.mipmap.launcher_icon, "Turn Off", stopPendingIntent)
            .build()
    }
}
