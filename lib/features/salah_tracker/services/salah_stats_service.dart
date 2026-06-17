import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';
import 'package:wadhakir/data/models/salah/salah_log_model.dart';

/// Aggregated stats for a date range (week / month sections).
class SalahRangeStats {
  /// Inclusive day bounds (normalized to midnight).
  final DateTime start;
  final DateTime end;

  /// Count of each status across all fard prayers in the range.
  final Map<PrayerStatus, int> statusCounts;

  /// Days in the range where all five fard are prayed.
  final int completeDays;

  /// Total days in the range.
  final int totalDays;

  /// Prayed (onTime/late/qada) fard count over the range.
  final int prayedCount;

  /// Total possible fard slots in the range (totalDays * 5).
  final int totalSlots;

  const SalahRangeStats({
    required this.start,
    required this.end,
    required this.statusCounts,
    required this.completeDays,
    required this.totalDays,
    required this.prayedCount,
    required this.totalSlots,
  });

  int countOf(PrayerStatus s) => statusCounts[s] ?? 0;

  /// 0..1 completion (prayed / total slots).
  double get completionFraction =>
      totalSlots == 0 ? 0 : prayedCount / totalSlots;
}

/// Pure derivation of streaks and weekly/monthly stats over a [SalahLogModel].
/// Nothing here is persisted — it is a sub-millisecond pass over the decoded
/// days map. Modeled on WirdScheduleService (stateless, const-constructible).
class SalahStatsService {
  const SalahStatsService();

  DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  /// A day counts as "complete" when all five fard are prayed
  /// (onTime / late / qada).
  bool isDayComplete(SalahLogModel log, DateTime day) {
    final key = SalahLogModel.dateKey(normalize(day));
    for (final slot in PrayerSlot.values) {
      if (!log.fardStatus(key, slot).isPrayed) return false;
    }
    return true;
  }

  /// Number of prayed fard (onTime/late/qada) on [day].
  int prayedCount(SalahLogModel log, DateTime day) {
    final key = SalahLogModel.dateKey(normalize(day));
    var n = 0;
    for (final slot in PrayerSlot.values) {
      if (log.fardStatus(key, slot).isPrayed) n++;
    }
    return n;
  }

  /// 0..1 completion fraction for a single day (prayed / 5).
  double completionFraction(SalahLogModel log, DateTime day) =>
      prayedCount(log, day) / PrayerSlot.values.length;

  /// Current streak: consecutive complete days ending at the most recent
  /// complete day, provided that day is today or yesterday (otherwise the
  /// streak is considered broken → 0). Today being incomplete does NOT break
  /// the streak until the day ends — it just isn't counted yet.
  int currentStreak(SalahLogModel log, DateTime today) {
    final t = normalize(today);
    var cursor = isDayComplete(log, t)
        ? t
        : t.subtract(const Duration(days: 1));
    if (!isDayComplete(log, cursor)) return 0;
    var streak = 0;
    while (isDayComplete(log, cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Longest run of consecutive complete calendar days anywhere in the log.
  int bestStreak(SalahLogModel log) {
    final completeDays = <DateTime>[];
    for (final dayKey in log.days.keys) {
      final parsed = DateTime.tryParse(dayKey);
      if (parsed == null) continue;
      final day = normalize(parsed);
      if (isDayComplete(log, day)) completeDays.add(day);
    }
    if (completeDays.isEmpty) return 0;
    completeDays.sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < completeDays.length; i++) {
      final prev = completeDays[i - 1];
      final cur = completeDays[i];
      if (cur.difference(prev).inDays == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }

  /// Aggregate stats over the inclusive day range [start]..[end].
  SalahRangeStats rangeStats(SalahLogModel log, DateTime start, DateTime end) {
    final s = normalize(start);
    final e = normalize(end);
    final counts = <PrayerStatus, int>{};
    var completeDays = 0;
    var prayed = 0;
    var totalDays = 0;
    var cursor = s;
    while (!cursor.isAfter(e)) {
      totalDays++;
      final key = SalahLogModel.dateKey(cursor);
      var dayPrayed = 0;
      for (final slot in PrayerSlot.values) {
        final status = log.fardStatus(key, slot);
        counts[status] = (counts[status] ?? 0) + 1;
        if (status.isPrayed) {
          prayed++;
          dayPrayed++;
        }
      }
      if (dayPrayed == PrayerSlot.values.length) completeDays++;
      cursor = cursor.add(const Duration(days: 1));
    }
    return SalahRangeStats(
      start: s,
      end: e,
      statusCounts: counts,
      completeDays: completeDays,
      totalDays: totalDays,
      prayedCount: prayed,
      totalSlots: totalDays * PrayerSlot.values.length,
    );
  }

  /// Last 7 days (inclusive of [today]).
  SalahRangeStats weekStats(SalahLogModel log, DateTime today) {
    final end = normalize(today);
    return rangeStats(log, end.subtract(const Duration(days: 6)), end);
  }

  /// The current calendar month containing [today].
  SalahRangeStats monthStats(SalahLogModel log, DateTime today) {
    final t = normalize(today);
    final start = DateTime(t.year, t.month, 1);
    final end = DateTime(t.year, t.month + 1, 0); // last day of month
    return rangeStats(log, start, end);
  }

  /// Per-day prayed counts (0..5) for the [today]'s calendar month — drives the
  /// monthly heatmap. Key is 'yyyy-MM-dd'.
  Map<String, int> monthlyHeatmap(SalahLogModel log, DateTime today) {
    final t = normalize(today);
    final last = DateTime(t.year, t.month + 1, 0).day;
    final result = <String, int>{};
    for (var d = 1; d <= last; d++) {
      final day = DateTime(t.year, t.month, d);
      result[SalahLogModel.dateKey(day)] = prayedCount(log, day);
    }
    return result;
  }

  /// Classify a fard logged "now" against today's prayer times: [PrayerStatus.onTime]
  /// if `now` is before the next fard's time, else [PrayerStatus.late].
  ///
  /// The boundary after Isha is the start of the next calendar day (Isha prayed
  /// any time the same day counts as on-time). Only meaningful for *today*; past
  /// days have no times in memory and should be logged as qada.
  PrayerStatus classifyFard(
    PrayerTimesModel model,
    PrayerSlot slot,
    DateTime now,
  ) {
    final times = <PrayerSlot, DateTime>{
      PrayerSlot.fajr: model.fajr,
      PrayerSlot.dhuhr: model.dhuhr,
      PrayerSlot.asr: model.asr,
      PrayerSlot.maghrib: model.maghrib,
      PrayerSlot.isha: model.isha,
    };
    final order = PrayerSlot.values;
    final idx = order.indexOf(slot);
    final DateTime nextTime;
    if (idx < order.length - 1) {
      nextTime = times[order[idx + 1]]!;
    } else {
      final d = model.date;
      nextTime = DateTime(d.year, d.month, d.day).add(const Duration(days: 1));
    }
    return now.isBefore(nextTime) ? PrayerStatus.onTime : PrayerStatus.late;
  }
}
