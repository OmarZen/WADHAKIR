import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/time/clock.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';
import 'package:wadhakir/features/pray_times/services/prayer_schedule_planner.dart';

const _planner = PrayerSchedulePlanner();

/// Cairo, mid-March. Real times, because a plan built on 10:00/11:00/12:00
/// would not catch an Isha that lands after midnight or a Fajr that a
/// 15-minute lead time pulls into the previous day.
const _cairoTimes = {
  'Fajr': (4, 41),
  'Dhuhr': (11, 58),
  'Asr': (15, 22),
  'Maghrib': (17, 56),
  'Isha': (19, 14),
};

DateTime _day(int dayOfMarch) => DateTime(2026, 3, dayOfMarch);

Map<DateTime, Map<String, DateTime>> _horizon(
  int days, {
  int startDayOfMarch = 14,
  Map<String, (int, int)> times = _cairoTimes,
}) => {
  for (var i = 0; i < days; i++)
    _day(startDayOfMarch + i): {
      for (final e in times.entries)
        e.key: DateTime(2026, 3, startDayOfMarch + i, e.value.$1, e.value.$2),
    },
};

PrayerNotificationSettings _prayer({
  bool enabled = true,
  NotificationTiming timing = NotificationTiming.onTime,
  String? sound,
  bool vibration = true,
}) => PrayerNotificationSettings(
  enabled: enabled,
  timing: timing,
  sound: NotificationSound.defaultSound,
  vibration: vibration,
  customSoundPath: sound,
);

NotificationSettingsModel _settings({
  bool masterEnabled = true,
  PrayerNotificationSettings? fajr,
  PrayerNotificationSettings? dhuhr,
  PrayerNotificationSettings? asr,
  PrayerNotificationSettings? maghrib,
  PrayerNotificationSettings? isha,
}) {
  final base = NotificationSettingsModel.defaultSettings();
  return base.copyWith(
    masterEnabled: masterEnabled,
    fajrSettings: fajr ?? _prayer(),
    dhuhrSettings: dhuhr ?? _prayer(),
    asrSettings: asr ?? _prayer(),
    maghribSettings: maghrib ?? _prayer(),
    ishaSettings: isha ?? _prayer(),
  );
}

void main() {
  group('what gets planned', () {
    test('a full horizon arms every prayer on every day', () {
      // 04:00 — before Fajr, so nothing today has passed yet.
      final clock = FixedClock(DateTime(2026, 3, 14, 4));

      final plan = _planner.plan(
        prayerTimesByDay: _horizon(7),
        settings: _settings(),
        now: clock.now(),
      );

      expect(plan, hasLength(35));
      expect(plan.map((p) => p.dayIndex).toSet(), {0, 1, 2, 3, 4, 5, 6});
      expect(
        plan.where((p) => p.dayIndex == 0).map((p) => p.prayer).toList(),
        PlannedPrayer.values,
      );
    });

    test('an instant already past is not scheduled', () {
      // Mid-afternoon: Fajr and Dhuhr are gone, Asr onwards remain.
      final plan = _planner.plan(
        prayerTimesByDay: _horizon(1),
        settings: _settings(),
        now: DateTime(2026, 3, 14, 13),
      );

      expect(plan.map((p) => p.prayer).toList(), [
        PlannedPrayer.asr,
        PlannedPrayer.maghrib,
        PlannedPrayer.isha,
      ]);
    });

    test('a prayer due exactly now is skipped, not armed', () {
      // The platform-channel round trip alone puts it in the past, and the OS
      // would either fire it instantly or drop it. Either way it is not a
      // schedule.
      final plan = _planner.plan(
        prayerTimesByDay: _horizon(1),
        settings: _settings(),
        now: DateTime(2026, 3, 14, 15, 22), // Asr, to the minute
      );

      expect(plan.map((p) => p.prayer), isNot(contains(PlannedPrayer.asr)));
      expect(plan.map((p) => p.prayer).toList(), [
        PlannedPrayer.maghrib,
        PlannedPrayer.isha,
      ]);
    });

    test('the master toggle off plans nothing at all', () {
      expect(
        _planner.plan(
          prayerTimesByDay: _horizon(7),
          settings: _settings(masterEnabled: false),
          now: DateTime(2026, 3, 14, 4),
        ),
        isEmpty,
      );
    });

    test('a disabled prayer is dropped on every day, not just today', () {
      // The old code only cancelled a disabled prayer for dayIndex 0, so
      // turning Fajr off left six future Fajr alarms armed.
      final plan = _planner.plan(
        prayerTimesByDay: _horizon(7),
        settings: _settings(fajr: _prayer(enabled: false)),
        now: DateTime(2026, 3, 14, 4),
      );

      expect(plan, hasLength(28));
      expect(plan.map((p) => p.prayer), isNot(contains(PlannedPrayer.fajr)));
    });

    test('a day missing from the map is skipped without shifting the rest', () {
      final horizon = _horizon(3)..remove(_day(15));

      final plan = _planner.plan(
        prayerTimesByDay: horizon,
        settings: _settings(),
        now: DateTime(2026, 3, 14, 4),
      );

      // Two days present, and their indices are consecutive: index is the
      // position in the sorted horizon, not the offset from today.
      expect(plan.map((p) => p.day).toSet(), {_day(14), _day(16)});
      expect(plan.map((p) => p.dayIndex).toSet(), {0, 1});
    });

    test('an empty horizon plans nothing rather than throwing', () {
      expect(
        _planner.plan(
          prayerTimesByDay: const {},
          settings: _settings(),
          now: DateTime(2026, 3, 14, 4),
        ),
        isEmpty,
      );
    });
  });

  group('lead time', () {
    test('a before-prayer choice moves the fire time, not the prayer time', () {
      final plan = _planner.plan(
        prayerTimesByDay: _horizon(1),
        settings: _settings(
          fajr: _prayer(timing: NotificationTiming.before15Min),
        ),
        now: DateTime(2026, 3, 14, 4),
      );

      final fajr = plan.firstWhere((p) => p.prayer == PlannedPrayer.fajr);
      expect(fajr.prayerTime, DateTime(2026, 3, 14, 4, 41));
      expect(fajr.fireTime, DateTime(2026, 3, 14, 4, 26));
      expect(fajr.leadTime, const Duration(minutes: 15));
    });

    test('every timing maps to the duration it names', () {
      expect(
        PrayerSchedulePlanner.leadTimeFor(NotificationTiming.onTime),
        Duration.zero,
      );
      expect(
        PrayerSchedulePlanner.leadTimeFor(NotificationTiming.before5Min),
        const Duration(minutes: 5),
      );
      expect(
        PrayerSchedulePlanner.leadTimeFor(NotificationTiming.before10Min),
        const Duration(minutes: 10),
      );
      expect(
        PrayerSchedulePlanner.leadTimeFor(NotificationTiming.before15Min),
        const Duration(minutes: 15),
      );
    });

    test('the lead time decides whether a prayer is still schedulable', () {
      // 04:30 is after Fajr-minus-15 (04:26) but before Fajr-minus-10 (04:31).
      // The same prayer at the same instant is past under one setting and
      // future under the other, which is exactly the arithmetic that used to
      // be untestable.
      final now = DateTime(2026, 3, 14, 4, 30);

      final withFifteen = _planner.plan(
        prayerTimesByDay: _horizon(1),
        settings: _settings(
          fajr: _prayer(timing: NotificationTiming.before15Min),
        ),
        now: now,
      );
      expect(
        withFifteen.map((p) => p.prayer),
        isNot(contains(PlannedPrayer.fajr)),
      );

      final withTen = _planner.plan(
        prayerTimesByDay: _horizon(1),
        settings: _settings(
          fajr: _prayer(timing: NotificationTiming.before10Min),
        ),
        now: now,
      );
      expect(withTen.map((p) => p.prayer), contains(PlannedPrayer.fajr));
    });
  });

  group('the notification id space', () {
    test('no two entries in a full horizon share an id', () {
      // There has already been one production id collision in this app. Seven
      // days times five prayers must be 35 distinct ids.
      final plan = _planner.plan(
        prayerTimesByDay: _horizon(7),
        settings: _settings(),
        now: DateTime(2026, 3, 14, 4),
      );

      expect(plan.map((p) => p.id).toSet(), hasLength(plan.length));
    });

    test('ids stay inside the 100..214 window prayers own', () {
      // Everything outside this range belongs to another feature: persistent
      // 999, fasting 5001-5999, wird 6001/6099, azkar 7100+. A prayer id that
      // escaped the window would be cancelled by nothing and could collide
      // with a reminder from a different subsystem.
      final plan = _planner.plan(
        prayerTimesByDay: _horizon(7),
        settings: _settings(),
        now: DateTime(2026, 3, 14, 4),
      );

      for (final entry in plan) {
        expect(entry.id, inInclusiveRange(100, 214));
      }
    });

    test('the cancel sweep covers every id the planner can produce', () {
      // The sweep must be a superset of any horizon, including one wider than
      // today's — shrinking the horizon must not strand ids armed by a
      // previous, longer one.
      final widest = _planner.plan(
        prayerTimesByDay: _horizon(PrayerSchedulePlanner.cancelDayWindow),
        settings: _settings(),
        now: DateTime(2026, 3, 14, 4),
      );

      expect(
        PrayerSchedulePlanner.cancellableIds.toSet(),
        containsAll(widest.map((p) => p.id)),
      );
      expect(
        PrayerSchedulePlanner.cancellableIds.toSet(),
        hasLength(PrayerSchedulePlanner.cancellableIds.length),
        reason: 'the sweep must not cancel the same id twice',
      );
    });

    test('a day keeps its id regardless of map insertion order', () {
      // Ids are allocated after sorting, so a horizon built in a different
      // order produces the identical plan — which is what makes the
      // reschedule-suppression signature meaningful.
      final forwards = _horizon(3);
      final backwards = <DateTime, Map<String, DateTime>>{
        for (final key in forwards.keys.toList().reversed) key: forwards[key]!,
      };

      final now = DateTime(2026, 3, 14, 4);
      final a = _planner.plan(
        prayerTimesByDay: forwards,
        settings: _settings(),
        now: now,
      );
      final b = _planner.plan(
        prayerTimesByDay: backwards,
        settings: _settings(),
        now: now,
      );

      expect(b.map((p) => p.id).toList(), a.map((p) => p.id).toList());
      expect(_planner.signature(b), _planner.signature(a));
    });

    test('prayers resolve by English key and by Arabic name', () {
      // The repository used to branch on the Arabic display string, so a typo
      // in a translation file would have broken scheduling rather than text.
      expect(PlannedPrayer.byKey('Fajr'), PlannedPrayer.fajr);
      expect(PlannedPrayer.byKey('fajr'), PlannedPrayer.fajr);
      expect(PlannedPrayer.byKey('الفجر'), PlannedPrayer.fajr);
      expect(PlannedPrayer.byKey('العشاء'), PlannedPrayer.isha);
      expect(PlannedPrayer.byKey('Sunrise'), isNull);
      // The old lookup returned id 0 for anything unrecognised — an id outside
      // the documented map that cancelPrayerSchedules would never clear.
      expect(PlannedPrayer.byKey('TestNotification'), isNull);
    });
  });

  group('the reschedule signature', () {
    test('an identical plan produces an identical signature', () {
      final now = DateTime(2026, 3, 14, 4);
      final a = _planner.plan(
        prayerTimesByDay: _horizon(7),
        settings: _settings(),
        now: now,
      );
      final b = _planner.plan(
        prayerTimesByDay: _horizon(7),
        settings: _settings(),
        now: now,
      );
      expect(_planner.signature(b), _planner.signature(a));
    });

    test('moving a fire time changes it', () {
      final now = DateTime(2026, 3, 14, 4);
      final onTime = _planner.signature(
        _planner.plan(
          prayerTimesByDay: _horizon(7),
          settings: _settings(),
          now: now,
        ),
      );
      final early = _planner.signature(
        _planner.plan(
          prayerTimesByDay: _horizon(7),
          settings: _settings(
            asr: _prayer(timing: NotificationTiming.before10Min),
          ),
          now: now,
        ),
      );
      expect(early, isNot(onTime));
    });

    test('changing the adhan changes it even though nothing moves', () {
      // The alarm table would be identical, but the sound would not — a
      // signature that ignored this would leave the old adhan armed.
      final now = DateTime(2026, 3, 14, 4);
      final before = _planner.signature(
        _planner.plan(
          prayerTimesByDay: _horizon(7),
          settings: _settings(),
          now: now,
        ),
      );
      final after = _planner.signature(
        _planner.plan(
          prayerTimesByDay: _horizon(7),
          settings: _settings(
            fajr: _prayer(sound: 'assets/adhan_sounds/makkah.mp3'),
          ),
          now: now,
        ),
      );
      expect(after, isNot(before));
    });

    test('turning the master toggle off changes it', () {
      final now = DateTime(2026, 3, 14, 4);
      expect(
        _planner.signature(
          _planner.plan(
            prayerTimesByDay: _horizon(7),
            settings: _settings(masterEnabled: false),
            now: now,
          ),
        ),
        isNot(
          _planner.signature(
            _planner.plan(
              prayerTimesByDay: _horizon(7),
              settings: _settings(),
              now: now,
            ),
          ),
        ),
      );
    });
  });

  group('the horizon', () {
    test('iOS is shorter than Android, because of the 64-request cap', () {
      expect(PrayerSchedulePlanner.horizonDays(isIOS: true), 5);
      expect(PrayerSchedulePlanner.horizonDays(isIOS: false), 7);
    });

    test('the iOS horizon stays inside its share of the 64-slot budget', () {
      // Five days of five prayers is 25 requests. iOS keeps the 64
      // soonest-firing and silently discards the rest, so this has to leave
      // room for azkar, wird, daily inspiration and the fasting fan-out.
      final plan = _planner.plan(
        prayerTimesByDay: _horizon(
          PrayerSchedulePlanner.horizonDays(isIOS: true),
        ),
        settings: _settings(),
        now: DateTime(2026, 3, 14, 4),
      );
      expect(plan, hasLength(25));
      expect(plan.length, lessThan(64));
    });
  });

  group('a day boundary does not confuse the plan', () {
    test('an Isha after midnight keeps the day it belongs to', () {
      // High latitudes and the last third of Ramadan both produce an Isha that
      // lands after midnight. Re-deriving the day from the instant would file
      // it under tomorrow and collide with tomorrow's own Isha id.
      final horizon = {
        _day(14): {
          'Fajr': DateTime(2026, 3, 14, 4, 41),
          'Isha': DateTime(2026, 3, 15, 0, 20), // past midnight
        },
        _day(15): {'Isha': DateTime(2026, 3, 16, 0, 22)},
      };

      final plan = _planner.plan(
        prayerTimesByDay: horizon,
        settings: _settings(),
        now: DateTime(2026, 3, 14, 4),
      );

      final ishas = plan.where((p) => p.prayer == PlannedPrayer.isha).toList();
      expect(ishas, hasLength(2));
      expect(ishas[0].day, _day(14));
      expect(ishas[0].prayerTime, DateTime(2026, 3, 15, 0, 20));
      expect(ishas[1].day, _day(15));
      expect(ishas[0].id, isNot(ishas[1].id));
    });

    test('the clock decides the plan, and only the clock', () {
      // The point of the whole extraction: the same inputs at two instants
      // give two answers, and both are assertable without a device.
      final clock = FixedClock(DateTime(2026, 3, 14, 4));
      final horizon = _horizon(1);

      expect(
        _planner
            .plan(
              prayerTimesByDay: horizon,
              settings: _settings(),
              now: clock.now(),
            )
            .length,
        5,
      );

      clock.advance(const Duration(hours: 14)); // 18:00 — only Isha left
      expect(
        _planner
            .plan(
              prayerTimesByDay: horizon,
              settings: _settings(),
              now: clock.now(),
            )
            .map((p) => p.prayer)
            .toList(),
        [PlannedPrayer.isha],
      );

      clock.jumpTo(DateTime(2026, 3, 14, 23, 59));
      expect(
        _planner.plan(
          prayerTimesByDay: horizon,
          settings: _settings(),
          now: clock.now(),
        ),
        isEmpty,
      );
    });
  });

  group('Clock', () {
    test('today() is local midnight', () {
      final clock = FixedClock(DateTime(2026, 3, 14, 23, 59, 59));
      expect(clock.today(), DateTime(2026, 3, 14));
      clock.advance(const Duration(seconds: 1));
      expect(clock.today(), DateTime(2026, 3, 15));
    });

    test('the system clock advances', () {
      const clock = SystemClock();
      final first = clock.now();
      expect(clock.today(), DateTime(first.year, first.month, first.day));
      expect(systemClock.today(), clock.today());
    });
  });
}
