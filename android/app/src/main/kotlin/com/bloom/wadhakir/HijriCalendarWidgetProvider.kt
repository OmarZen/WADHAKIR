package com.bloom.wadhakir

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class HijriCalendarWidgetProvider : HomeWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} widgets")
        
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.hijri_calendar_widget)
            
            try {
                // Get calendar data from shared preferences (stored as strings by home_widget)
                val monthYear = widgetData.getString("hijri_month_year", "رجب 1447")
                val daysInMonth = widgetData.getString("days_in_month", "30")?.toIntOrNull() ?: 30
                val firstDayOffset = widgetData.getString("first_day_offset", "0")?.toIntOrNull() ?: 0
                val todayDay = widgetData.getString("today_day", "0")?.toIntOrNull() ?: 0
                val selectedDay = widgetData.getString("selected_day", "0")?.toIntOrNull() ?: 0
                val hijriDateDisplay = widgetData.getString("hijri_date_display", "23 رجب")
                val gregorianDateDisplay = widgetData.getString("gregorian_date_display", "12 يناير")

                Log.d(TAG, "Calendar data - Month: $monthYear, Days: $daysInMonth, Offset: $firstDayOffset, Today: $todayDay, Selected: $selectedDay")

                // Set month/year header
                views.setTextViewText(R.id.hijri_month_year, monthYear)
                
                // Set date displays
                views.setTextViewText(R.id.hijri_date_display, hijriDateDisplay)
                views.setTextViewText(R.id.gregorian_date_display, gregorianDateDisplay)

                // Set up navigation button click listeners
                setNavigationClickListeners(context, views, widgetId)

                // Hide all day views first
                for (i in 1..35) {
                    val dayId = getDayViewId(i)
                    views.setViewVisibility(dayId, View.GONE)
                }

                // Show and populate days
                var dayNumber = 1
                for (position in 1..35) {
                    if (position > firstDayOffset && dayNumber <= daysInMonth) {
                        val dayId = getDayViewId(position)
                        views.setTextViewText(dayId, dayNumber.toString())
                        views.setViewVisibility(dayId, View.VISIBLE)
                        
                        // Set click listener for each day
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
                        
                        // Style days - highlight today and selected day
                        when {
                            dayNumber == selectedDay && selectedDay > 0 -> {
                                // Selected day - medium blue
                                views.setInt(dayId, "setBackgroundResource", R.drawable.selected_day_background)
                                views.setTextColor(dayId, 0xFFFFFFFF.toInt()) // White text
                                views.setFloat(dayId, "setTextSize", 15f)
                                views.setTextViewTextSize(dayId, android.util.TypedValue.COMPLEX_UNIT_SP, 15f)
                            }
                            dayNumber == todayDay && todayDay > 0 -> {
                                // Today - lighter blue
                                views.setInt(dayId, "setBackgroundResource", R.drawable.today_background)
                                views.setTextColor(dayId, 0xFFFFFFFF.toInt()) // White text
                                views.setFloat(dayId, "setTextSize", 15f)
                                views.setTextViewTextSize(dayId, android.util.TypedValue.COMPLEX_UNIT_SP, 15f)
                            }
                            else -> {
                                // Regular day
                                views.setInt(dayId, "setBackgroundResource", R.drawable.day_box_background)
                                views.setTextColor(dayId, 0xFFE8E8E8.toInt()) // Light gray
                                views.setFloat(dayId, "setTextSize", 13f)
                                views.setTextViewTextSize(dayId, android.util.TypedValue.COMPLEX_UNIT_SP, 13f)
                            }
                        }
                        
                        dayNumber++
                    }
                }

                Log.d(TAG, "Widget $widgetId updated successfully with calendar")
            } catch (e: Exception) {
                Log.e(TAG, "Error updating widget $widgetId", e)
            } finally {
                appWidgetManager.updateAppWidget(widgetId, views)
            }
        }
    }
    
    private fun getDayViewId(position: Int): Int {
        return when (position) {
            1 -> R.id.day_1
            2 -> R.id.day_2
            3 -> R.id.day_3
            4 -> R.id.day_4
            5 -> R.id.day_5
            6 -> R.id.day_6
            7 -> R.id.day_7
            8 -> R.id.day_8
            9 -> R.id.day_9
            10 -> R.id.day_10
            11 -> R.id.day_11
            12 -> R.id.day_12
            13 -> R.id.day_13
            14 -> R.id.day_14
            15 -> R.id.day_15
            16 -> R.id.day_16
            17 -> R.id.day_17
            18 -> R.id.day_18
            19 -> R.id.day_19
            20 -> R.id.day_20
            21 -> R.id.day_21
            22 -> R.id.day_22
            23 -> R.id.day_23
            24 -> R.id.day_24
            25 -> R.id.day_25
            26 -> R.id.day_26
            27 -> R.id.day_27
            28 -> R.id.day_28
            29 -> R.id.day_29
            30 -> R.id.day_30
            31 -> R.id.day_31
            32 -> R.id.day_32
            33 -> R.id.day_33
            34 -> R.id.day_34
            35 -> R.id.day_35
            else -> R.id.day_1
        }
    }
    
    private fun setNavigationClickListeners(context: Context, views: RemoteViews, widgetId: Int) {
        // Previous month button (left arrow)
        val prevIntent = Intent(context, HijriCalendarWidgetProvider::class.java).apply {
            action = ACTION_PREVIOUS_MONTH
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        val prevPendingIntent = PendingIntent.getBroadcast(
            context,
            widgetId * 2, // Unique request code
            prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.prev_month_button, prevPendingIntent)
        
        // Next month button (right arrow)
        val nextIntent = Intent(context, HijriCalendarWidgetProvider::class.java).apply {
            action = ACTION_NEXT_MONTH
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        val nextPendingIntent = PendingIntent.getBroadcast(
            context,
            widgetId * 2 + 1, // Unique request code
            nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.next_month_button, nextPendingIntent)
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            ACTION_PREVIOUS_MONTH -> {
                Log.d(TAG, "Previous month button clicked")
                handleMonthNavigation(context, -1)
            }
            ACTION_NEXT_MONTH -> {
                Log.d(TAG, "Next month button clicked")
                handleMonthNavigation(context, 1)
            }
            ACTION_DAY_CLICKED -> {
                val dayNumber = intent.getIntExtra("day_number", 0)
                Log.d(TAG, "Day $dayNumber clicked")
                handleDayClick(context, dayNumber)
            }
        }
    }
    
    private fun handleDayClick(context: Context, dayNumber: Int) {
        try {
            Log.d(TAG, "Handling day click: $dayNumber")
            
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val monthOffset = prefs.getString("hijri_month_offset", "0")?.toIntOrNull() ?: 0
            
            // Trigger background callback to update date display
            val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("hijriCalendar://dayClick?day=$dayNumber&offset=$monthOffset")
            )
            backgroundIntent.send()
        } catch (e: Exception) {
            Log.e(TAG, "Error handling day click", e)
        }
    }
    
    private fun handleMonthNavigation(context: Context, direction: Int) {
        try {
            // Get shared preferences
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            
            // Get current offset
            val currentOffset = prefs.getString("hijri_month_offset", "0")?.toIntOrNull() ?: 0
            val newOffset = currentOffset + direction
            
            Log.d(TAG, "Navigating from offset $currentOffset to $newOffset")
            
            // Trigger background work using BackgroundIntent
            val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("hijriCalendar://navigate?offset=$newOffset")
            )
            backgroundIntent.send()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error handling month navigation", e)
        }
    }
    
    companion object {
        private const val TAG = "HijriCalendarWidget"
        private const val ACTION_PREVIOUS_MONTH = "com.bloom.wadhakir.ACTION_PREVIOUS_MONTH"
        private const val ACTION_NEXT_MONTH = "com.bloom.wadhakir.ACTION_NEXT_MONTH"
        private const val ACTION_UPDATE_MONTH = "com.bloom.wadhakir.ACTION_UPDATE_MONTH"
        private const val ACTION_DAY_CLICKED = "com.bloom.wadhakir.ACTION_DAY_CLICKED"
    }
}
