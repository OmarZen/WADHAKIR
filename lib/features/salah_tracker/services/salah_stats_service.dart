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

  /// Total calendar days in the range (including excused ones).
  final int totalDays;

  /// Days in the range the user marked excused. Excluded from [totalSlots] and
  /// from [completeDays], so a week with two excused days reads "5 of 5", not
  /// "5 of 7".
  final int excusedDays;

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
    this.excusedDays = 0,
  });

  /// Calendar days in the range on which prayers were actually owed.
  int get owedDays => totalDays - excusedDays;

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
  ///
  /// Excused days ([SalahLogModel.excusedDays]) are **transparent**: they are
  /// stepped over without counting toward the streak and without breaking it.
  /// A woman who pauses for her period resumes on the same chain she left.
  int currentStreak(SalahLogModel log, DateTime today) {
    final t = normalize(today);
    var cursor = t;

    // Walk back past anything that must not end the streak: excused days, and
    // an incomplete TODAY (the day isn't over yet, so it isn't a failure).
    while (log.isExcusedDay(cursor) ||
        (cursor == t && !isDayComplete(log, cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (true) {
      if (log.isExcusedDay(cursor)) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      if (!isDayComplete(log, cursor)) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Longest run of consecutive complete calendar days anywhere in the log.
  ///
  /// A gap composed entirely of excused days does not end a run — the days on
  /// either side are treated as adjacent.
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
      if (cur.difference(prev).inDays == 1 ||
          _bridgedByExcused(log, prev, cur)) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }

  /// True when every calendar day strictly between [prev] and [cur] is excused
  /// (and there is at least one such day). Used to bridge streak runs.
  bool _bridgedByExcused(SalahLogModel log, DateTime prev, DateTime cur) {
    var cursor = prev.add(const Duration(days: 1));
    if (!cursor.isBefore(cur)) return false;
    while (cursor.isBefore(cur)) {
      if (!log.isExcusedDay(cursor)) return false;
      cursor = cursor.add(const Duration(days: 1));
    }
    return true;
  }

  /// Steadfastness over the trailing [window] days: prayed fard ÷ fard actually
  /// owed, with excused days removed from the denominator. 0..1.
  ///
  /// This is the measure that replaces an all-or-nothing streak on the home
  /// screen. It never resets to zero for a single missed day, so a lapse costs
  /// a few percent rather than everything — which is the difference between a
  /// user who returns and one who deletes the app.
  double istiqamah(SalahLogModel log, DateTime today, {int window = 30}) {
    final end = normalize(today);
    var owed = 0;
    var prayed = 0;
    for (var i = 0; i < window; i++) {
      final day = end.subtract(Duration(days: i));
      if (log.isExcusedDay(day)) continue;
      owed += PrayerSlot.values.length;
      prayed += prayedCount(log, day);
    }
    return owed == 0 ? 0 : prayed / owed;
  }

  /// Days since the most recent day with any logged fard. `null` when the log
  /// is empty. Drives the "welcome back" copy after a lapse.
  int? daysSinceLastLog(SalahLogModel log, DateTime today) {
    final t = normalize(today);
    DateTime? latest;
    for (final dayKey in log.days.keys) {
      final parsed = DateTime.tryParse(dayKey);
      if (parsed == null) continue;
      final day = normalize(parsed);
      if (day.isAfter(t)) continue;
      if (latest == null || day.isAfter(latest)) latest = day;
    }
    if (latest == null) return null;
    return t.difference(latest).inDays;
  }

  /// Aggregate stats over the inclusive day range [start]..[end].
  SalahRangeStats rangeStats(SalahLogModel log, DateTime start, DateTime end) {
    final s = normalize(start);
    final e = normalize(end);
    final counts = <PrayerStatus, int>{};
    var completeDays = 0;
    var prayed = 0;
    var totalDays = 0;
    var excused = 0;
    var cursor = s;
    while (!cursor.isAfter(e)) {
      totalDays++;
      // An excused day is skipped entirely: it contributes no status counts,
      // no prayed count, and no slots to the denominator. Counting it would
      // report a shortfall against prayers that were never owed.
      if (log.isExcusedDay(cursor)) {
        excused++;
        cursor = cursor.add(const Duration(days: 1));
        continue;
      }
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
      excusedDays: excused,
      prayedCount: prayed,
      totalSlots: (totalDays - excused) * PrayerSlot.values.length,
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
