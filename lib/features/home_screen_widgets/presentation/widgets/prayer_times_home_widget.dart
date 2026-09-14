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
  static const String clockWidgetProvider = 'GlassClockWidgetProvider';

  static String _arabicPrayerName(String? englishName) {
    switch (englishName) {
      case 'Fajr':
        return 'الفجر';
      case 'Dhuhr':
        return 'الظهر';
      case 'Asr':
        return 'العصر';
      case 'Maghrib':
        return 'المغرب';
      case 'Isha':
        return 'العشاء';
      default:
        return englishName ?? '';
    }
  }

  static Future<void> updatePrayerTimes(PrayerTimesModel prayerTimes) async {
    // Skip on Windows/Desktop - home_widget not supported
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      debugPrint('⏭️  Skipping home widget update (not supported on desktop)');
      return;
    }

    try {
      final jsonData = jsonEncode(prayerTimes.toJson());
      debugPrint('Saving prayer times data to widget: $jsonData');

      // Save raw prayer times data
      await HomeWidget.saveWidgetData('prayer_times', jsonData);

      // Save formatted prayer times
      await HomeWidget.saveWidgetData(
        'fajr',
        prayerTimes.formatTime(prayerTimes.fajr),
      );
      await HomeWidget.saveWidgetData(
        'dhuhr',
        prayerTimes.formatTime(prayerTimes.dhuhr),
      );
      await HomeWidget.saveWidgetData(
        'asr',
        prayerTimes.formatTime(prayerTimes.asr),
      );
      await HomeWidget.saveWidgetData(
        'maghrib',
        prayerTimes.formatTime(prayerTimes.maghrib),
      );
      await HomeWidget.saveWidgetData(
        'isha',
        prayerTimes.formatTime(prayerTimes.isha),
      );

      // Save current location
      try {
        final repository = PrayerTimesRepositoryImpl();
        final location = await repository.getCurrentLocationName();
        await HomeWidget.saveWidgetData('location', location);
      } catch (e) {
        debugPrint('Error getting location: $e');
        await HomeWidget.saveWidgetData('location', 'Location unavailable');
      }

      // Save current date (both Gregorian and Hijri)
      final now = DateTime.now();
      final gregorianDate = '${now.day}/${now.month}/${now.year}';
      await HomeWidget.saveWidgetData('date', gregorianDate);

      // Save formatted dates for list widget
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
        'ديسمبر',
      ];
      final arabicDays = [
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
        'الأحد',
      ];

      final gregorianDateFormatted =
          '${now.day} ${arabicMonths[now.month - 1]}';
      final dayName = arabicDays[now.weekday - 1];

      await HomeWidget.saveWidgetData('gregorian_date', gregorianDateFormatted);
      await HomeWidget.saveWidgetData('day_name', dayName);

      // Calculate and save Hijri date
      try {
        final hijriDate = _calculateHijriDate(now);
        await HomeWidget.saveWidgetData('hijri_date', hijriDate);
      } catch (e) {
        debugPrint('Error calculating Hijri date: $e');
        await HomeWidget.saveWidgetData('hijri_date', '');
      }

      // Calculate current and next prayer
      DateTime? nextPrayerTime;
      String? nextPrayerName;
      String? currentPrayerName;
      String? currentPrayerTime;

      final prayers = [
        {'name': 'Fajr', 'time': prayerTimes.fajr},
        {'name': 'Dhuhr', 'time': prayerTimes.dhuhr},
        {'name': 'Asr', 'time': prayerTimes.asr},
        {'name': 'Maghrib', 'time': prayerTimes.maghrib},
        {'name': 'Isha', 'time': prayerTimes.isha},
      ];

      // Find current and next prayer
      for (int i = 0; i < prayers.length; i++) {
        if (now.isBefore(prayers[i]['time'] as DateTime)) {
          nextPrayerTime = prayers[i]['time'] as DateTime;
          nextPrayerName = prayers[i]['name'] as String;

          if (i > 0) {
            currentPrayerName = prayers[i - 1]['name'] as String;
            currentPrayerTime = prayerTimes.formatTime(
              prayers[i - 1]['time'] as DateTime,
            );
          }
          break;
        }
      }

      // If no next prayer found, it means we're after Isha
      if (nextPrayerTime == null) {
        nextPrayerTime = prayerTimes.fajr.add(const Duration(days: 1));
        nextPrayerName = 'Fajr';
        currentPrayerName = 'Isha';
        currentPrayerTime = prayerTimes.formatTime(prayerTimes.isha);
      }

      // Save current and next prayer info
      await HomeWidget.saveWidgetData(
        'currentPrayer',
        currentPrayerName?.toUpperCase() ?? '',
      );
      await HomeWidget.saveWidgetData(
        'currentPrayerTime',
        currentPrayerTime ?? '',
      );
      await HomeWidget.saveWidgetData(
        'nextPrayer',
        nextPrayerName?.toUpperCase() ?? '',
      );

      // Calculate and save time until next prayer
      final remaining = nextPrayerTime.difference(now);
      final timeUntilNext =
          '${remaining.inHours}h ${remaining.inMinutes % 60}m';
      await HomeWidget.saveWidgetData('timeUntilNext', timeUntilNext);

      // Next-prayer epoch + Arabic name for the live clock widget's
      // self-ticking countdown chronometer.
      await HomeWidget.saveWidgetData(
        'nextPrayerEpoch',
        nextPrayerTime.millisecondsSinceEpoch.toString(),
      );
      await HomeWidget.saveWidgetData(
        'nextPrayerArabic',
        _arabicPrayerName(nextPrayerName),
      );

      // Update compact widget
      await HomeWidget.updateWidget(
        androidName: compactWidgetProvider,
        iOSName: 'PrayerTimesWidget',
        qualifiedAndroidName: 'com.bloom.wadhakir.$compactWidgetProvider',
      );

      // Update list widget
      await HomeWidget.updateWidget(
        androidName: listWidgetProvider,
        iOSName: 'PrayerTimesListWidget',
        qualifiedAndroidName: 'com.bloom.wadhakir.$listWidgetProvider',
      );

      // Update live clock widget
      await HomeWidget.updateWidget(
        androidName: clockWidgetProvider,
        iOSName: 'GlassClockWidget',
        qualifiedAndroidName: 'com.bloom.wadhakir.$clockWidgetProvider',
      );
      debugPrint('Widget update completed successfully');
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  static Future<void> setupBackgroundCallback() async {
    // Skip on Windows/Desktop - home_widget not supported
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      debugPrint('⏭️  Skipping home widget setup (not supported on desktop)');
      return;
    }

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
        // Retrieve the saved prayer times
        final prayerTimesJson = await HomeWidget.getWidgetData<String>(
          'prayer_times',
        );
        if (prayerTimesJson != null) {
          // Update both widgets with the saved data
          await HomeWidget.updateWidget(
            androidName: compactWidgetProvider,
            iOSName: 'PrayerTimesWidget',
          );
          await HomeWidget.updateWidget(
            androidName: listWidgetProvider,
            iOSName: 'PrayerTimesListWidget',
          );
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
