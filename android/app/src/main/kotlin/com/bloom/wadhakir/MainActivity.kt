package com.bloom.wadhakir

import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.bloom.wadhakir/widget_navigation"
    
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
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            // Method channel for Flutter to receive navigation commands
            result.success(null)
        }
    }
    
    private fun handleIntent(intent: Intent?) {
        when (intent?.action) {
            "HIJRI_PREVIOUS_MONTH" -> {
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL).invokeMethod("previousMonth", null)
                }
            }
            "HIJRI_NEXT_MONTH" -> {
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL).invokeMethod("nextMonth", null)
                }
            }
        }
    }
}
