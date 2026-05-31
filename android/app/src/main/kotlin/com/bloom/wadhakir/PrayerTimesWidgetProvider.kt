package com.bloom.wadhakir

import android.appwidget.AppWidgetManager
import android.content.Context
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class PrayerTimesWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)

            try {
                // Read the latest values straight from the home_widget store.
                val location = widgetData.getString("location", null)
                val date = widgetData.getString("date", null)
                val currentPrayer = widgetData.getString("currentPrayer", null)
                val currentPrayerTime = widgetData.getString("currentPrayerTime", null)
                val nextPrayer = widgetData.getString("nextPrayer", null)
                val timeUntilNext = widgetData.getString("timeUntilNext", null)

                views.setTextViewText(R.id.location_text, location ?: "Location unavailable")
                views.setTextViewText(R.id.date_text, date ?: "")
                views.setTextViewText(R.id.current_prayer_name, currentPrayer ?: "")
                views.setTextViewText(R.id.current_prayer_time, currentPrayerTime ?: "")
                views.setTextViewText(R.id.next_prayer_name, nextPrayer ?: "")
                views.setTextViewText(R.id.time_until_next_prayer, timeUntilNext ?: "")

                // First tap opens the app.
                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    null
                )
                views.setOnClickPendingIntent(R.id.widget_container, launchIntent)

                Log.d("PrayerTimesWidget", "Widget views updated successfully")
            } catch (e: Exception) {
                Log.e("PrayerTimesWidget", "Error updating widget", e)
            } finally {
                appWidgetManager.updateAppWidget(widgetId, views)
            }
        }
    }
}
