import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';
import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/features/salah_tracker/services/salah_stats_service.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:wadhakir/core/utils/calculation_method_mapper.dart';

/// Build a log where each listed day has ALL five fard set to [status].
SalahLogModel _logWithCompleteDays(List<DateTime> days,
    {PrayerStatus status = PrayerStatus.onTime}) {
  var log = SalahLogModel.defaultSettings();
  for (final day in days) {
    final key = SalahLogModel.dateKey(day);
    for (final slot in PrayerSlot.values) {
      log = log.setFard(key, slot, status);
    }
  }
  return log;
}

PrayerTimesModel _prayerTimesFor(DateTime day) {
  DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);
  return PrayerTimesModel(
    fajr: at(4, 0),
    sunrise: at(5, 30),
    dhuhr: at(12, 0),
    asr: at(15, 30),
    maghrib: at(18, 0),
    isha: at(19, 30),
    date: DateTime(day.year, day.month, day.day),
    calculationParameters:
        CalculationMethodMapper.getParameters('muslim_world_league'),
    coordinates: const Coordinates(0, 0),
    middleOfTheNight: at(0, 0),
    lastThirdOfTheNight: at(2, 0),
  );
}

void main() {
  const stats = SalahStatsService();

  group('SalahLogModel', () {
    test('setFard with notLogged removes the entry and empty day', () {
      final key = SalahLogModel.dateKey(DateTime(2026, 6, 15));
      var log = SalahLogModel.defaultSettings()
          .setFard(key, PrayerSlot.fajr, PrayerStatus.onTime);
      expect(log.fardStatus(key, PrayerSlot.fajr), PrayerStatus.onTime);
      log = log.setFard(key, PrayerSlot.fajr, PrayerStatus.notLogged);
      expect(log.fardStatus(key, PrayerSlot.fajr), PrayerStatus.notLogged);
      expect(log.days.containsKey(key), isFalse);
    });

    test('JSON round-trips days, rawatib, makeUp and trackNawafil', () {
      final key = SalahLogModel.dateKey(DateTime(2026, 6, 15));
      var log = SalahLogModel.defaultSettings()
          .setFard(key, PrayerSlot.fajr, PrayerStatus.onTime)
          .setFard(key, PrayerSlot.asr, PrayerStatus.late)
          .setFard(key, PrayerSlot.isha, PrayerStatus.missed)
          .setRawatib(key, RawatibUnit.fajrBefore, true)
          .setRawatib(key, RawatibUnit.dhuhrBefore, true)
          .setRawatib(key, RawatibUnit.dhuhrAfter, true)
          .setWitr(key, true)
          .setMakeUp(PrayerSlot.dhuhr, 7)
          .copyWith(trackNawafil: true);

      final decoded = SalahLogModel.fromJson(
        jsonDecode(jsonEncode(log.toJson())) as Map<String, dynamic>,
      );
      expect(decoded, log);
      expect(decoded.fardStatus(key, PrayerSlot.asr), PrayerStatus.late);
      expect(decoded.rawatibDone(key, RawatibUnit.fajrBefore), isTrue);
      expect(decoded.rawatibDone(key, RawatibUnit.dhuhrBefore), isTrue);
      expect(decoded.rawatibDone(key, RawatibUnit.dhuhrAfter), isTrue);
      // A unit that was never set reads back false.
      expect(decoded.rawatibDone(key, RawatibUnit.maghribAfter), isFalse);
      expect(decoded.rawatibDoneCount(key, PrayerSlot.dhuhr), 2);
      expect(decoded.witrDone(key), isTrue);
      expect(decoded.makeUpFor(PrayerSlot.dhuhr), 7);
      expect(decoded.trackNawafil, isTrue);
    });

    test('fromJson migrates legacy per-prayer sunnah names to rawatib units', () {
      // Pre-3.4 logs stored a bare PrayerSlot name per prayer whose sunnah was
      // done. These must expand to that prayer's rawatib units on read.
      final decoded = SalahLogModel.fromJson({
        'sunnah': {
          '2026-06-15': ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'],
        },
      });
      const key = '2026-06-15';
      expect(decoded.rawatibDone(key, RawatibUnit.fajrBefore), isTrue);
      expect(decoded.rawatibDone(key, RawatibUnit.dhuhrBefore), isTrue);
      expect(decoded.rawatibDone(key, RawatibUnit.dhuhrAfter), isTrue);
      expect(decoded.rawatibDone(key, RawatibUnit.maghribAfter), isTrue);
      expect(decoded.rawatibDone(key, RawatibUnit.ishaAfter), isTrue);
      // 'asr' had no muʾakkadah rawatib -> migrates to nothing.
      expect(decoded.rawatibDoneCount(key, PrayerSlot.asr), 0);
    });

    test('RawatibUnit.forSlot returns the 12-rakaah structure', () {
      expect(RawatibUnit.forSlot(PrayerSlot.fajr), [RawatibUnit.fajrBefore]);
      expect(RawatibUnit.forSlot(PrayerSlot.dhuhr),
          [RawatibUnit.dhuhrBefore, RawatibUnit.dhuhrAfter]);
      expect(RawatibUnit.forSlot(PrayerSlot.asr), isEmpty);
      expect(RawatibUnit.forSlot(PrayerSlot.maghrib), [RawatibUnit.maghribAfter]);
      expect(RawatibUnit.forSlot(PrayerSlot.isha), [RawatibUnit.ishaAfter]);
      // The confirmed rawatib total is 12 rakʿah.
      final total = RawatibUnit.values.fold<int>(0, (s, u) => s + u.rakat);
      expect(total, 12);
    });

    test('makeUp is floored at zero', () {
      final log =
          SalahLogModel.defaultSettings().setMakeUp(PrayerSlot.fajr, 2).adjustMakeUp(PrayerSlot.fajr, -5);
      expect(log.makeUpFor(PrayerSlot.fajr), 0);
      expect(log.makeUp.containsKey(PrayerSlot.fajr), isFalse);
    });

    test('fromJson tolerates corrupt / unknown values', () {
      final decoded = SalahLogModel.fromJson({
        'days': {
          '2026-06-15': {'fajr': 1, 'bogus': 99, 'asr': 'x'},
        },
        'makeUp': {'unknown': 3, 'fajr': -1},
        'trackNawafil': 'notabool',
      });
      final key = '2026-06-15';
      expect(decoded.fardStatus(key, PrayerSlot.fajr), PrayerStatus.onTime);
      // 'asr' had a non-int -> clamped to index 0 (notLogged) -> dropped.
      expect(decoded.fardStatus(key, PrayerSlot.asr), PrayerStatus.notLogged);
      expect(decoded.makeUpFor(PrayerSlot.fajr), 0);
      expect(decoded.trackNawafil, isFalse);
    });
  });

  group('SalahStatsService.currentStreak', () {
    final today = DateTime(2026, 6, 15);

    test('counts today when today is complete', () {
      final log = _logWithCompleteDays([
        today,
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
      ]);
      expect(stats.currentStreak(log, today), 3);
    });

    test('today incomplete does not break a streak ending yesterday', () {
      final log = _logWithCompleteDays([
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
      ]);
      expect(stats.currentStreak(log, today), 2);
    });

    test('a gap (day before yesterday missing) breaks the streak', () {
      final log = _logWithCompleteDays([
        today,
        // yesterday missing
        today.subtract(const Duration(days: 2)),
      ]);
      expect(stats.currentStreak(log, today), 1);
    });

    test('no complete days yields zero', () {
      expect(stats.currentStreak(SalahLogModel.defaultSettings(), today), 0);
    });

    test('qada counts toward completion', () {
      final log = _logWithCompleteDays([today], status: PrayerStatus.qada);
      expect(stats.currentStreak(log, today), 1);
    });

    test('missed does NOT count as prayed', () {
      final log = _logWithCompleteDays([today], status: PrayerStatus.missed);
      expect(stats.isDayComplete(log, today), isFalse);
      expect(stats.currentStreak(log, today), 0);
    });
  });

  group('SalahStatsService.bestStreak', () {
    test('finds the longest run across gaps', () {
      final base = DateTime(2026, 5, 1);
      final days = <DateTime>[
        base,
        base.add(const Duration(days: 1)),
        base.add(const Duration(days: 2)), // run of 3
        // gap at day 3
        base.add(const Duration(days: 5)),
        base.add(const Duration(days: 6)), // run of 2
      ];
      final log = _logWithCompleteDays(days);
      expect(stats.bestStreak(log), 3);
    });
  });

  group('SalahStatsService.rangeStats / weekStats', () {
    test('aggregates prayed and status counts', () {
      final today = DateTime(2026, 6, 15);
      var log = _logWithCompleteDays([
        today,
        today.subtract(const Duration(days: 1)),
      ]);
      // Add a late + missed on a third day.
      final k = SalahLogModel.dateKey(today.subtract(const Duration(days: 2)));
      log = log
          .setFard(k, PrayerSlot.fajr, PrayerStatus.late)
          .setFard(k, PrayerSlot.dhuhr, PrayerStatus.missed);

      final week = stats.weekStats(log, today);
      expect(week.totalDays, 7);
      expect(week.completeDays, 2);
      // 2 complete days * 5 onTime + 1 late = 11 prayed.
      expect(week.prayedCount, 11);
      expect(week.countOf(PrayerStatus.missed), 1);
      expect(week.countOf(PrayerStatus.late), 1);
    });
  });

  group('SalahStatsService.classifyFard', () {
    final day = DateTime(2026, 6, 15);
    final model = _prayerTimesFor(day);

    test('within the window is on-time', () {
      // Dhuhr 12:00, Asr 15:30 -> 13:00 is on-time.
      final now = DateTime(2026, 6, 15, 13, 0);
      expect(stats.classifyFard(model, PrayerSlot.dhuhr, now),
          PrayerStatus.onTime);
    });

    test('after the next prayer entered is late', () {
      // 16:00 is after Asr 15:30 -> Dhuhr logged then is late.
      final now = DateTime(2026, 6, 15, 16, 0);
      expect(
          stats.classifyFard(model, PrayerSlot.dhuhr, now), PrayerStatus.late);
    });

    test('Isha is on-time any time the same calendar day', () {
      final now = DateTime(2026, 6, 15, 23, 30);
      expect(
          stats.classifyFard(model, PrayerSlot.isha, now), PrayerStatus.onTime);
    });

    test('Isha after midnight is late', () {
      final now = DateTime(2026, 6, 16, 0, 30);
      expect(stats.classifyFard(model, PrayerSlot.isha, now), PrayerStatus.late);
    });
  });
}
