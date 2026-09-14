package com.bloom.wadhakir

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

/**
 * "Prayer Next" glass widget. Displays a Flutter-rendered PNG (path stored
 * under `glass_prayer_next_image`) and opens the app on a single tap.
 */
class GlassPrayerNextWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.glass_prayer_next_widget)
            try {
                val path = widgetData.getString("glass_prayer_next_image", null)
                if (path != null && File(path).exists()) {
                    BitmapFactory.decodeFile(path)?.let {
                        views.setImageViewBitmap(R.id.widget_image, it)
                    }
                }
                views.setOnClickPendingIntent(
                    R.id.widget_image,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, null)
                )
            } catch (e: Exception) {
                Log.e("GlassPrayerNext", "Error updating widget", e)
            } finally {
                appWidgetManager.updateAppWidget(widgetId, views)
            }
        }
    }
}
