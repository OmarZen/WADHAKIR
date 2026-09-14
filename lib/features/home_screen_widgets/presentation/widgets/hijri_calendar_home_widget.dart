import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:syncfusion_flutter_core/core.dart';

@pragma('vm:entry-point')
class HijriCalendarHomeWidget {
  static const String widgetProvider = 'HijriCalendarWidgetProvider';
  static const String _monthOffsetKey = 'hijri_month_offset';
  static const String _cacheKey = 'hijri_month_cache';

  /// Pre-compute a window of Hijri months around today and store them as a
  /// single JSON blob under [_cacheKey]. The native widget reads this cache to
  /// switch months instantly on arrow taps — no Flutter background isolate
  /// round-trip, so month scrolling is smooth with no flashing.
  @pragma('vm:entry-point')
  static Future<void> cacheCalendarWindow({int radius = 24}) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return;
    try {
      final hijriToday = HijriDateTime.fromDateTime(DateTime.now());
      final Map<String, dynamic> cache = {};
      for (int offset = -radius; offset <= radius; offset++) {
        cache[offset.toString()] = _computeMonth(hijriToday, offset);
      }
      await HomeWidget.saveWidgetData(_cacheKey, jsonEncode(cache));
      debugPrint('🗓️  Cached Hijri months for offsets -$radius..$radius');
    } catch (e) {
      debugPrint('❌ Error caching Hijri calendar window: $e');
    }
  }

  /// Compute one month's grid metadata for [monthOffset] relative to today.
  /// Stores day-1's Gregorian date so the native side can derive any clicked
  /// day's Gregorian date by adding (day - 1) days — no Hijri math in Kotlin.
  @pragma('vm:entry-point')
  static Map<String, dynamic> _computeMonth(
    HijriDateTime hijriToday,
    int monthOffset,
  ) {
    int targetYear = hijriToday.year;
    int targetMonth = hijriToday.month + monthOffset;
    while (targetMonth > 12) {
      targetMonth -= 12;
      targetYear++;
    }
    while (targetMonth < 1) {
      targetMonth += 12;
      targetYear--;
    }

    final displayMonth = HijriDateTime(targetYear, targetMonth, 1);

    // Hijri months are 29 or 30 days. Creating day 30 throws on a 29-day month.
    int daysInMonth = 30;
    try {
      HijriDateTime(displayMonth.year, displayMonth.month, 30);
      daysInMonth = 30;
    } catch (_) {
      daysInMonth = 29;
    }

    final firstDayGregorian = displayMonth.toDateTime();
    // 0 = Sunday column, 1 = Monday, ... 6 = Saturday.
    final firstDayOffset = firstDayGregorian.weekday % 7;

    final todayDay =
        (monthOffset == 0 &&
            hijriToday.month == displayMonth.month &&
            hijriToday.year == displayMonth.year)
        ? hijriToday.day
        : 0;

    return {
      'monthYear':
          '${_getHijriMonthName(displayMonth.month)} ${displayMonth.year}',
      'daysInMonth': daysInMonth,
      'firstDayOffset': firstDayOffset,
      'todayDay': todayDay,
      'hMonth': displayMonth.month,
      'hYear': displayMonth.year,
      'gYear': firstDayGregorian.year,
      'gMonth': firstDayGregorian.month,
      'gDay': firstDayGregorian.day,
    };
  }

  /// Update the Hijri calendar widget for today's month (offset 0 by default).
  /// Also refreshes the month-window cache used by native navigation.
  @pragma('vm:entry-point')
  static Future<void> updateCalendar([int monthOffset = 0]) async {
    // Skip on Windows/Desktop - home_widget not supported
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      debugPrint(
        '⏭️  Skipping Hijri calendar widget update (not supported on desktop)',
      );
      return;
    }

    try {
      // Refresh the month cache so native arrow navigation always has data.
      await cacheCalendarWindow();

      final today = DateTime.now();
      final hijriToday = HijriDateTime.fromDateTime(today);
      final month = _computeMonth(hijriToday, monthOffset);

      // Snap the widget back to the requested (usually current) month and
      // clear any stale day selection.
      await HomeWidget.saveWidgetData(_monthOffsetKey, monthOffset.toString());
      await HomeWidget.saveWidgetData('selected_day', '0');

      // Month grid metadata (also serves as a first-paint fallback when the
      // JSON cache hasn't been read yet).
      await HomeWidget.saveWidgetData('hijri_month_year', month['monthYear']);
      await HomeWidget.saveWidgetData(
        'days_in_month',
        month['daysInMonth'].toString(),
      );
      await HomeWidget.saveWidgetData(
        'first_day_offset',
        month['firstDayOffset'].toString(),
      );
      await HomeWidget.saveWidgetData(
        'today_day',
        month['todayDay'].toString(),
      );

      // Header date card shows today's date.
      final hijriDateDisplay =
          '${hijriToday.day} ${_getHijriMonthName(hijriToday.month)}';
      final gregorianDateDisplay = _formatGregorianDate(today);
      await HomeWidget.saveWidgetData('hijri_date_display', hijriDateDisplay);
      await HomeWidget.saveWidgetData(
        'gregorian_date_display',
        gregorianDateDisplay,
      );

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
}
