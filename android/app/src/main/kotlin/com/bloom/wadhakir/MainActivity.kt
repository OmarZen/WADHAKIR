package com.bloom.wadhakir

import android.app.AppOpsManager
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : AudioServiceActivity() {
    private val widgetChannel = "com.bloom.wadhakir/widget_navigation"
    private val appLockChannel = "com.bloom.wadhakir/app_lock"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge display for Android 15 (API 35) compatibility
        // This prevents UI elements from being hidden behind system bars
        if (Build.VERSION.SDK_INT >= 35) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
        
        super.onCreate(savedInstanceState)
        
        // Handle widget navigation intents
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannel).setMethodCallHandler { call, result ->
            // Method channel for Flutter to receive navigation commands
            result.success(null)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appLockChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> result.success(getInstalledApps())
                "getAppIcon" -> {
                    val packageNameArg = call.argument<String>("packageName")
                    if (packageNameArg.isNullOrBlank()) {
                        result.success(null)
                    } else {
                        result.success(getAppIcon(packageNameArg))
                    }
                }
                "getPermissionStatus" -> result.success(getPermissionStatus())
                "openUsageAccessSettings" -> {
                    openUsageAccessSettings()
                    result.success(null)
                }
                "openOverlaySettings" -> {
                    openOverlaySettings()
                    result.success(null)
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(null)
                }
                "openAppDetailsSettings" -> {
                    openAppDetailsSettings()
                    result.success(null)
                }
                "startLockMonitor" -> {
                    val lockedPackages = call.argument<List<String>>("lockedPackages") ?: emptyList()
                    val overlayMessage = call.argument<String>("overlayMessage")
                    val overlayTexts = call.argument<Map<String, String>>("overlayTexts") ?: emptyMap()
                    val overlayMessages = call.argument<List<String>>("overlayMessages") ?: emptyList()
                    val overlayReferences = call.argument<List<String>>("overlayReferences") ?: emptyList()
                    val lockDurationMinutes = call.argument<Int>("lockDurationMinutes")
                    val emergencyBypassEnabled = call.argument<Boolean>("emergencyBypassEnabled") ?: true
                    val overlayIsDark = call.argument<Boolean>("overlayIsDark") ?: false
                    val prayerWindowStartMs = call.argument<Long>("prayerWindowStartMs") ?: 0L
                    val nextPrayerStartMs = call.argument<Long>("nextPrayerStartMs") ?: 0L
                    startLockMonitor(
                        lockedPackages = lockedPackages,
                        overlayMessage = overlayMessage,
                        overlayTexts = overlayTexts,
                        overlayMessages = overlayMessages,
                        overlayReferences = overlayReferences,
                        lockDurationMinutes = lockDurationMinutes,
                        emergencyBypassEnabled = emergencyBypassEnabled,
                        overlayIsDark = overlayIsDark,
                        prayerWindowStartMs = prayerWindowStartMs,
                        nextPrayerStartMs = nextPrayerStartMs,
                    )
                    result.success(null)
                }
                "stopLockMonitor" -> {
                    stopLockMonitor()
                    result.success(null)
                }
                "updateLockedPackages" -> {
                    val lockedPackages = call.argument<List<String>>("lockedPackages") ?: emptyList()
                    updateLockedPackages(lockedPackages)
                    result.success(null)
                }
                "updateMonitorConfig" -> {
                    val lockedPackages = call.argument<List<String>>("lockedPackages") ?: emptyList()
                    val overlayTexts = call.argument<Map<String, String>>("overlayTexts") ?: emptyMap()
                    val overlayMessages = call.argument<List<String>>("overlayMessages") ?: emptyList()
                    val overlayReferences = call.argument<List<String>>("overlayReferences") ?: emptyList()
                    val lockDurationMinutes = call.argument<Int>("lockDurationMinutes")
                    val emergencyBypassEnabled = call.argument<Boolean>("emergencyBypassEnabled") ?: true
                    val overlayIsDark = call.argument<Boolean>("overlayIsDark") ?: false
                    val prayerWindowStartMs = call.argument<Long>("prayerWindowStartMs") ?: 0L
                    val nextPrayerStartMs = call.argument<Long>("nextPrayerStartMs") ?: 0L
                    updateMonitorConfig(
                        lockedPackages = lockedPackages,
                        overlayTexts = overlayTexts,
                        overlayMessages = overlayMessages,
                        overlayReferences = overlayReferences,
                        lockDurationMinutes = lockDurationMinutes,
                        emergencyBypassEnabled = emergencyBypassEnabled,
                        overlayIsDark = overlayIsDark,
                        prayerWindowStartMs = prayerWindowStartMs,
                        nextPrayerStartMs = nextPrayerStartMs,
                    )
                    result.success(null)
                }
                "updatePrayerWindow" -> {
                    val prayerWindowStartMs = call.argument<Long>("prayerWindowStartMs") ?: 0L
                    val nextPrayerStartMs = call.argument<Long>("nextPrayerStartMs") ?: 0L
                    updatePrayerWindow(
                        prayerWindowStartMs = prayerWindowStartMs,
                        nextPrayerStartMs = nextPrayerStartMs,
                    )
                    result.success(null)
                }
                // test overlay API removed in production
                "isLockMonitorRunning" -> {
                    result.success(AppLockMonitorService.isRunning)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun handleIntent(intent: Intent?) {
        when (intent?.action) {
            "HIJRI_PREVIOUS_MONTH" -> {
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, widgetChannel).invokeMethod("previousMonth", null)
                }
            }
            "HIJRI_NEXT_MONTH" -> {
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, widgetChannel).invokeMethod("nextMonth", null)
                }
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        val resolveInfos = packageManager.queryIntentActivities(launcherIntent, PackageManager.MATCH_ALL)

        val appsByPackage = linkedMapOf<String, Map<String, Any>>()

        resolveInfos.forEach { info ->
                val appInfo = info.activityInfo.applicationInfo
                val resolvedPackageName = info.activityInfo.packageName
                val appName = appInfo.loadLabel(packageManager)?.toString().orEmpty()
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val iconBytes = try {
                    drawableToPngBytes(info.loadIcon(packageManager))
                } catch (_: Exception) {
                    null
                }

                if (resolvedPackageName != packageName && !appsByPackage.containsKey(resolvedPackageName)) {
                    appsByPackage[resolvedPackageName] = mapOf(
                        "packageName" to resolvedPackageName,
                        "appName" to appName,
                        "isSystemApp" to isSystemApp,
                        "iconBytes" to (iconBytes ?: ByteArray(0)),
                    )
                }
        }

        return appsByPackage.values
            .sortedBy { app -> (app["appName"] as String).lowercase() }
    }

    private fun getPermissionStatus(): Map<String, Boolean> {
        return mapOf(
            "usageAccessGranted" to hasUsageAccessPermission(),
            "overlayGranted" to Settings.canDrawOverlays(this),
        )
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

    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    private fun openOverlaySettings() {
        try {
            val packageIntent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName"),
            )
            startActivity(packageIntent)
        } catch (_: Exception) {
            try {
                val genericIntent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                startActivity(genericIntent)
            } catch (_: Exception) {
                openAppDetailsSettings()
            }
        }
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }

    private fun openAppDetailsSettings() {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:$packageName"),
        )
        startActivity(intent)
    }

    private fun startLockMonitor(
        lockedPackages: List<String>,
        overlayMessage: String?,
        overlayTexts: Map<String, String>,
        overlayMessages: List<String>,
        overlayReferences: List<String>,
        lockDurationMinutes: Int?,
        emergencyBypassEnabled: Boolean,
        overlayIsDark: Boolean,
        prayerWindowStartMs: Long,
        nextPrayerStartMs: Long,
    ) {
        val serviceIntent = Intent(this, AppLockMonitorService::class.java).apply {
            action = AppLockMonitorService.ACTION_START
            putStringArrayListExtra(
                AppLockMonitorService.EXTRA_LOCKED_PACKAGES,
                ArrayList(lockedPackages),
            )
            putExtra(AppLockMonitorService.EXTRA_OVERLAY_MESSAGE, overlayMessage)
            putExtra(AppLockMonitorService.EXTRA_OVERLAY_TITLE_TEXT, overlayTexts["title"])
            putExtra(AppLockMonitorService.EXTRA_OVERLAY_REFERENCE_TEXT, overlayTexts["reference"])
            putExtra(AppLockMonitorService.EXTRA_OVERLAY_PRAYER_NAME, overlayTexts["prayerName"])
            putExtra(AppLockMonitorService.EXTRA_OVERLAY_IS_DARK, overlayIsDark)
            putExtra(AppLockMonitorService.EXTRA_PRAYER_WINDOW_START_MS, prayerWindowStartMs)
            putExtra(AppLockMonitorService.EXTRA_NEXT_PRAYER_START_MS, nextPrayerStartMs)
            putStringArrayListExtra(
                AppLockMonitorService.EXTRA_OVERLAY_MESSAGES,
                ArrayList(overlayMessages),
            )
            putStringArrayListExtra(
                AppLockMonitorService.EXTRA_OVERLAY_REFERENCES,
                ArrayList(overlayReferences),
            )
            putExtra(AppLockMonitorService.EXTRA_GO_HOME_BUTTON_TEXT, overlayTexts["goHome"])
            putExtra(AppLockMonitorService.EXTRA_COMPLETED_PRAYER_BUTTON_TEXT, overlayTexts["completedPrayer"])
            putExtra(AppLockMonitorService.EXTRA_HOLD_BYPASS_TEXT, overlayTexts["holdBypass"])
            putExtra(AppLockMonitorService.EXTRA_KEEP_HOLDING_TEXT, overlayTexts["keepHolding"])
            putExtra(AppLockMonitorService.EXTRA_HOLD_READY_TEXT, overlayTexts["holdReady"])
            putExtra(AppLockMonitorService.EXTRA_CONFIRM_BYPASS_TEXT, overlayTexts["confirmBypass"])
            putExtra(AppLockMonitorService.EXTRA_CANCEL_TEXT, overlayTexts["cancel"])
            putExtra(AppLockMonitorService.EXTRA_LOCK_DURATION_MINUTES, lockDurationMinutes)
            putExtra(
                AppLockMonitorService.EXTRA_EMERGENCY_BYPASS_ENABLED,
                emergencyBypassEnabled,
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun stopLockMonitor() {
        val serviceIntent = Intent(this, AppLockMonitorService::class.java).apply {
            action = AppLockMonitorService.ACTION_STOP
        }
        startService(serviceIntent)
    }

    private fun updateLockedPackages(lockedPackages: List<String>) {
        val serviceIntent = Intent(this, AppLockMonitorService::class.java).apply {
            action = AppLockMonitorService.ACTION_UPDATE_PACKAGES
            putStringArrayListExtra(
                AppLockMonitorService.EXTRA_LOCKED_PACKAGES,
                ArrayList(lockedPackages),
            )
        }
        startService(serviceIntent)
    }

    private fun updateMonitorConfig(
        lockedPackages: List<String>,
        overlayTexts: Map<String, String>,
        overlayMessages: List<String>,
        overlayReferences: List<String>,
        lockDurationMinutes: Int?,
        emergencyBypassEnabled: Boolean,
        overlayIsDark: Boolean,
        prayerWindowStartMs: Long,
        nextPrayerStartMs: Long,
    ) {
        val serviceIntent = Intent(this, AppLockMonitorService::class.java).apply {
            action = AppLockMonitorService.ACTION_UPDATE_CONFIG
            putStringArrayListExtra(
                AppLockMonitorService.EXTRA_LOCKED_PACKAGES,
                ArrayList(lockedPackages),
            )
            putExtra(AppLockMonitorService.EXTRA_OVERLAY_TITLE_TEXT, overlayTexts["title"])
            putExtra(AppLockMonitorService.EXTRA_OVERLAY_REFERENCE_TEXT, overlayTexts["reference"])
            putExtra(AppLockMonitorService.EXTRA_OVERLAY_PRAYER_NAME, overlayTexts["prayerName"])
            putExtra(AppLockMonitorService.EXTRA_OVERLAY_IS_DARK, overlayIsDark)
            putExtra(AppLockMonitorService.EXTRA_PRAYER_WINDOW_START_MS, prayerWindowStartMs)
            putExtra(AppLockMonitorService.EXTRA_NEXT_PRAYER_START_MS, nextPrayerStartMs)
            putStringArrayListExtra(
                AppLockMonitorService.EXTRA_OVERLAY_MESSAGES,
                ArrayList(overlayMessages),
            )
            putStringArrayListExtra(
                AppLockMonitorService.EXTRA_OVERLAY_REFERENCES,
                ArrayList(overlayReferences),
            )
            putExtra(AppLockMonitorService.EXTRA_GO_HOME_BUTTON_TEXT, overlayTexts["goHome"])
            putExtra(AppLockMonitorService.EXTRA_COMPLETED_PRAYER_BUTTON_TEXT, overlayTexts["completedPrayer"])
            putExtra(AppLockMonitorService.EXTRA_HOLD_BYPASS_TEXT, overlayTexts["holdBypass"])
            putExtra(AppLockMonitorService.EXTRA_KEEP_HOLDING_TEXT, overlayTexts["keepHolding"])
            putExtra(AppLockMonitorService.EXTRA_HOLD_READY_TEXT, overlayTexts["holdReady"])
            putExtra(AppLockMonitorService.EXTRA_CONFIRM_BYPASS_TEXT, overlayTexts["confirmBypass"])
            putExtra(AppLockMonitorService.EXTRA_CANCEL_TEXT, overlayTexts["cancel"])
            putExtra(AppLockMonitorService.EXTRA_LOCK_DURATION_MINUTES, lockDurationMinutes)
            putExtra(
                AppLockMonitorService.EXTRA_EMERGENCY_BYPASS_ENABLED,
                emergencyBypassEnabled,
            )
        }
        startService(serviceIntent)
    }

    private fun updatePrayerWindow(
        prayerWindowStartMs: Long,
        nextPrayerStartMs: Long,
    ) {
        val serviceIntent = Intent(this, AppLockMonitorService::class.java).apply {
            action = AppLockMonitorService.ACTION_UPDATE_PRAYER_WINDOW
            putExtra(AppLockMonitorService.EXTRA_PRAYER_WINDOW_START_MS, prayerWindowStartMs)
            putExtra(AppLockMonitorService.EXTRA_NEXT_PRAYER_START_MS, nextPrayerStartMs)
        }
        startService(serviceIntent)
    }

    // showTestOverlay removed: test button removed from production

    private fun getAppIcon(packageName: String): ByteArray? {
        return try {
            val drawable = packageManager.getApplicationIcon(packageName)
            drawableToPngBytes(drawable)
        } catch (_: Exception) {
            null
        }
    }

    private fun drawableToPngBytes(drawable: Drawable): ByteArray {
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 128
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 128

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)

        val output = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
        return output.toByteArray()
    }
}
