package com.bloom.wadhakir

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class PrayerTimesWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val CLICK_TIMESTAMP_KEY = "last_click_timestamp"
        private const val DOUBLE_CLICK_DELAY = 500 // milliseconds
    }

    private var lastWidgetData: Map<String, String?> = mapOf()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        // Get current data from SharedPreferences
        val currentData = mapOf(
            "location" to widgetData.getString("location", null),
            "date" to widgetData.getString("date", null),
            "currentPrayer" to widgetData.getString("currentPrayer", null),
            "currentPrayerTime" to widgetData.getString("currentPrayerTime", null),
            "nextPrayer" to widgetData.getString("nextPrayer", null),
            "timeUntilNext" to widgetData.getString("timeUntilNext", null)
        )

        // If all new values are null and we have previous data, use the previous data
        if (currentData.values.all { it == null } && lastWidgetData.values.any { it != null }) {
            Log.d("PrayerTimesWidget", "Received null values, using cached data")
            return
        }

        // Update cached data if we have valid new data
        if (currentData.values.any { it != null }) {
            lastWidgetData = currentData
        }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)
            
            try {
                // Use cached data
                val location = lastWidgetData["location"]
                val date = lastWidgetData["date"]
                val currentPrayer = lastWidgetData["currentPrayer"]
                val currentPrayerTime = lastWidgetData["currentPrayerTime"]
                val nextPrayer = lastWidgetData["nextPrayer"]
                val timeUntilNext = lastWidgetData["timeUntilNext"]

                // Log the retrieved values
                Log.d("PrayerTimesWidget", """
                    Retrieved prayer times:
                    Location: $location
                    Date: $date
                    Current Prayer: $currentPrayer
                    Current Prayer Time: $currentPrayerTime
                    Next Prayer: $nextPrayer
                    Time Until Next: $timeUntilNext
                """.trimIndent())

                // Update the location and date
                views.setTextViewText(R.id.location_text, location ?: "Location unavailable")
                views.setTextViewText(R.id.date_text, date ?: "")

                // Update current prayer info
                views.setTextViewText(R.id.current_prayer_name, currentPrayer ?: "")
                views.setTextViewText(R.id.current_prayer_time, currentPrayerTime ?: "")

                // Update next prayer info
                views.setTextViewText(R.id.next_prayer_name, nextPrayer ?: "")
                views.setTextViewText(R.id.time_until_next_prayer, timeUntilNext ?: "")
                
                // Handle click events based on last click time
                val currentTime = SystemClock.elapsedRealtime()
                val prefs = context.getSharedPreferences("WidgetClicks", Context.MODE_PRIVATE)
                val lastClickTime = prefs.getLong(CLICK_TIMESTAMP_KEY + widgetId, 0)

                if (currentTime - lastClickTime <= DOUBLE_CLICK_DELAY) {
                    // Double click - launch app
                    val launchIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        null
                    )
                    views.setOnClickPendingIntent(R.id.widget_container, launchIntent)
                } else {
                    // Single click - update widget
                    val updateIntent = Intent(context, PrayerTimesWidgetProvider::class.java).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
                    }
                    val updatePendingIntent = PendingIntent.getBroadcast(
                        context,
                        widgetId,
                        updateIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.widget_container, updatePendingIntent)
                }

                // Update last click time
                prefs.edit().putLong(CLICK_TIMESTAMP_KEY + widgetId, currentTime).apply()
                
                Log.d("PrayerTimesWidget", "Widget views updated successfully")
            } catch (e: Exception) {
                Log.e("PrayerTimesWidget", "Error updating widget", e)
            } finally {
                // Always update the widget, even if there was an error
                appWidgetManager.updateAppWidget(widgetId, views)
                Log.d("PrayerTimesWidget", "Widget ${widgetId} update completed")
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        // Handle widget update broadcasts
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val widgetData = context.getSharedPreferences("HomeWidgetProvider", Context.MODE_PRIVATE)
                onUpdate(context, appWidgetManager, appWidgetIds, widgetData)
            }
        }
    }
}