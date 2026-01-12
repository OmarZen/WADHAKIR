import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:syncfusion_flutter_core/core.dart';

@pragma('vm:entry-point')
class HijriCalendarHomeWidget {
  static const String widgetProvider = 'HijriCalendarWidgetProvider';
  static const String _monthOffsetKey = 'hijri_month_offset';

  /// Update the Hijri calendar widget with today's date and month calendar
  @pragma('vm:entry-point')
  static Future<void> updateCalendar([int monthOffset = 0]) async {
    // Skip on Windows/Desktop - home_widget not supported
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      debugPrint(
          '⏭️  Skipping Hijri calendar widget update (not supported on desktop)');
      return;
    }

    try {
      final today = DateTime.now();
      final hijriToday = HijriDateTime.fromDateTime(today);

      // Calculate target month based on offset
      int targetYear = hijriToday.year;
      int targetMonth = hijriToday.month + monthOffset;

      // Handle year boundaries
      while (targetMonth > 12) {
        targetMonth -= 12;
        targetYear++;
      }
      while (targetMonth < 1) {
        targetMonth += 12;
        targetYear--;
      }

      final displayMonth = HijriDateTime(targetYear, targetMonth, 1);

      debugPrint('🕌 Updating Hijri calendar widget');
      debugPrint(
          '   Today: ${hijriToday.day} ${_getHijriMonthName(hijriToday.month)} ${hijriToday.year} هـ');
      debugPrint(
          '   Display Month: ${_getHijriMonthName(displayMonth.month)} ${displayMonth.year} (offset: $monthOffset)');

      // Save month offset
      await HomeWidget.saveWidgetData(_monthOffsetKey, monthOffset.toString());

      // Calculate month details - Hijri months are either 29 or 30 days
      // Calculate by checking the last day of the month
      int daysInMonth = 30;
      try {
        // Try to create day 30 of this month
        HijriDateTime(displayMonth.year, displayMonth.month, 30);
        daysInMonth = 30;
      } catch (e) {
        // If day 30 fails, the month has 29 days
        daysInMonth = 29;
      }

      // Calculate first day offset (which day of week the month starts)
      final firstDayOfMonth =
          HijriDateTime(displayMonth.year, displayMonth.month, 1);
      final firstDayGregorian = firstDayOfMonth.toDateTime();
      final firstDayOffset =
          firstDayGregorian.weekday % 7; // 0 = Sunday, 1 = Monday, etc.

      // Check if today is in this displayed month
      final todayDay = (monthOffset == 0 &&
              hijriToday.month == displayMonth.month &&
              hijriToday.year == displayMonth.year)
          ? hijriToday.day
          : 0; // 0 means no highlight

      debugPrint('   Days in month: $daysInMonth');
      debugPrint('   First day offset: $firstDayOffset');
      debugPrint('   Today highlight: $todayDay');

      // Save month/year
      final monthYear =
          '${_getHijriMonthName(displayMonth.month)} ${displayMonth.year}';
      await HomeWidget.saveWidgetData('hijri_month_year', monthYear);

      // Save calendar data
      await HomeWidget.saveWidgetData('days_in_month', daysInMonth.toString());
      await HomeWidget.saveWidgetData(
          'first_day_offset', firstDayOffset.toString());
      await HomeWidget.saveWidgetData('today_day', todayDay.toString());

      // Save formatted date displays
      final hijriDateDisplay =
          '${hijriToday.day} ${_getHijriMonthName(hijriToday.month)}';
      final gregorianDateDisplay = _formatGregorianDate(today);

      await HomeWidget.saveWidgetData('hijri_date_display', hijriDateDisplay);
      await HomeWidget.saveWidgetData(
          'gregorian_date_display', gregorianDateDisplay);

      debugPrint('   Hijri display: $hijriDateDisplay');
      debugPrint('   Gregorian display: $gregorianDateDisplay');

      // Update the widget
      await HomeWidget.updateWidget(
        androidName: widgetProvider,
        iOSName: 'HijriCalendarWidget',
        qualifiedAndroidName: 'com.bloom.wadhakir.$widgetProvider',
      );

      debugPrint('✅ Hijri calendar widget updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating Hijri calendar widget: $e');
    }
  }

  @pragma('vm:entry-point')
  static String _getHijriMonthName(int month) {
    const months = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الثاني',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
    return month >= 1 && month <= 12 ? months[month - 1] : '';
  }

  @pragma('vm:entry-point')
  static String _formatGregorianDate(DateTime date) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  /// Navigate to previous month
  @pragma('vm:entry-point')
  static Future<void> previousMonth() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return;

    try {
      // Get current offset
      final currentOffset =
          await HomeWidget.getWidgetData<String>(_monthOffsetKey);
      final offset = int.tryParse(currentOffset ?? '0') ?? 0;

      // Move to previous month (increase offset)
      await updateCalendar(offset - 1);
      debugPrint('📅 Navigated to previous month (offset: ${offset - 1})');
    } catch (e) {
      debugPrint('❌ Error navigating to previous month: $e');
    }
  }

  /// Navigate to next month
  @pragma('vm:entry-point')
  static Future<void> nextMonth() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return;

    try {
      // Get current offset
      final currentOffset =
          await HomeWidget.getWidgetData<String>(_monthOffsetKey);
      final offset = int.tryParse(currentOffset ?? '0') ?? 0;

      // Move to next month (decrease offset)
      await updateCalendar(offset + 1);
      debugPrint('📅 Navigated to next month (offset: ${offset + 1})');
    } catch (e) {
      debugPrint('❌ Error navigating to next month: $e');
    }
  }

  /// Background callback for widget interactions
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri == null) return;

    debugPrint('📱 Widget background callback triggered: $uri');

    // Handle month navigation
    final offsetStr = uri.queryParameters['offset'];
    if (offsetStr != null && uri.queryParameters['day'] == null) {
      final offset = int.tryParse(offsetStr) ?? 0;
      debugPrint('🔄 Updating calendar with offset: $offset');

      // Clear selected day when navigating months
      await HomeWidget.saveWidgetData('selected_day', '0');
      await updateCalendar(offset);
      return;
    }

    // Handle day click
    final dayStr = uri.queryParameters['day'];
    if (dayStr != null) {
      final day = int.tryParse(dayStr) ?? 0;
      final offset = int.tryParse(offsetStr ?? '0') ?? 0;
      debugPrint('📅 Day clicked: $day with offset: $offset');
      await handleDayClickWithOffset(day, offset);
      return;
    }
  }

  /// Handle day click to update the date card with specific offset
  @pragma('vm:entry-point')
  static Future<void> handleDayClickWithOffset(int day, int offset) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return;

    try {
      final today = DateTime.now();
      final hijriToday = HijriDateTime.fromDateTime(today);

      // Calculate display month using the provided offset
      int targetYear = hijriToday.year;
      int targetMonth = hijriToday.month + offset;

      while (targetMonth > 12) {
        targetMonth -= 12;
        targetYear++;
      }
      while (targetMonth < 1) {
        targetMonth += 12;
        targetYear--;
      }

      // Create the clicked date
      final clickedHijriDate = HijriDateTime(targetYear, targetMonth, day);
      final clickedGregorianDate = clickedHijriDate.toDateTime();

      // Update date displays
      final hijriDateDisplay = '$day ${_getHijriMonthName(targetMonth)}';
      final gregorianDateDisplay = _formatGregorianDate(clickedGregorianDate);

      await HomeWidget.saveWidgetData('hijri_date_display', hijriDateDisplay);
      await HomeWidget.saveWidgetData(
          'gregorian_date_display', gregorianDateDisplay);

      // Save selected day for highlighting
      await HomeWidget.saveWidgetData('selected_day', day.toString());

      debugPrint(
          '   Updated date display: $hijriDateDisplay • $gregorianDateDisplay');

      // Update the widget
      await HomeWidget.updateWidget(
        androidName: widgetProvider,
        iOSName: 'HijriCalendarWidget',
        qualifiedAndroidName: 'com.bloom.wadhakir.$widgetProvider',
      );

      debugPrint('✅ Date card updated for day $day');
    } catch (e) {
      debugPrint('❌ Error handling day click: $e');
    }
  }

  /// Setup background callback handler
  @pragma('vm:entry-point')
  static Future<void> setupBackgroundCallback() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return;

    await HomeWidget.setAppGroupId('com.bloom.wadhakir');
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }
}
