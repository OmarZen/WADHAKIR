package com.bloom.wadhakir

import android.appwidget.AppWidgetManager
import android.content.Context
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONArray
import java.util.Calendar

/**
 * Home-screen widget showing today's ayah / dua / hadith.
 *
 * The full filtered list is pushed from Dart as a JSON array; the daily index
 * is recomputed HERE so the widget rotates at midnight without the app running.
 * The formula `(DAY_OF_YEAR - 1) % len` matches the Dart side
 * (`DailyInspirationService.indexFor`, 0-based day-of-year) so the widget, the
 * notification and the in-app card show the same item on a given day.
 * `home_widget` stores every value as a String.
 */
class DailyInspirationWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.daily_inspiration_widget)

            try {
                val title = widgetData.getString("daily_title", "آية وذِكر اليوم")
                    ?: "آية وذِكر اليوم"
                views.setTextViewText(R.id.daily_title, title)

                val itemsJson = widgetData.getString("daily_items", "[]") ?: "[]"
                val arr = JSONArray(itemsJson)

                if (arr.length() == 0) {
                    views.setTextViewText(R.id.daily_arabic, "افتح التطبيق لعرض ذِكر اليوم")
                    views.setTextViewText(R.id.daily_reference, "")
                } else {
                    val dayOfYear = Calendar.getInstance().get(Calendar.DAY_OF_YEAR) - 1
                    val idx = ((dayOfYear % arr.length()) + arr.length()) % arr.length()
                    val obj = arr.optJSONObject(idx)
                    views.setTextViewText(R.id.daily_arabic, obj?.optString("arabic", "") ?: "")
                    views.setTextViewText(R.id.daily_reference, obj?.optString("reference", "") ?: "")
                }

                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    null
                )
                views.setOnClickPendingIntent(R.id.daily_widget_container, launchIntent)
            } catch (e: Exception) {
                Log.e("DailyInspirationWidget", "Error updating widget", e)
            } finally {
                appWidgetManager.updateAppWidget(widgetId, views)
            }
        }
    }
}
