import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';
import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/features/salah_tracker/services/salah_stats_service.dart';

/// Build a log where each listed day has ALL five fard set to [status].
SalahLogModel _complete(
  List<DateTime> days, {
  PrayerStatus status = PrayerStatus.onTime,
}) {
  var log = SalahLogModel.defaultSettings();
  for (final day in days) {
    final key = SalahLogModel.dateKey(day);
    for (final slot in PrayerSlot.values) {
      log = log.setFard(key, slot, status);
    }
  }
  return log;
}

SalahLogModel _excuse(SalahLogModel log, List<DateTime> days) {
  var out = log;
  for (final d in days) {
    out = out.setExcused(SalahLogModel.dateKey(d), true);
  }
  return out;
}

void main() {
  const stats = SalahStatsService();

  // A fixed "today" — the production code takes `today` as a parameter, which
  // is what makes these tests hermetic despite the codebase's 85 DateTime.now()
  // calls elsewhere.
  final today = DateTime(2026, 6, 20);
  DateTime ago(int d) => today.subtract(Duration(days: d));

  group('SalahLogModel excused days', () {
    test('round-trips through JSON', () {
      final log = _excuse(SalahLogModel.defaultSettings(), [
        DateTime(2026, 6, 10),
        DateTime(2026, 6, 11),
      ]);
      final restored = SalahLogModel.fromJson(
        jsonDecode(jsonEncode(log.toJson())) as Map<String, dynamic>,
      );
      expect(restored.excusedDays, log.excusedDays);
      expect(restored.isExcusedDay(DateTime(2026, 6, 10)), isTrue);
      expect(restored.isExcusedDay(DateTime(2026, 6, 12)), isFalse);
    });

    test('a log written before excused days existed still decodes', () {
      // Exactly the shape an older build wrote: no "excused" key at all.
      final legacy = {
        'days': {
          '2026-06-15': {'fajr': PrayerStatus.onTime.index},
        },
        'sunnah': <String, dynamic>{},
        'witr': <String>[],
        'makeUp': <String, dynamic>{},
        'trackNawafil': false,
      };
      final log = SalahLogModel.fromJson(legacy);
      expect(log.excusedDays, isEmpty);
      expect(
        log.fardStatus('2026-06-15', PrayerSlot.fajr),
        PrayerStatus.onTime,
      );
    });

    test('marking a day excused clears any statuses logged for it', () {
      final key = SalahLogModel.dateKey(today);
      final log = _complete([today]).setExcused(key, true);
      expect(log.isExcused(key), isTrue);
      for (final slot in PrayerSlot.values) {
        expect(log.fardStatus(key, slot), PrayerStatus.notLogged);
      }
    });

    test('setExcusedRange covers both endpoints', () {
      final log = SalahLogModel.defaultSettings().setExcusedRange(
        ago(4),
        ago(2),
        true,
      );
      expect(log.isExcusedDay(ago(4)), isTrue);
      expect(log.isExcusedDay(ago(3)), isTrue);
      expect(log.isExcusedDay(ago(2)), isTrue);
      expect(log.isExcusedDay(ago(5)), isFalse);
      expect(log.isExcusedDay(ago(1)), isFalse);
    });
  });

  group('currentStreak with excused days', () {
    test('excused days do not break the chain', () {
      // Prayed 5 days, paused 3, prayed 4 more up to today.
      var log = _complete([
        for (var i = 0; i <= 3; i++) ago(i), // today..today-3
        for (var i = 7; i <= 11; i++) ago(i), // today-7..today-11
      ]);
      log = _excuse(log, [ago(4), ago(5), ago(6)]);

      // 4 recent + 5 older = 9. The pause is stepped over, not counted.
      expect(stats.currentStreak(log, today), 9);
    });

    test('a genuinely missed day still breaks the chain', () {
      var log = _complete([
        for (var i = 0; i <= 3; i++) ago(i),
        for (var i = 5; i <= 9; i++) ago(i),
      ]);
      // ago(4) is neither prayed nor excused — a real gap.
      log = _excuse(log, const []);
      expect(stats.currentStreak(log, today), 4);
    });

    test('excused today does not zero the streak', () {
      var log = _complete([for (var i = 1; i <= 5; i++) ago(i)]);
      log = _excuse(log, [today]);
      expect(stats.currentStreak(log, today), 5);
    });

    test(
      'an incomplete today still does not break it (unchanged behaviour)',
      () {
        final log = _complete([for (var i = 1; i <= 3; i++) ago(i)]);
        expect(stats.currentStreak(log, today), 3);
      },
    );

    test('terminates when every day back to the epoch is excused', () {
      final log = _excuse(SalahLogModel.defaultSettings(), [
        for (var i = 0; i <= 30; i++) ago(i),
      ]);
      expect(stats.currentStreak(log, today), 0);
    });
  });

  group('bestStreak with excused days', () {
    test('bridges a run across an all-excused gap', () {
      var log = _complete([
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 2),
        // 3rd and 4th excused
        DateTime(2026, 6, 5),
        DateTime(2026, 6, 6),
      ]);
      log = _excuse(log, [DateTime(2026, 6, 3), DateTime(2026, 6, 4)]);
      expect(stats.bestStreak(log), 4);
    });

    test('does not bridge when the gap contains a non-excused day', () {
      var log = _complete([
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 2),
        DateTime(2026, 6, 5),
        DateTime(2026, 6, 6),
      ]);
      // Only one of the two gap days is excused.
      log = _excuse(log, [DateTime(2026, 6, 3)]);
      expect(stats.bestStreak(log), 2);
    });
  });

  group('rangeStats with excused days', () {
    test('excused days leave the denominator', () {
      var log = _complete([for (var i = 0; i <= 4; i++) ago(i)]);
      log = _excuse(log, [ago(5), ago(6)]);

      final week = stats.weekStats(log, today);
      expect(week.totalDays, 7);
      expect(week.excusedDays, 2);
      expect(week.owedDays, 5);
      expect(week.totalSlots, 25);
      expect(week.prayedCount, 25);
      // The point of the whole feature: a full week despite the pause.
      expect(week.completionFraction, 1.0);
    });

    test('without the pause the same week reads as a shortfall', () {
      final log = _complete([for (var i = 0; i <= 4; i++) ago(i)]);
      final week = stats.weekStats(log, today);
      expect(week.totalSlots, 35);
      expect(week.completionFraction, closeTo(25 / 35, 1e-9));
    });
  });

  group('istiqamah', () {
    test('a single missed day costs a few percent, not everything', () {
      // 29 of the last 30 days complete, one day entirely missed.
      final log = _complete([
        for (var i = 0; i < 30; i++)
          if (i != 7) ago(i),
      ]);
      final value = stats.istiqamah(log, today);
      expect(value, closeTo(145 / 150, 1e-9));
      // Contrast with the streak, which resets hard.
      expect(stats.currentStreak(log, today), 7);
    });

    test('excused days are removed from the denominator', () {
      var log = _complete([
        for (var i = 0; i < 30; i++)
          if (i >= 5) ago(i),
      ]);
      log = _excuse(log, [for (var i = 0; i < 5; i++) ago(i)]);
      expect(stats.istiqamah(log, today), 1.0);
    });

    test('an empty log is 0, not NaN', () {
      expect(stats.istiqamah(SalahLogModel.defaultSettings(), today), 0);
    });
  });

  _pauseModelTests();

  group('daysSinceLastLog', () {
    test('null when nothing was ever logged', () {
      expect(
        stats.daysSinceLastLog(SalahLogModel.defaultSettings(), today),
        isNull,
      );
    });

    test('counts back to the most recent logged day', () {
      final log = _complete([ago(6), ago(9)]);
      expect(stats.daysSinceLastLog(log, today), 6);
    });
  });
}

/// Pause-as-state: the model half. The cubit half (day-rollover fill-forward)
/// needs SharedPreferences and lives in the cubit test.
void _pauseModelTests() {
  final today = DateTime(2026, 6, 20);

  group('pause anchor (excusedSince)', () {
    test('round-trips through JSON', () {
      final log = SalahLogModel.defaultSettings().copyWith(
        excusedSince: SalahLogModel.dateKey(today),
      );
      final restored = SalahLogModel.fromJson(
        jsonDecode(jsonEncode(log.toJson())) as Map<String, dynamic>,
      );
      expect(restored.excusedSince, '2026-06-20');
    });

    test('is absent from JSON when not paused', () {
      final json = SalahLogModel.defaultSettings().toJson();
      expect(json.containsKey('excusedSince'), isFalse);
    });

    test('clearExcusedSince actually clears it — a bare copyWith cannot', () {
      final paused = SalahLogModel.defaultSettings().copyWith(
        excusedSince: '2026-06-20',
      );
      // Passing null to a nullable copyWith param is indistinguishable from
      // omitting it, which is why the explicit flag exists.
      expect(paused.copyWith(excusedSince: null).excusedSince, '2026-06-20');
      expect(paused.copyWith(clearExcusedSince: true).excusedSince, isNull);
    });

    test('a legacy log has no anchor and is not paused', () {
      final log = SalahLogModel.fromJson({
        'days': <String, dynamic>{},
        'witr': <String>[],
        'makeUp': <String, dynamic>{},
        'trackNawafil': false,
      });
      expect(log.excusedSince, isNull);
      expect(log.excusedDays, isEmpty);
    });

    test('a non-string anchor is rejected rather than crashing', () {
      final log = SalahLogModel.fromJson({
        'days': <String, dynamic>{},
        'witr': <String>[],
        'makeUp': <String, dynamic>{},
        'trackNawafil': false,
        'excusedSince': 12345,
      });
      expect(log.excusedSince, isNull);
    });
  });
}
