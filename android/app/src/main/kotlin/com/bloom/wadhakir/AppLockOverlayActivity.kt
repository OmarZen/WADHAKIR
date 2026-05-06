package com.bloom.wadhakir

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity

class AppLockOverlayActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        WindowCompat.setDecorFitsSystemWindows(window, false)

        val message = intent.getStringExtra("overlay_message")
            ?: "Use this moment for something beneficial and meaningful."

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
            setBackgroundColor(Color.parseColor("#FF0B1320"))
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
        }

        val title = TextView(this).apply {
            text = "وقت ثمين"
            textSize = 30f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        }

        val body = TextView(this).apply {
            text = message
            textSize = 18f
            setTextColor(Color.parseColor("#FFE3ECFF"))
            gravity = Gravity.CENTER
            setPadding(0, 26, 0, 26)
        }

        val action = Button(this).apply {
            text = "الرجوع للرئيسية"
            textSize = 18f
            setPadding(36, 20, 36, 20)
            setOnClickListener {
                goHome()
            }
        }

        root.addView(title)
        root.addView(body)
        root.addView(action)

        setContentView(root)
    }

    override fun onBackPressed() {
        goHome()
    }

    private fun goHome() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }
}
