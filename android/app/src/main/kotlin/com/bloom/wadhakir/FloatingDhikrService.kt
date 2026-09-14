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

        private const val CHANNEL_ID = "floating_dhikr_channel"
        private const val NOTIFICATION_ID = 9011
        private const val PREFS = "floating_dhikr_native"

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
            p.apply()
        }

        fun clearEnabled(context: Context) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putBoolean("enabled", false).apply()
        }

        fun isEnabled(context: Context): Boolean =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean("enabled", false)
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

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                clearEnabled(this)
                stopLoop()
                hidePill()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_EMIT_NOW -> {
                if (intent.hasExtra(EXTRA_DHIKR)) applyConfig(intent)
                startInForeground()
                emitOnce()
            }
            else -> {
                // START or UPDATE
                if (intent != null && intent.hasExtra(EXTRA_DHIKR)) {
                    applyConfig(intent)
                    saveConfig(this, intent)
                } else {
                    loadConfigFromPrefs()
                }
                startInForeground()
                startLoop()
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        stopLoop()
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

    private fun emitOnce() {
        if (!Settings.canDrawOverlays(this)) return
        if (dhikr.isEmpty()) return
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

        try {
            wm.addView(card, params)
            pillView = card
            handler.postDelayed({ hidePill() }, dismissSeconds.coerceAtLeast(2) * 1000L)
        } catch (_: Exception) {
            pillView = null
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

    private fun startInForeground() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                buildNotification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, buildNotification())
        }
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
