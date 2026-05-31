package com.bloom.wadhakir

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Glassy live clock widget. The current time ([TextClock]) and the countdown to
 * the next prayer ([android.widget.Chronometer]) both tick on their own without
 * any app refresh. Date + next-prayer name come from the home_widget store.
 */
class GlassClockWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.glass_clock_widget)
            try {
                val hijri = widgetData.getString("hijri_date", "") ?: ""
                val greg = widgetData.getString("gregorian_date", "") ?: ""
                val dateLine = listOf(hijri, greg)
                    .filter { it.isNotEmpty() }
                    .joinToString("  •  ")
                views.setTextViewText(R.id.clock_date_line, dateLine)

                val nextName = widgetData.getString("nextPrayerArabic", "") ?: ""
                views.setTextViewText(R.id.clock_next_prayer, nextName)

                // Self-ticking countdown to the next prayer.
                val epoch = widgetData.getString("nextPrayerEpoch", null)?.toLongOrNull()
                if (epoch != null) {
                    val base = SystemClock.elapsedRealtime() +
                        (epoch - System.currentTimeMillis())
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        views.setChronometerCountDown(R.id.clock_countdown, true)
                    }
                    views.setChronometer(R.id.clock_countdown, base, null, true)
                } else {
                    views.setChronometer(
                        R.id.clock_countdown,
                        SystemClock.elapsedRealtime(),
                        null,
                        false
                    )
                }

                views.setOnClickPendingIntent(
                    R.id.widget_container,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, null)
                )
            } catch (e: Exception) {
                Log.e("GlassClockWidget", "Error updating widget", e)
            } finally {
                appWidgetManager.updateAppWidget(widgetId, views)
            }
        }
    }
}
