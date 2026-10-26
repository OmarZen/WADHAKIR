package com.bloom.wadhakir

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.util.Calendar
import kotlin.random.Random

/**
 * Native foreground service that shows the floating dhikr "pill" over other
 * apps on a timer. Unlike the previous in-process Dart timer, this survives
 * the app being backgrounded or killed, and is restarted on boot by
 * [BootReceiver]. Mirrors the overlay/notification patterns of
 * [AppLockMonitorService].
 */
class FloatingDhikrService : Service() {
    companion object {
        const val ACTION_START = "com.bloom.wadhakir.FLOATING_DHIKR_START"
        const val ACTION_STOP = "com.bloom.wadhakir.FLOATING_DHIKR_STOP"
        const val ACTION_UPDATE = "com.bloom.wadhakir.FLOATING_DHIKR_UPDATE"
        const val ACTION_EMIT_NOW = "com.bloom.wadhakir.FLOATING_DHIKR_EMIT"

        const val EXTRA_DHIKR = "dhikr_list"
        const val EXTRA_INTERVAL_MIN = "interval_minutes"
        const val EXTRA_DISMISS_SEC = "dismiss_seconds"
        const val EXTRA_ANCHOR = "anchor"
        const val EXTRA_OPACITY = "opacity"
        const val EXTRA_IS_DARK = "is_dark"
        const val EXTRA_QUIET_START = "quiet_start_min"
        const val EXTRA_QUIET_END = "quiet_end_min"

        /** Set on the notification's «إيقاف» only; see [hasUserStop]. */
        const val EXTRA_FROM_NOTIFICATION = "from_notification"

        private const val CHANNEL_ID = "floating_dhikr_channel"
        private const val NOTIFICATION_ID = 9011
        private const val PREFS = "floating_dhikr_native"
        private const val KEY_USER_STOP = "stoppedByUser"

        /** Persist config so the boot receiver can restart the service. */
        fun saveConfig(context: Context, intent: Intent) {
            val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            p.putBoolean("enabled", true)
            p.putStringSet(
                "dhikr",
                intent.getStringArrayListExtra(EXTRA_DHIKR)?.toSet() ?: emptySet(),
            )
            p.putInt("interval", intent.getIntExtra(EXTRA_INTERVAL_MIN, 30))
            p.putInt("dismiss", intent.getIntExtra(EXTRA_DISMISS_SEC, 8))
            p.putString("anchor", intent.getStringExtra(EXTRA_ANCHOR) ?: "bottomBar")
            p.putFloat("opacity", intent.getDoubleExtra(EXTRA_OPACITY, 0.95).toFloat())
            p.putBoolean("dark", intent.getBooleanExtra(EXTRA_IS_DARK, false))
            p.putInt("quietStart", intent.getIntExtra(EXTRA_QUIET_START, -1))
            p.putInt("quietEnd", intent.getIntExtra(EXTRA_QUIET_END, -1))
            // Turned on again: an earlier «إيقاف» no longer speaks for the user.
            p.remove(KEY_USER_STOP)
            p.apply()
        }

        fun clearEnabled(context: Context) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putBoolean("enabled", false).apply()
        }

        fun isEnabled(context: Context): Boolean =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean("enabled", false)

        /**
         * True once the user has pressed «إيقاف» on the notification, until the
         * Dart side acknowledges it.
         *
         * «إيقاف» means "turn the feature off", but the switch lives in Dart's
         * `floating_dhikr_settings_v1`, which native code must not write
         * (lost-write races; see [PrayerAlarmStore]). Clearing only the native
         * flag left Dart's "enabled", so the next app start turned the pill
         * back on. Dart reads this marker, saves "off" itself, then calls
         * [clearUserStop]: two steps, so a reader that dies in between leaves
         * the marker for the next one.
         */
        fun hasUserStop(context: Context): Boolean =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_USER_STOP, false)

        fun clearUserStop(context: Context) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().remove(KEY_USER_STOP).apply()
        }

        private fun markUserStop(context: Context) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putBoolean(KEY_USER_STOP, true).apply()
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var pillView: View? = null

    private var dhikr: List<String> = emptyList()
    private var intervalMinutes: Int = 30
    private var dismissSeconds: Int = 8
    private var anchor: String = "bottomBar"
    private var opacity: Float = 0.95f
    private var isDark: Boolean = false
    private var quietStart: Int = -1
    private var quietEnd: Int = -1

    private val emitRunnable = object : Runnable {
        override fun run() {
            if (!isInQuietHours()) emitOnce()
            handler.postDelayed(this, intervalMinutes.coerceAtLeast(1) * 60_000L)
        }
    }

    /**
     * Named so it can be cancelled. As an anonymous lambda, a second pill
     * shown within [dismissSeconds] was hidden early by the first one's timer,
     * and the timer could still run after [onDestroy].
     */
    private val hideRunnable = Runnable { hidePill() }

    /** The start id of a preview made with the feature off; see [previewStopRunnable]. */
    private var previewStartId = 0

    /**
     * Ends a preview that ran with the feature off, once its pill is gone.
     * Re-checks first: if the user turned the feature on meanwhile, their
     * START has taken this service over and it must keep running.
     */
    private val previewStopRunnable = Runnable {
        if (isEnabled(this)) return@Runnable
        hidePill()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf(previewStartId)
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Whatever arrives next decides this service's fate itself.
        handler.removeCallbacks(previewStopRunnable)
        when (intent?.action) {
            ACTION_STOP -> {
                clearEnabled(this)
                if (ServiceStartRules.stopIsUserTurnOff(
                        intent.getBooleanExtra(EXTRA_FROM_NOTIFICATION, false),
                    )
                ) {
                    markUserStop(this)
                }
                stopLoop()
                hidePill()
                stopForeground(STOP_FOREGROUND_REMOVE)
                // A quick off-then-on leaves the new START queued behind this.
                stopSelf(startId)
                return START_NOT_STICKY
            }
            ACTION_EMIT_NOW -> {
                if (intent.hasExtra(EXTRA_DHIKR)) applyConfig(intent)
                // First, before any early stop: this was started with
                // startForegroundService, and stopping without ever calling
                // startForeground is itself a crash.
                if (!startInForeground()) return stopWithoutRestart(startId)
                val pillShown = emitOnce()
                when (ServiceStartRules.afterPreview(isEnabled(this), pillShown)) {
                    ServiceStartRules.PreviewEnd.KEEP_RUNNING -> Unit
                    ServiceStartRules.PreviewEnd.STOP_NOW -> {
                        stopForeground(STOP_FOREGROUND_REMOVE)
                        return stopWithoutRestart(startId)
                    }
                    ServiceStartRules.PreviewEnd.STOP_AFTER_PILL -> {
                        // "معاينة الآن" with the feature off used to stay
                        // foreground, its "active" notification up until the
                        // process died.
                        previewStartId = startId
                        handler.postDelayed(previewStopRunnable, dismissMillis() + 300L)
                        return START_NOT_STICKY
                    }
                }
            }
            else -> {
                // START or UPDATE, or a sticky restart (null intent)
                if (intent != null && intent.hasExtra(EXTRA_DHIKR)) {
                    applyConfig(intent)
                    saveConfig(this, intent)
                } else {
                    // "Preview now" starts this service with the feature off;
                    // its sticky restart must not bring the loop back.
                    if (!isEnabled(this)) return stopWithoutRestart(startId)
                    loadConfigFromPrefs()
                }
                if (!startInForeground()) return stopWithoutRestart(startId)
                startLoop()
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        // The loop, the pill's auto-hide and a pending preview stop alike.
        handler.removeCallbacksAndMessages(null)
        hidePill()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // --------------------------------------------------------------- config

    private fun applyConfig(intent: Intent) {
        dhikr = intent.getStringArrayListExtra(EXTRA_DHIKR) ?: dhikr
        intervalMinutes = intent.getIntExtra(EXTRA_INTERVAL_MIN, intervalMinutes)
        dismissSeconds = intent.getIntExtra(EXTRA_DISMISS_SEC, dismissSeconds)
        anchor = intent.getStringExtra(EXTRA_ANCHOR) ?: anchor
        opacity = intent.getDoubleExtra(EXTRA_OPACITY, opacity.toDouble()).toFloat()
        isDark = intent.getBooleanExtra(EXTRA_IS_DARK, isDark)
        quietStart = intent.getIntExtra(EXTRA_QUIET_START, quietStart)
        quietEnd = intent.getIntExtra(EXTRA_QUIET_END, quietEnd)
    }

    private fun loadConfigFromPrefs() {
        val p = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        dhikr = p.getStringSet("dhikr", emptySet())?.toList() ?: emptyList()
        intervalMinutes = p.getInt("interval", 30)
        dismissSeconds = p.getInt("dismiss", 8)
        anchor = p.getString("anchor", "bottomBar") ?: "bottomBar"
        opacity = p.getFloat("opacity", 0.95f)
        isDark = p.getBoolean("dark", false)
        quietStart = p.getInt("quietStart", -1)
        quietEnd = p.getInt("quietEnd", -1)
    }

    private fun isInQuietHours(): Boolean {
        if (quietStart < 0 || quietEnd < 0 || quietStart == quietEnd) return false
        val now = Calendar.getInstance()
        val mins = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        return if (quietStart < quietEnd) {
            mins in quietStart until quietEnd
        } else {
            // Overnight window (e.g. 22:00 → 06:00).
            mins >= quietStart || mins < quietEnd
        }
    }

    // ----------------------------------------------------------------- loop

    private fun startLoop() {
        handler.removeCallbacks(emitRunnable)
        // First emission after one interval (don't pop instantly on every
        // config change); the "test now" path uses ACTION_EMIT_NOW instead.
        handler.postDelayed(emitRunnable, intervalMinutes.coerceAtLeast(1) * 60_000L)
    }

    private fun stopLoop() = handler.removeCallbacks(emitRunnable)

    // -------------------------------------------------------------- overlay

    private fun dismissMillis(): Long = dismissSeconds.coerceAtLeast(2) * 1000L

    /** Shows one pill. Returns whether one actually went up. */
    private fun emitOnce(): Boolean {
        if (!Settings.canDrawOverlays(this)) return false
        if (dhikr.isEmpty()) return false
        hidePill()

        val text = dhikr[Random.nextInt(dhikr.size)]
        val wm = windowManager ?: (getSystemService(Context.WINDOW_SERVICE) as WindowManager)
        windowManager = wm

        val bgTop = if (isDark) "#FF121C2A" else "#FF20497D"
        val bgBottom = if (isDark) "#FF0B1320" else "#FF3A6BA8"

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(40, 26, 40, 26)
            alpha = opacity.coerceIn(0.3f, 1.0f)
            background = GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(Color.parseColor(bgTop), Color.parseColor(bgBottom)),
            ).apply {
                cornerRadius = 999f
                setStroke(2, Color.parseColor("#33FFFFFF"))
            }
            setOnClickListener { hidePill() }
        }
        val label = TextView(this).apply {
            this.text = text
            setTextColor(Color.WHITE)
            textSize = 16f
            maxLines = 2
            ellipsize = android.text.TextUtils.TruncateAt.END
            gravity = Gravity.CENTER
            typeface = Typeface.DEFAULT_BOLD
            textDirection = View.TEXT_DIRECTION_RTL
        }
        card.addView(label)

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = gravityFor(anchor)
            x = 24
            y = if (anchor.startsWith("top")) 90 else 120
        }

        return try {
            wm.addView(card, params)
            pillView = card
            handler.removeCallbacks(hideRunnable)
            handler.postDelayed(hideRunnable, dismissMillis())
            true
        } catch (_: Exception) {
            pillView = null
            false
        }
    }

    private fun gravityFor(a: String): Int = when (a) {
        "topBar" -> Gravity.TOP or Gravity.CENTER_HORIZONTAL
        "topLeft" -> Gravity.TOP or Gravity.START
        "topRight" -> Gravity.TOP or Gravity.END
        "bottomLeft" -> Gravity.BOTTOM or Gravity.START
        "bottomRight" -> Gravity.BOTTOM or Gravity.END
        else -> Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
    }

    private fun hidePill() {
        handler.removeCallbacks(hideRunnable)
        val wm = windowManager ?: return
        val view = pillView ?: return
        try {
            wm.removeView(view)
        } catch (_: Exception) {
        } finally {
            pillView = null
        }
    }

    // ----------------------------------------------------------- foreground

    /**
     * Goes foreground, or returns false when the platform refuses.
     *
     * Android 12+ refuses `startForeground` from the background with
     * `ForegroundServiceStartNotAllowedException`, which Play reported on 3.4.3.
     * The likely path is the system restarting this START_STICKY service after
     * killing the process: the intent is null, no activity is visible, and from
     * Android 15 holding SYSTEM_ALERT_WINDOW only exempts an app that has an
     * overlay on screen. Uncaught, the refusal crashed the process. "enabled"
     * is left set, so the pill comes back when the app next starts (main()
     * runs the Dart side's bootstrap) or on the next boot.
     */
    private fun startInForeground(): Boolean = try {
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
        Log.w("FloatingDhikrService", "Could not go foreground", e)
        false
    }

    /**
     * Stops without asking to be restarted. `stopSelf(startId)` rather than
     * `stopSelf()`: a start the app queued meanwhile (startForegroundService on
     * app open) keeps the service alive to call startForeground, instead of
     * being torn down under it, which the platform punishes with a crash.
     */
    private fun stopWithoutRestart(startId: Int): Int {
        stopLoop()
        hidePill()
        stopSelf(startId)
        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "تذكير الأذكار العائم",
            NotificationManager.IMPORTANCE_LOW,
        ).apply { description = "يُبقي تذكير الأذكار العائم نشطاً" }
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
        val stopIntent = Intent(this, FloatingDhikrService::class.java).apply {
            action = ACTION_STOP
            putExtra(EXTRA_FROM_NOTIFICATION, true)
        }
        val stopPending = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle("وَذكِّر")
            .setContentText("تذكير الأذكار العائم نشط")
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pendingIntent)
            .addAction(0, "إيقاف", stopPending)
            .build()
    }
}
