package com.bloom.wadhakir

import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class PrayerTimesListWidgetProviderNew : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: android.content.SharedPreferences) {

        appWidgetIds.forEach { widgetId ->
            // FIX: Move this to the TOP so 'views' exists before we use it
            val views = RemoteViews(context.packageName, R.layout.prayer_times_list_widget_new)

            // 1. Handle the Countdown (Chronometer)
            // Compute next prayer live from individual timestamps so the widget
            // stays accurate throughout the day without needing a Flutter app relaunch.
            val now = System.currentTimeMillis()
            val prayerList = listOf(
                Pair("Fajr",    widgetData.getLong("fajrTimestamp", 0L)),
                Pair("Dhuhr",   widgetData.getLong("dhuhrTimestamp", 0L)),
                Pair("Asr",     widgetData.getLong("asrTimestamp", 0L)),
                Pair("Maghrib", widgetData.getLong("maghribTimestamp", 0L)),
                Pair("Isha",    widgetData.getLong("ishaTimestamp", 0L)),
            )
            val hasTimestamps = prayerList.any { it.second > 0L }
            val nextPrayerEntry = prayerList.firstOrNull { it.second > now }

            // If individual timestamps haven't been saved yet (first run after update),
            // fall back to the pre-computed values from the old approach.
            val nextPrayerName: String
            val nextPrayerMillis: Long
            if (hasTimestamps) {
                nextPrayerName = nextPrayerEntry?.first ?: "Fajr"
                nextPrayerMillis = nextPrayerEntry?.second ?: 0L
            } else {
                nextPrayerName = widgetData.getString("nextPrayerName", "Fajr") ?: "Fajr"
                nextPrayerMillis = widgetData.getLong("nextPrayerTimestamp", 0L)
            }

            if (nextPrayerMillis > 0) {
                val timeUntilPrayer = nextPrayerMillis - now
                val chronoBase = SystemClock.elapsedRealtime() + timeUntilPrayer
                views.setChronometer(R.id.countdown_text_new, chronoBase, null, true)
                // setString (not setCharSequence) — Chronometer.setFormat takes String, not CharSequence
                views.setString(R.id.countdown_text_new, "setFormat", "$nextPrayerName in %s")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    views.setChronometerCountDown(R.id.countdown_text_new, true)
                }
            } else {
                views.setTextViewText(R.id.countdown_text_new, "")
            }

            // 2. Handle Prayer Highlights
            val currentPrayer = if (hasTimestamps) {
                (prayerList.lastOrNull { it.second <= now }?.first ?: "Isha").uppercase()
            } else {
                widgetData.getString("currentPrayer", "")?.uppercase()?.trim() ?: ""
            }

            val prayerMap = mapOf(
                "FAJR" to Triple(R.id.fajr_container_new, R.id.fajr_label_new, R.id.fajr_time_new),
                "DHUHR" to Triple(R.id.dhuhr_container_new, R.id.dhuhr_label_new, R.id.dhuhr_time_new),
                "ASR" to Triple(R.id.asr_container_new, R.id.asr_label_new, R.id.asr_time_new),
                "MAGHRIB" to Triple(R.id.maghrib_container_new, R.id.maghrib_label_new, R.id.maghrib_time_new),
                "ISHA" to Triple(R.id.isha_container_new, R.id.isha_label_new, R.id.isha_time_new)
            )

            // Reset all containers and set prayer times
            prayerMap.forEach { (name, ids) ->
                val (container, label, time) = ids
                views.setInt(container, "setBackgroundResource", 0)
                views.setTextColor(label, Color.WHITE)
                views.setTextColor(time, Color.WHITE)

                // Sets the time (e.g., 4:25 AM)
                views.setTextViewText(time, widgetData.getString(name.lowercase(), "--:--"))
            }

            // Apply the "Pill" highlight to the current prayer
            if (prayerMap.containsKey(currentPrayer)) {
                val (container, label, time) = prayerMap[currentPrayer]!!
                views.setInt(container, "setBackgroundResource", R.drawable.current_prayer_pill)
                views.setTextColor(label, Color.BLACK)
                views.setTextColor(time, Color.BLACK)
            }

            // 3. Set Dates
            views.setTextViewText(R.id.gregorian_date_new, widgetData.getString("gregorian_date", ""))
            views.setTextViewText(R.id.hijri_date_new, widgetData.getString("hijri_date", ""))
            views.setTextViewText(R.id.day_name_new, widgetData.getString("day_name", ""))

            // 4. Set Launch Intent (Open app on click)
            val launchIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_container_new, launchIntent)

            // 5. Update the Widget
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}