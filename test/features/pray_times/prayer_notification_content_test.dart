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
  bool overrideSilentMode = true,
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
      overrideSilentMode: overrideSilentMode,
    ),
  );
}

void main() {
  group('channel resolution', () {
    test('every prayer but Fajr shares one channel, whatever the adhan', () {
      // Stage 3 collapsed fifteen sounding channels into two silent ones. The
      // channel used to select the sound, because a channel's sound is
      // immutable and that was the only way to offer a choice; the playback
      // service selects it now, so the adhan cannot influence the channel.
      for (final path in <String?>[null, _makkahFajrAsset]) {
        expect(
          PrayerNotificationContent.of(
            _planned(prayer: PlannedPrayer.asr, customSoundPath: path),
          ).channelKey,
          PrayerNotificationContent.adhanChannelKey,
        );
      }
    });

    test('Fajr keeps a channel of its own', () {
      // So its importance, vibration and lock-screen visibility can diverge —
      // by the user today, by a Fajr-only DND bypass later — without another
      // migration.
      expect(
        PrayerNotificationContent.of(
          _planned(
            prayer: PlannedPrayer.fajr,
            customSoundPath: _makkahFajrAsset,
          ),
        ).channelKey,
        PrayerNotificationContent.fajrAdhanChannelKey,
      );
      expect(
        PrayerNotificationContent.of(
          _planned(prayer: PlannedPrayer.fajr),
        ).channelKey,
        PrayerNotificationContent.fajrAdhanChannelKey,
      );
    });

    test('the new keys are not the retired ones', () {
      // A channel's sound is immutable once created, so reusing a `_v1` key
      // would give a channel that still plays its baked mp3 on top of the
      // service — the same adhan twice, out of step, on two volume sliders.
      final live = {
        PrayerNotificationContent.adhanChannelKey,
        PrayerNotificationContent.fajrAdhanChannelKey,
      };
      final retired = {
        PrayerNotificationContent.legacyAdhanChannelKey('adhan_fajr_makkah'),
        PrayerNotificationContent.legacyFajrDefaultChannelKey,
        PrayerNotificationContent.legacyPrayersDefaultChannelKey,
      };

      expect(live.intersection(retired), isEmpty);
    });

    test('the chosen adhan still reaches the wire as a raw resource', () {
      // The channel stopped carrying the sound; this is what carries it now.
      final content = PrayerNotificationContent.of(
        _planned(prayer: PlannedPrayer.fajr, customSoundPath: _makkahFajrAsset),
      );

      expect(content.useCustomAdhan, isTrue);
      expect(content.androidRawRes, 'adhan_fajr_makkah');
    });

    test('an unknown asset path degrades to the system tone', () {
      // A stale settings blob naming an adhan that shipped out of the app must
      // not leave a raw resource name the service cannot resolve.
      final content = PrayerNotificationContent.of(
        _planned(customSoundPath: 'assets/adhan_sounds/deleted.mp3'),
      );

      expect(content.channelKey, PrayerNotificationContent.adhanChannelKey);
      expect(content.useCustomAdhan, isFalse);
      expect(content.androidRawRes, isNull);
    });
  });

  group('the legacy keys the migration depends on', () {
    test('the retired key shape matches what shipped', () {
      // Kotlin rewrites any non-v2 channel on a stored row to one of the new
      // keys, because a ledger written before Stage 3 still names a channel
      // with the mp3 baked in — and that would play the adhan twice, once from
      // the channel and once from the service. Dart is what removes those
      // channels by key, so the two spellings have to be the same.
      expect(
        PrayerNotificationContent.legacyAdhanChannelKey('adhan_makkah_haram'),
        'adhan_adhan_makkah_haram_v1',
      );
      expect(
        PrayerNotificationContent.legacyFajrDefaultChannelKey,
        'fajr_channel_default_sound',
      );
      expect(
        PrayerNotificationContent.legacyPrayersDefaultChannelKey,
        'prayers_channel_default_sound',
      );
    });
  });

  group('silent-mode override', () {
    test('defaults to the alarm-clock behaviour', () {
      expect(PrayerNotificationContent.of(_planned()).overrideSilent, isTrue);
      expect(
        PrayerNotificationSettings.defaultSettings().overrideSilentMode,
        isTrue,
      );
    });

    test('carries the user turning it off', () {
      expect(
        PrayerNotificationContent.of(
          _planned(overrideSilentMode: false),
        ).overrideSilent,
        isFalse,
      );
    });

    test('an install that predates the setting keeps the new default', () {
      // Every existing install has a settings blob with no such key. Reading it
      // as false would silently opt the whole install base OUT of the behaviour
      // the release was built to deliver.
      final restored = PrayerNotificationSettings.fromJson({
        'enabled': true,
        'timing': 0,
        'sound': 0,
        'vibration': true,
        'customSoundPath': null,
      });

      expect(restored.overrideSilentMode, isTrue);
    });

    test('survives a JSON round trip in both positions', () {
      for (final value in [true, false]) {
        final round = PrayerNotificationSettings.fromJson(
          PrayerNotificationSettings.defaultSettings()
              .copyWith(overrideSilentMode: value)
              .toJson(),
        );
        expect(round.overrideSilentMode, value);
      }
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
