import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/data/repositories/prayer_times_repository_impl.dart';

class PrayerTimesHomeWidget {
  static const String compactWidgetProvider = 'PrayerTimesWidgetProvider';
  static const String listWidgetProvider = 'PrayerTimesListWidgetProvider';
  static const String newListWidgetProvider =
      'PrayerTimesListWidgetProviderNew';

  static Future<void> updatePrayerTimes(PrayerTimesModel prayerTimes) async {
    // Skip on Windows/Desktop - home_widget not supported
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      debugPrint('⏭️ Skipping home widget update (not supported on desktop)');
      return;
    }

    try {
      final jsonData = jsonEncode(prayerTimes.toJson());
      debugPrint('Saving prayer times data to widget: $jsonData');

      // 1. Save Raw and Individual Prayer Times
      await HomeWidget.saveWidgetData('prayer_times', jsonData);
      await HomeWidget.saveWidgetData(
          'fajr', prayerTimes.formatTime(prayerTimes.fajr));
      await HomeWidget.saveWidgetData(
          'dhuhr', prayerTimes.formatTime(prayerTimes.dhuhr));
      await HomeWidget.saveWidgetData(
          'asr', prayerTimes.formatTime(prayerTimes.asr));
      await HomeWidget.saveWidgetData(
          'maghrib', prayerTimes.formatTime(prayerTimes.maghrib));
      await HomeWidget.saveWidgetData(
          'isha', prayerTimes.formatTime(prayerTimes.isha));

      // Save epoch timestamps for all prayers so the widget can compute the
      // next prayer live (without relying on pre-computed nextPrayerName)
      await HomeWidget.saveWidgetData(
          'fajrTimestamp', prayerTimes.fajr.millisecondsSinceEpoch);
      await HomeWidget.saveWidgetData(
          'dhuhrTimestamp', prayerTimes.dhuhr.millisecondsSinceEpoch);
      await HomeWidget.saveWidgetData(
          'asrTimestamp', prayerTimes.asr.millisecondsSinceEpoch);
      await HomeWidget.saveWidgetData(
          'maghribTimestamp', prayerTimes.maghrib.millisecondsSinceEpoch);
      await HomeWidget.saveWidgetData(
          'ishaTimestamp', prayerTimes.isha.millisecondsSinceEpoch);

      // 2. Save current location
      try {
        final repository = PrayerTimesRepositoryImpl();
        final location = await repository.getCurrentLocationName();
        await HomeWidget.saveWidgetData('location', location);
      } catch (e) {
        await HomeWidget.saveWidgetData('location', 'Location unavailable');
      }

      // 3. Save current date (both Gregorian and Hijri)
      final now = DateTime.now();
      final arabicMonths = [
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
        'ديسمبر'
      ];
      final arabicDays = [
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
        'الأحد'
      ];

      final gregorianDateFormatted =
          '${now.day} ${arabicMonths[now.month - 1]}';
      final dayName = arabicDays[now.weekday - 1];

      await HomeWidget.saveWidgetData('gregorian_date', gregorianDateFormatted);
      await HomeWidget.saveWidgetData('day_name', dayName);

      try {
        final hijriDate = _calculateHijriDate(now);
        await HomeWidget.saveWidgetData('hijri_date', hijriDate);
      } catch (e) {
        await HomeWidget.saveWidgetData('hijri_date', '');
      }

      // 4. Calculate Current and Next Prayer
      DateTime? nextPrayerTime;
      String? nextPrayerName;
      String? currentPrayerName;

      final prayers = [
        {'name': 'Fajr', 'time': prayerTimes.fajr},
        {'name': 'Dhuhr', 'time': prayerTimes.dhuhr},
        {'name': 'Asr', 'time': prayerTimes.asr},
        {'name': 'Maghrib', 'time': prayerTimes.maghrib},
        {'name': 'Isha', 'time': prayerTimes.isha},
      ];

      for (int i = 0; i < prayers.length; i++) {
        if (now.isBefore(prayers[i]['time'] as DateTime)) {
          nextPrayerTime = prayers[i]['time'] as DateTime;
          nextPrayerName = prayers[i]['name'] as String;
          if (i > 0) {
            currentPrayerName = prayers[i - 1]['name'] as String;
          } else {
            // If before Fajr, current is Isha of yesterday
            currentPrayerName = 'Isha';
          }
          break;
        }
      }

      // After Isha case
      if (nextPrayerTime == null) {
        nextPrayerTime = prayerTimes.fajr.add(const Duration(days: 1));
        nextPrayerName = 'Fajr';
        currentPrayerName = 'Isha';
      }
      // 5. Save Logic for the "Pill" and "Chronometer"
      // currentPrayer is saved in uppercase (e.g., 'ASR') for the Kotlin Map
      await HomeWidget.saveWidgetData(
          'currentPrayer', currentPrayerName?.toUpperCase() ?? '');

      // nextPrayerName is used for the "Asr in %s" format
      await HomeWidget.saveWidgetData('nextPrayerName', nextPrayerName);

      // nextPrayerTimestamp is used for the ticking Chronometer
      await HomeWidget.saveWidgetData(
          'nextPrayerTimestamp', nextPrayerTime.millisecondsSinceEpoch);

      // 6. Update all Widget Providers
      final providers = [
        compactWidgetProvider,
        listWidgetProvider,
        newListWidgetProvider
      ];

      for (var provider in providers) {
        await HomeWidget.updateWidget(
          androidName: provider,
          qualifiedAndroidName: 'com.bloom.wadhakir.$provider',
        );
      }

      debugPrint('✅ All widgets updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating widget: $e');
    }
  }

  static Future<void> setupBackgroundCallback() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return;
    try {
      await HomeWidget.setAppGroupId('group.com.bloom.wadhakir');
      await HomeWidget.registerInteractivityCallback(backgroundCallback);
    } catch (e) {
      debugPrint('Error setting up home widget: $e');
    }
  }

  static Future<void> backgroundCallback(Uri? uri) async {
    try {
      if (uri?.host == 'updatewidget') {
        final prayerTimesJson =
            await HomeWidget.getWidgetData<String>('prayer_times');
        if (prayerTimesJson != null) {
          // Re-trigger the update logic with existing data if needed
          await HomeWidget.updateWidget(androidName: compactWidgetProvider);
          await HomeWidget.updateWidget(androidName: listWidgetProvider);
          await HomeWidget.updateWidget(androidName: newListWidgetProvider);
        }
      }
    } catch (e) {
      debugPrint('Error in background callback: $e');
    }
  }

  static String _calculateHijriDate(DateTime gregorian) {
    try {
      // Import required for Hijri calculations
      // Using syncfusion_flutter_core which is already in pubspec
      final hijri = HijriDateTime.fromDateTime(gregorian);
      final hijriMonths = [
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
      return '${hijri.day} ${hijriMonths[hijri.month - 1]}';
    } catch (e) {
      debugPrint('Error in Hijri calculation: $e');
      return '';
    }
  }
}
