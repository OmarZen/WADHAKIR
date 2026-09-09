import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';
import 'package:wadhakir/features/pray_times/services/prayer_notification_content.dart';
import 'package:wadhakir/features/pray_times/services/prayer_schedule_planner.dart';

/// The Makkah Fajr adhan, as the settings model stores it: the Flutter asset
/// path, which `AdhanSounds.byAssetPath` resolves back to the option that owns
/// the `res/raw` resource and therefore the channel.
const _makkahFajrAsset = 'assets/adhan_sounds/أذان الفجر - مكه المكرمة.mp3';

PlannedPrayerNotification _planned({
  PlannedPrayer prayer = PlannedPrayer.dhuhr,
  NotificationTiming timing = NotificationTiming.onTime,
  String? customSoundPath,
  bool vibration = true,
  DateTime? prayerTime,
}) {
  final at = prayerTime ?? DateTime(2026, 3, 14, 11, 58);
  final lead = PrayerSchedulePlanner.leadTimeFor(timing);
  return PlannedPrayerNotification(
    id: PrayerSchedulePlanner.idFor(prayer, 0),
    prayer: prayer,
    day: DateTime(at.year, at.month, at.day),
    dayIndex: 0,
    prayerTime: at,
    fireTime: at.subtract(lead),
    settings: PrayerNotificationSettings(
      enabled: true,
      timing: timing,
      sound: NotificationSound.defaultSound,
      vibration: vibration,
      customSoundPath: customSoundPath,
    ),
  );
}

void main() {
  group('channel resolution', () {
    test('a chosen adhan routes to that sound\'s own channel', () {
      // The mp3 is baked into the channel at creation, which is what lets the
      // OS play the right adhan with no app process alive.
      final content = PrayerNotificationContent.of(
        _planned(prayer: PlannedPrayer.fajr, customSoundPath: _makkahFajrAsset),
      );

      expect(content.channelKey, 'adhan_adhan_fajr_makkah_v1');
      expect(content.useCustomAdhan, isTrue);
      expect(content.androidRawRes, 'adhan_fajr_makkah');
    });

    test('the default sound splits Fajr from the other four', () {
      // Two channels, not one, so Fajr's importance and vibration can diverge
      // later without touching the rest.
      expect(
        PrayerNotificationContent.of(
          _planned(prayer: PlannedPrayer.fajr),
        ).channelKey,
        PrayerNotificationContent.fajrDefaultChannelKey,
      );
      expect(
        PrayerNotificationContent.of(
          _planned(prayer: PlannedPrayer.asr),
        ).channelKey,
        PrayerNotificationContent.prayersDefaultChannelKey,
      );
    });

    test('an unknown asset path degrades to the default beep', () {
      // A stale settings blob naming an adhan that shipped out of the app must
      // not resolve to a channel that was never created — a notification on a
      // missing channel is dropped by Android entirely.
      final content = PrayerNotificationContent.of(
        _planned(customSoundPath: 'assets/adhan_sounds/deleted.mp3'),
      );

      expect(
        content.channelKey,
        PrayerNotificationContent.prayersDefaultChannelKey,
      );
      expect(content.useCustomAdhan, isFalse);
    });
  });

  group('lead-time copy', () {
    test('on time says nothing', () {
      expect(PrayerNotificationContent.leadTimeText(Duration.zero), '');
    });

    test('counts 3-10 with the plural and 11+ with the singular', () {
      // Arabic number agreement. 5 and 10 take دقائق, 15 takes دقيقة — get this
      // backwards and every early adhan reads as broken Arabic.
      expect(
        PrayerNotificationContent.leadTimeText(const Duration(minutes: 5)),
        ' (بعد 5 دقائق)',
      );
      expect(
        PrayerNotificationContent.leadTimeText(const Duration(minutes: 10)),
        ' (بعد 10 دقائق)',
      );
      expect(
        PrayerNotificationContent.leadTimeText(const Duration(minutes: 15)),
        ' (بعد 15 دقيقة)',
      );
    });

    test('the title carries the lead time and the prayer name', () {
      final content = PrayerNotificationContent.of(
        _planned(
          prayer: PlannedPrayer.maghrib,
          timing: NotificationTiming.before10Min,
        ),
      );

      expect(content.title, '🕌 حان وقت صلاة المغرب (بعد 10 دقائق)');
    });
  });

  group('body', () {
    test('shows the prayer time, not the fire time', () {
      // The user is told when the prayer is. An early notification that
      // announced its own fire time would be telling them the wrong minute.
      final content = PrayerNotificationContent.of(
        _planned(
          prayerTime: DateTime(2026, 3, 14, 17, 56),
          timing: NotificationTiming.before15Min,
        ),
      );

      expect(content.body, contains('5:56 مساءً'));
    });

    test('appends the location only when there is one', () {
      final at = DateTime(2026, 3, 14, 4, 41);
      expect(
        PrayerNotificationContent.bodyText(at, 'القاهرة'),
        '4:41 صباحاً • القاهرة',
      );
      expect(PrayerNotificationContent.bodyText(at, null), '4:41 صباحاً');
      expect(PrayerNotificationContent.bodyText(at, ''), '4:41 صباحاً');
    });

    test('formats the two clock edges the 12-hour rule gets wrong', () {
      // Midnight and noon are the cases a naive `hour % 12` renders as "0".
      expect(
        PrayerNotificationContent.formatTime(DateTime(2026, 3, 14, 0, 5)),
        '12:05 صباحاً',
      );
      expect(
        PrayerNotificationContent.formatTime(DateTime(2026, 3, 14, 12, 0)),
        '12:00 مساءً',
      );
      expect(
        PrayerNotificationContent.formatTime(DateTime(2026, 3, 14, 13, 7)),
        '1:07 مساءً',
      );
    });
  });

  group('tap payload', () {
    test('carries the fire time separately from the prayer time', () {
      // The app-open replay guard compares against 'fireTime'. Collapsing the
      // two would make every before-prayer adhan look stale on open and be
      // suppressed.
      final content = PrayerNotificationContent.of(
        _planned(
          prayer: PlannedPrayer.isha,
          prayerTime: DateTime(2026, 3, 14, 19, 14),
          timing: NotificationTiming.before5Min,
        ),
      );

      expect(content.payload['type'], 'prayer');
      expect(content.payload['prayer'], 'Isha');
      expect(
        content.payload['time'],
        DateTime(2026, 3, 14, 19, 14).toIso8601String(),
      );
      expect(
        content.payload['fireTime'],
        DateTime(2026, 3, 14, 19, 9).toIso8601String(),
      );
    });

    test('identifies the prayer by key, never by its Arabic name', () {
      // Scheduling used to branch on the display string; a translation edit
      // would have broken which prayer was armed, not just its label.
      for (final prayer in PlannedPrayer.values) {
        final content = PrayerNotificationContent.of(_planned(prayer: prayer));
        expect(content.payload['prayer'], prayer.key);
      }
    });
  });
}
