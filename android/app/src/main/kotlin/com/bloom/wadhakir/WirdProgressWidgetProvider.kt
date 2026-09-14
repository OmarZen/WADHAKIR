package com.bloom.wadhakir

import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONObject
import java.util.Calendar

/**
 * Home-screen widget showing the user's daily Quran wird (ورد) progress.
 *
 * The pace (متأخر / متقدم) is recomputed HERE from raw inputs against the
 * current date, so the widget stays fresh as days pass without needing the app
 * to be opened. `home_widget` stores every value as a String, so all reads use
 * getString(...). The arithmetic mirrors `WirdProgressStatus` (Dart) — keep the
 * two in sync.
 */
class WirdProgressWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.wird_progress_widget)

            try {
                val title = widgetData.getString("wird_title", "وردك اليومي") ?: "وردك اليومي"
                views.setTextViewText(R.id.wird_title, title)

                val active = widgetData.getString("wird_active", "false") == "true"

                if (!active) {
                    // Empty / not-set-up state.
                    views.setImageViewBitmap(R.id.wird_ring, drawProgressRing(0, "#8FB8E0"))
                    views.setTextViewText(R.id.wird_emoji, "📖")
                    views.setTextViewText(R.id.wird_status, "ابدأ وردك")
                    views.setTextViewText(R.id.wird_motivation, "اضغط لبدء ختمتك القرآنية")
                } else {
                    val total = widgetData.getString("wird_total_days", "0")?.toIntOrNull() ?: 0
                    val completed = widgetData.getString("wird_completed_days", "0")?.toIntOrNull() ?: 0
                    val startEpoch = widgetData.getString("wird_start_epoch", "0")?.toLongOrNull() ?: 0L
                    val percent = widgetData.getString("wird_percent", "0")?.toIntOrNull() ?: 0
                    val messagesJson = widgetData.getString("wird_messages", "{}") ?: "{}"

                    // --- pace recompute (keep in sync with WirdProgressStatus) ---
                    val now = System.currentTimeMillis()
                    val elapsed = if (startEpoch > 0L)
                        maxOf(0L, (now - startEpoch) / 86_400_000L).toInt() else 0
                    val expected = elapsed.coerceIn(0, total)
                    val daysLate = maxOf(0, expected - completed)
                    val daysAhead = maxOf(0, completed - expected)
                    val finished = total > 0 && completed >= total

                    val bucket = when {
                        finished -> "finished"
                        daysLate > 0 -> "behind"
                        daysAhead > 0 -> "ahead"
                        else -> "ontrack"
                    }
                    val emoji = when (bucket) {
                        "finished" -> "🎉"
                        "behind" -> "😔"
                        "ahead" -> "🌟"
                        else -> "📖"
                    }
                    // Short status — the compact widget keeps it to one line.
                    val status = when (bucket) {
                        "finished" -> "تمت الختمة"
                        "behind" -> "متأخّر ${daysLabel(daysLate)}"
                        "ahead" -> "متقدّم ${daysLabel(daysAhead)}"
                        else -> "على المسار"
                    }
                    // Ring colour reflects the pace (calm tones, not alarming).
                    val ringColor = when (bucket) {
                        "finished" -> "#7BD88F" // green
                        "behind" -> "#E6A15C"   // warm amber
                        "ahead" -> "#F2C879"    // gold
                        else -> "#8FB8E0"       // blue
                    }

                    views.setImageViewBitmap(
                        R.id.wird_ring,
                        drawProgressRing(percent.coerceIn(0, 100), ringColor)
                    )
                    views.setTextViewText(R.id.wird_emoji, emoji)
                    views.setTextViewText(R.id.wird_status, status)
                    views.setTextViewText(R.id.wird_motivation, pickMessage(messagesJson, bucket))
                }

                // Tap opens the app.
                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    null
                )
                views.setOnClickPendingIntent(R.id.wird_widget_container, launchIntent)
            } catch (e: Exception) {
                Log.e("WirdProgressWidget", "Error updating widget", e)
            } finally {
                appWidgetManager.updateAppWidget(widgetId, views)
            }
        }
    }

    /**
     * Draws a compact determinate progress ring (track + arc + centered
     * percent) to a bitmap, since RemoteViews has no circular progress view.
     */
    private fun drawProgressRing(percent: Int, colorHex: String): Bitmap {
        val size = 252
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val stroke = size * 0.105f
        val pad = stroke / 2f + size * 0.05f
        val rect = RectF(pad, pad, size - pad, size - pad)

        val track = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = stroke
            color = Color.parseColor("#30FFFFFF")
            strokeCap = Paint.Cap.ROUND
        }
        canvas.drawArc(rect, 0f, 360f, false, track)

        val prog = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = stroke
            color = Color.parseColor(colorHex)
            strokeCap = Paint.Cap.ROUND
        }
        val sweep = 360f * (percent.coerceIn(0, 100) / 100f)
        if (sweep > 0f) canvas.drawArc(rect, -90f, sweep, false, prog)

        val tp = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textAlign = Paint.Align.CENTER
            textSize = size * 0.28f
            isFakeBoldText = true
        }
        val label = "${arabicDigits(percent)}٪"
        val fm = tp.fontMetrics
        canvas.drawText(label, size / 2f, size / 2f - (fm.ascent + fm.descent) / 2f, tp)
        return bmp
    }

    /** Pick a daily-rotating line from the matching bucket of the messages JSON. */
    private fun pickMessage(json: String, bucket: String): String {
        return try {
            val arr = JSONObject(json).optJSONArray(bucket) ?: return ""
            if (arr.length() == 0) return ""
            val dayOfYear = Calendar.getInstance().get(Calendar.DAY_OF_YEAR)
            arr.optString(dayOfYear % arr.length(), arr.optString(0, ""))
        } catch (e: Exception) {
            ""
        }
    }

    /** Western → Arabic-Indic digits, matching WirdFormat.toArabicDigits. */
    private fun arabicDigits(n: Int): String {
        val map = charArrayOf('٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩')
        return n.toString().map { c -> if (c in '0'..'9') map[c - '0'] else c }.joinToString("")
    }

    /** Grammatically-aware Arabic day count, matching WirdFormat.daysLabel. */
    private fun daysLabel(n: Int): String = when {
        n == 1 -> "يوم واحد"
        n == 2 -> "يومين"
        n in 3..10 -> "${arabicDigits(n)} أيام"
        else -> "${arabicDigits(n)} يومًا"
    }
}
