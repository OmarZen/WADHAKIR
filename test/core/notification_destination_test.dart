import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/notifications/notification_router.dart';
import 'package:wadhakir/core/routes/app_shell.dart';

NotificationDestination? _for(String type, [String? target]) =>
    NotificationDestination.forPayload({'type': type, 'target': ?target});

void main() {
  group(
    'azkar notifications open the Azkar tab with their category on top',
    () {
      final cases = {
        'azkar_morning': AppConstants.azkarMorningEveningCategory,
        'azkar_evening': AppConstants.azkarMorningEveningCategory,
        'azkar_sleep': AppConstants.azkarSleepCategory,
        'azkar_witr': AppConstants.azkarWitrCategory,
        'azkar_qiyam': AppConstants.azkarWakingCategory,
      };
      for (final MapEntry(key: type, value: title) in cases.entries) {
        test(type, () {
          final destination = _for(type);
          expect(destination, isA<AzkarCategoryDestination>());
          destination as AzkarCategoryDestination;
          expect(destination.tab, AppTab.azkar);
          expect(destination.title, title);
        });
      }

      test('after-prayer adhkar open their own screen over the Azkar tab', () {
        final destination = _for('azkar_after_prayer');
        expect(destination, isA<RouteDestination>());
        destination as RouteDestination;
        expect(destination.tab, AppTab.azkar);
        expect(destination.routeName, AppConstants.afterPrayerAdhkarRoute);
      });
    },
  );

  test('every category a notification can open exists in adhkar.json', () {
    // A renamed category in the data would otherwise turn a tap into "nothing
    // happened" with no error anywhere.
    final data =
        jsonDecode(File('assets/json_data/adhkar.json').readAsStringSync())
            as List<dynamic>;
    final titles = data.map((c) => (c as Map)['category'] as String).toSet();
    for (final title in [
      AppConstants.azkarMorningEveningCategory,
      AppConstants.azkarSleepCategory,
      AppConstants.azkarWitrCategory,
      AppConstants.azkarWakingCategory,
    ]) {
      expect(titles, contains(title));
    }
  });

  test('Al-Kahf opens surah 18 in the Quran tab', () {
    final destination = _for('azkar_kahf');
    expect(destination, isA<QuranSurahDestination>());
    destination as QuranSurahDestination;
    expect(destination.tab, AppTab.quran);
    expect(destination.surah, 18);
  });

  test('the daily inspiration opens Home, where its card is', () {
    final destination = _for('daily_inspiration');
    expect(destination, isA<TabDestination>());
    expect(destination!.tab, AppTab.home);
  });

  test('prayer settings open the Settings tab rather than a bare page', () {
    final destination = _for('feature_nudge', 'open_prayer_settings');
    expect(destination, isA<TabDestination>());
    expect(destination!.tab, AppTab.settings);
  });

  group('screens pushed over Home', () {
    final cases = {
      'prayer': AppConstants.prayerTimesRoute,
      'azkar_duha': AppConstants.prayerTimesRoute,
      'wird_reminder': AppConstants.wirdRoute,
      'open_wird': AppConstants.wirdRoute,
      'open_daily_inspiration': AppConstants.dailyInspirationSettingsRoute,
      'open_azkar_reminders': AppConstants.azkarRemindersSettingsRoute,
      'open_zakat': AppConstants.zakatRoute,
      'open_backgrounds': AppConstants.islamicBackgroundsRoute,
    };
    for (final MapEntry(key: type, value: route) in cases.entries) {
      test(type, () {
        final destination = _for(type);
        expect(destination, isA<RouteDestination>());
        destination as RouteDestination;
        expect(destination.tab, AppTab.home);
        expect(destination.routeName, route);
      });
    }
  });

  test('feature nudges route to the feature they advertise', () {
    final destination = _for('feature_nudge', 'open_zakat');
    expect(destination, isA<RouteDestination>());
    expect(
      (destination! as RouteDestination).routeName,
      AppConstants.zakatRoute,
    );
  });

  test('fasting reminders open the calendar over Home', () {
    for (final type in ['fasting_reminder', 'weekly_fasting', 'open_fasting']) {
      final destination = _for(type);
      expect(destination, isA<FastingCalendarDestination>());
      expect(destination!.tab, AppTab.home);
    }
  });

  test('the reminder floor just opens Home', () {
    expect(_for('reminder_floor'), isA<TabDestination>());
  });

  test('an unknown or missing type opens nothing', () {
    expect(_for('something_new'), isNull);
    expect(NotificationDestination.forPayload(const {}), isNull);
  });
}
