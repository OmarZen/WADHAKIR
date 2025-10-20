import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';

class PrayerTimesHomeWidget {
  static const String appWidgetProviderClass =
      'com.bloom.wadhakir.PrayerTimesWidgetProvider';

  static Future<void> updatePrayerTimes(PrayerTimesModel prayerTimes) async {
    try {
      final jsonData = jsonEncode(prayerTimes.toJson());
      debugPrint('Saving prayer times data to widget: $jsonData');

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

      await HomeWidget.updateWidget(
        androidName: appWidgetProviderClass,
        iOSName: 'PrayerTimesWidget',
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
          // Update the widget with the saved data
          await HomeWidget.updateWidget(
            androidName: appWidgetProviderClass,
            iOSName: 'PrayerTimesWidget',
          );
        }
      }
    } catch (e) {
      debugPrint('Error in background callback: $e');
    }
  }
}
