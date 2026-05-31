package com.bloom.wadhakir

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.util.Calendar

/**
 * Hijri calendar home-screen widget. Month navigation and day selection are
 * handled fully natively from a pre-computed month cache (key
 * `hijri_month_cache`, written by the Flutter side). This avoids the previous
 * Flutter background-isolate round-trip, so arrow taps switch months instantly
 * with no flashing/jitter.
 */
class HijriCalendarWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.hijri_calendar_widget)
            try {
                val offset = widgetData.getString("hijri_month_offset", "0")?.toIntOrNull() ?: 0
                applyMonth(context, views, offset, widgetId, widgetData)
            } catch (e: Exception) {
                Log.e(TAG, "Error updating widget $widgetId", e)
            } finally {
                appWidgetManager.updateAppWidget(widgetId, views)
            }
        }
    }

    /**
     * Populate [views] with the month at [offset], reading metadata from the
     * JSON cache (falling back to the legacy single keys on first paint).
     */
    private fun applyMonth(
        context: Context,
        views: RemoteViews,
        offset: Int,
        widgetId: Int,
        prefs: SharedPreferences
    ) {
        var monthYear = ""
        var daysInMonth = 30
        var firstDayOffset = 0
        var todayDay = 0
        val selectedDay = prefs.getString("selected_day", "0")?.toIntOrNull() ?: 0

        var loadedFromCache = false
        val cacheStr = prefs.getString("hijri_month_cache", null)
        if (cacheStr != null) {
            try {
                val monthObj = JSONObject(cacheStr).optJSONObject(offset.toString())
                if (monthObj != null) {
                    monthYear = monthObj.optString("monthYear", "")
                    daysInMonth = monthObj.optInt("daysInMonth", 30)
                    firstDayOffset = monthObj.optInt("firstDayOffset", 0)
                    todayDay = monthObj.optInt("todayDay", 0)
                    loadedFromCache = true
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing month cache", e)
            }
        }

        if (!loadedFromCache) {
            // First-paint fallback before the JSON cache has been written.
            monthYear = prefs.getString("hijri_month_year", "") ?: ""
            daysInMonth = prefs.getString("days_in_month", "30")?.toIntOrNull() ?: 30
            firstDayOffset = prefs.getString("first_day_offset", "0")?.toIntOrNull() ?: 0
            todayDay = prefs.getString("today_day", "0")?.toIntOrNull() ?: 0
        }

        val hijriDateDisplay = prefs.getString("hijri_date_display", "") ?: ""
        val gregorianDateDisplay = prefs.getString("gregorian_date_display", "") ?: ""

        views.setTextViewText(R.id.hijri_month_year, monthYear)
        views.setTextViewText(R.id.hijri_date_display, hijriDateDisplay)
        views.setTextViewText(R.id.gregorian_date_display, gregorianDateDisplay)

        setNavigationClickListeners(context, views, widgetId)

        // Hide all day cells first.
        for (i in 1..35) {
            views.setViewVisibility(getDayViewId(i), View.GONE)
        }

        // Show and populate the days of this month.
        var dayNumber = 1
        for (position in 1..35) {
            if (position > firstDayOffset && dayNumber <= daysInMonth) {
                val dayId = getDayViewId(position)
                views.setTextViewText(dayId, dayNumber.toString())
                views.setViewVisibility(dayId, View.VISIBLE)

                val dayClickIntent = Intent(context, HijriCalendarWidgetProvider::class.java).apply {
                    action = ACTION_DAY_CLICKED
                    putExtra("day_number", dayNumber)
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                }
                val dayClickPendingIntent = PendingIntent.getBroadcast(
                    context,
                    widgetId * 100 + dayNumber,
                    dayClickIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(dayId, dayClickPendingIntent)

                when {
                    dayNumber == selectedDay && selectedDay > 0 -> {
                        views.setInt(dayId, "setBackgroundResource", R.drawable.selected_day_background)
                        views.setTextColor(dayId, 0xFFFFFFFF.toInt())
                        views.setTextViewTextSize(dayId, TypedValue.COMPLEX_UNIT_SP, 15f)
                    }
                    dayNumber == todayDay && todayDay > 0 -> {
                        views.setInt(dayId, "setBackgroundResource", R.drawable.today_background)
                        views.setTextColor(dayId, 0xFFFFFFFF.toInt())
                        views.setTextViewTextSize(dayId, TypedValue.COMPLEX_UNIT_SP, 15f)
                    }
                    else -> {
                        views.setInt(dayId, "setBackgroundResource", R.drawable.day_box_background)
                        views.setTextColor(dayId, 0xFFE8E8E8.toInt())
                        views.setTextViewTextSize(dayId, TypedValue.COMPLEX_UNIT_SP, 13f)
                    }
                }

                dayNumber++
            }
        }
    }

    private fun setNavigationClickListeners(context: Context, views: RemoteViews, widgetId: Int) {
        val prevIntent = Intent(context, HijriCalendarWidgetProvider::class.java).apply {
            action = ACTION_PREVIOUS_MONTH
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        val prevPendingIntent = PendingIntent.getBroadcast(
            context,
            widgetId * 2,
            prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.prev_month_button, prevPendingIntent)

        val nextIntent = Intent(context, HijriCalendarWidgetProvider::class.java).apply {
            action = ACTION_NEXT_MONTH
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        val nextPendingIntent = PendingIntent.getBroadcast(
            context,
            widgetId * 2 + 1,
            nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.next_month_button, nextPendingIntent)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_PREVIOUS_MONTH -> navigateMonth(context, -1)
            ACTION_NEXT_MONTH -> navigateMonth(context, 1)
            ACTION_DAY_CLICKED -> handleDayClick(context, intent.getIntExtra("day_number", 0))
        }
    }

    /** Switch month instantly by reading the new offset's entry from the cache. */
    private fun navigateMonth(context: Context, direction: Int) {
        try {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val currentOffset = prefs.getString("hijri_month_offset", "0")?.toIntOrNull() ?: 0
            var newOffset = currentOffset + direction
            if (newOffset > CACHE_RADIUS) newOffset = CACHE_RADIUS
            if (newOffset < -CACHE_RADIUS) newOffset = -CACHE_RADIUS
            if (newOffset == currentOffset) return // at the edge of the cached window

            prefs.edit()
                .putString("hijri_month_offset", newOffset.toString())
                .putString("selected_day", "0")
                .apply()

            refreshAllWidgets(context, prefs, newOffset)
        } catch (e: Exception) {
            Log.e(TAG, "Error navigating month", e)
        }
    }

    /** Update the date card for the tapped day, computing its dates natively. */
    private fun handleDayClick(context: Context, dayNumber: Int) {
        if (dayNumber <= 0) return
        try {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val offset = prefs.getString("hijri_month_offset", "0")?.toIntOrNull() ?: 0

            var hijriDisplay: String? = null
            var gregorianDisplay: String? = null

            val cacheStr = prefs.getString("hijri_month_cache", null)
            if (cacheStr != null) {
                try {
                    val monthObj = JSONObject(cacheStr).optJSONObject(offset.toString())
                    if (monthObj != null) {
                        hijriDisplay = "$dayNumber ${hijriMonthName(monthObj.optInt("hMonth", 1))}"
                        // Day-1 Gregorian + (day - 1) days = clicked day's Gregorian.
                        val cal = Calendar.getInstance()
                        cal.clear()
                        cal.set(
                            monthObj.optInt("gYear"),
                            monthObj.optInt("gMonth") - 1, // Calendar months are 0-based
                            monthObj.optInt("gDay")
                        )
                        cal.add(Calendar.DAY_OF_MONTH, dayNumber - 1)
                        gregorianDisplay =
                            "${cal.get(Calendar.DAY_OF_MONTH)} ${gregMonthName(cal.get(Calendar.MONTH) + 1)}"
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error computing clicked day", e)
                }
            }

            val editor = prefs.edit().putString("selected_day", dayNumber.toString())
            if (hijriDisplay != null) editor.putString("hijri_date_display", hijriDisplay)
            if (gregorianDisplay != null) editor.putString("gregorian_date_display", gregorianDisplay)
            editor.apply()

            refreshAllWidgets(context, prefs, offset)
        } catch (e: Exception) {
            Log.e(TAG, "Error handling day click", e)
        }
    }

    private fun refreshAllWidgets(context: Context, prefs: SharedPreferences, offset: Int) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val ids = appWidgetManager.getAppWidgetIds(
            ComponentName(context, HijriCalendarWidgetProvider::class.java)
        )
        ids.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.hijri_calendar_widget)
            applyMonth(context, views, offset, widgetId, prefs)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun getDayViewId(position: Int): Int {
        return when (position) {
            1 -> R.id.day_1; 2 -> R.id.day_2; 3 -> R.id.day_3; 4 -> R.id.day_4
            5 -> R.id.day_5; 6 -> R.id.day_6; 7 -> R.id.day_7; 8 -> R.id.day_8
            9 -> R.id.day_9; 10 -> R.id.day_10; 11 -> R.id.day_11; 12 -> R.id.day_12
            13 -> R.id.day_13; 14 -> R.id.day_14; 15 -> R.id.day_15; 16 -> R.id.day_16
            17 -> R.id.day_17; 18 -> R.id.day_18; 19 -> R.id.day_19; 20 -> R.id.day_20
            21 -> R.id.day_21; 22 -> R.id.day_22; 23 -> R.id.day_23; 24 -> R.id.day_24
            25 -> R.id.day_25; 26 -> R.id.day_26; 27 -> R.id.day_27; 28 -> R.id.day_28
            29 -> R.id.day_29; 30 -> R.id.day_30; 31 -> R.id.day_31; 32 -> R.id.day_32
            33 -> R.id.day_33; 34 -> R.id.day_34; 35 -> R.id.day_35
            else -> R.id.day_1
        }
    }

    private fun hijriMonthName(month: Int): String =
        if (month in 1..12) HIJRI_MONTHS[month - 1] else ""

    private fun gregMonthName(month: Int): String =
        if (month in 1..12) GREG_MONTHS[month - 1] else ""

    companion object {
        private const val TAG = "HijriCalendarWidget"
        private const val PREFS = "HomeWidgetPreferences"
        private const val CACHE_RADIUS = 24
        private const val ACTION_PREVIOUS_MONTH = "com.bloom.wadhakir.ACTION_PREVIOUS_MONTH"
        private const val ACTION_NEXT_MONTH = "com.bloom.wadhakir.ACTION_NEXT_MONTH"
        private const val ACTION_DAY_CLICKED = "com.bloom.wadhakir.ACTION_DAY_CLICKED"

        private val HIJRI_MONTHS = arrayOf(
            "محرم", "صفر", "ربيع الأول", "ربيع الثاني", "جمادى الأولى", "جمادى الآخرة",
            "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة"
        )
        private val GREG_MONTHS = arrayOf(
            "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
            "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
        )
    }
}
