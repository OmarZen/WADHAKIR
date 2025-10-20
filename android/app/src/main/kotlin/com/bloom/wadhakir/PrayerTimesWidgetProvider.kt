package com.bloom.wadhakir

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import org.json.JSONObject

class PrayerTimesWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)
        
        // Get saved prayer times data from Flutter shared preferences
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        try {
            // Get individual prayer times
            val fajr = prefs.getString("flutter.fajr", null)
            val dhuhr = prefs.getString("flutter.dhuhr", null)
            val asr = prefs.getString("flutter.asr", null)
            val maghrib = prefs.getString("flutter.maghrib", null)
            val isha = prefs.getString("flutter.isha", null)

            android.util.Log.d("PrayerTimesWidget", "Fajr: $fajr, Dhuhr: $dhuhr, Asr: $asr, Maghrib: $maghrib, Isha: $isha")
            
            // Update the widget views with prayer times
            views.setTextViewText(R.id.fajr_time, "Fajr: ${fajr ?: "--:--"}")
            views.setTextViewText(R.id.dhuhr_time, "Dhuhr: ${dhuhr ?: "--:--"}")
            views.setTextViewText(R.id.asr_time, "Asr: ${asr ?: "--:--"}")
            views.setTextViewText(R.id.maghrib_time, "Maghrib: ${maghrib ?: "--:--"}")
            views.setTextViewText(R.id.isha_time, "Isha: ${isha ?: "--:--"}")
            
            android.util.Log.d("PrayerTimesWidget", "Widget views updated successfully")
        } catch (e: Exception) {
            android.util.Log.e("PrayerTimesWidget", "Error updating widget", e)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}