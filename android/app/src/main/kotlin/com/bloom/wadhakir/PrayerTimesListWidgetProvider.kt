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

class PrayerTimesListWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.prayer_times_list_widget)
            
            try {
                // Get prayer times from shared preferences
                val fajr = widgetData.getString("fajr", "--:--")
                val dhuhr = widgetData.getString("dhuhr", "--:--")
                val asr = widgetData.getString("asr", "--:--")
                val maghrib = widgetData.getString("maghrib", "--:--")
                val isha = widgetData.getString("isha", "--:--")
                
                // Get date information
                val hijriDate = widgetData.getString("hijri_date", "")
                val gregorianDate = widgetData.getString("gregorian_date", "")
                val dayName = widgetData.getString("day_name", "")

                // Log the retrieved values
                Log.d("PrayerTimesListWidget", """
                    Retrieved prayer times:
                    Fajr: $fajr
                    Dhuhr: $dhuhr
                    Asr: $asr
                    Maghrib: $maghrib
                    Isha: $isha
                    Hijri Date: $hijriDate
                    Gregorian Date: $gregorianDate
                    Day Name: $dayName
                """.trimIndent())

                // Update all prayer times
                views.setTextViewText(R.id.fajr_time, fajr ?: "--:--")
                views.setTextViewText(R.id.dhuhr_time, dhuhr ?: "--:--")
                views.setTextViewText(R.id.asr_time, asr ?: "--:--")
                views.setTextViewText(R.id.maghrib_time, maghrib ?: "--:--")
                views.setTextViewText(R.id.isha_time, isha ?: "--:--")
                
                // Update date information
                views.setTextViewText(R.id.hijri_date, hijriDate ?: "")
                views.setTextViewText(R.id.gregorian_date, gregorianDate ?: "")
                views.setTextViewText(R.id.day_name, dayName ?: "")

                // Get current prayer and highlight it
                val currentPrayer = widgetData.getString("currentPrayer", "")?.uppercase()
                
                // Reset all backgrounds first
                views.setInt(R.id.fajr_container, "setBackgroundResource", 0)
                views.setInt(R.id.dhuhr_container, "setBackgroundResource", 0)
                views.setInt(R.id.asr_container, "setBackgroundResource", 0)
                views.setInt(R.id.maghrib_container, "setBackgroundResource", 0)
                views.setInt(R.id.isha_container, "setBackgroundResource", 0)

                // Set background for current prayer
                when (currentPrayer) {
                    "FAJR" -> views.setInt(R.id.fajr_container, "setBackgroundResource", R.drawable.current_prayer_background)
                    "DHUHR" -> views.setInt(R.id.dhuhr_container, "setBackgroundResource", R.drawable.current_prayer_background)
                    "ASR" -> views.setInt(R.id.asr_container, "setBackgroundResource", R.drawable.current_prayer_background)
                    "MAGHRIB" -> views.setInt(R.id.maghrib_container, "setBackgroundResource", R.drawable.current_prayer_background)
                    "ISHA" -> views.setInt(R.id.isha_container, "setBackgroundResource", R.drawable.current_prayer_background)
                }

                // Add click handler to launch the app
                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    null
                )
                views.setOnClickPendingIntent(R.id.widget_container, launchIntent)

                Log.d("PrayerTimesListWidget", "Widget views updated successfully")
            } catch (e: Exception) {
                Log.e("PrayerTimesListWidget", "Error updating widget", e)
            } finally {
                // Always update the widget, even if there was an error
                appWidgetManager.updateAppWidget(widgetId, views)
                Log.d("PrayerTimesListWidget", "Widget ${widgetId} update completed")
            }
        }
    }
}