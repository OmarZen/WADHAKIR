import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/data/repositories/prayer_times_repository_impl.dart';

class PrayerTimesHomeWidget {
  static const String compactWidgetProvider = 'PrayerTimesWidgetProvider';
  static const String listWidgetProvider = 'PrayerTimesListWidgetProvider';

  static Future<void> updatePrayerTimes(PrayerTimesModel prayerTimes) async {
    try {
      final jsonData = jsonEncode(prayerTimes.toJson());
      debugPrint('Saving prayer times data to widget: $jsonData');

      // Save raw prayer times data
      await HomeWidget.saveWidgetData('prayer_times', jsonData);

      // Save formatted prayer times
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
            currentPrayerTime =
                prayerTimes.formatTime(prayers[i - 1]['time'] as DateTime);
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
          'currentPrayer', currentPrayerName?.toUpperCase() ?? '');
      await HomeWidget.saveWidgetData(
          'currentPrayerTime', currentPrayerTime ?? '');
      await HomeWidget.saveWidgetData(
          'nextPrayer', nextPrayerName?.toUpperCase() ?? '');

      // Calculate and save time until next prayer
      final remaining = nextPrayerTime.difference(now);
      final timeUntilNext =
          '${remaining.inHours}h ${remaining.inMinutes % 60}m';
      await HomeWidget.saveWidgetData('timeUntilNext', timeUntilNext);

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
      debugPrint('Widget update completed successfully');
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  static Future<void> setupBackgroundCallback() async {
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
        final prayerTimesJson =
            await HomeWidget.getWidgetData<String>('prayer_times');
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
}
