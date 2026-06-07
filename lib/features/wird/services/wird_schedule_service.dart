import 'dart:developer';
import 'package:quran_library/quran_library.dart';
import 'package:wadhakir/data/models/wird/wird_enums.dart';
import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/features/wird/services/quran_structure.dart';

/// One day of the wird schedule.
class WirdDay {
  /// 0-based index into the schedule.
  final int dayIndex;

  /// 1-based day number for display ("يوم N").
  final int dayNumber;

  /// First Mushaf page to read this day (1-based, inclusive).
  final int startPage;

  /// Last Mushaf page to read this day (1-based, inclusive).
  final int endPage;

  /// Calendar date for this day (date-only).
  final DateTime date;

  /// Display label for the juz this day starts in, e.g. "الجزء 1" — empty if
  /// it could not be resolved.
  final String juzLabel;

  const WirdDay({
    required this.dayIndex,
    required this.dayNumber,
    required this.startPage,
    required this.endPage,
    required this.date,
    required this.juzLabel,
  });

  /// Number of pages covered this day.
  int get pageCount => endPage - startPage + 1;
}

/// How the user is doing relative to their plan's schedule.
enum WirdPace {
  /// No active plan / not yet started.
  notStarted,

  /// Fewer days completed than the calendar expects → "متأخر".
  behind,

  /// Exactly on schedule.
  onTrack,

  /// More days completed than the calendar expects → "متقدم".
  ahead,

  /// All days completed — the ختمة is done.
  finished,
}

/// Pace snapshot derived from a [WirdPlanModel] + its schedule and "now".
///
/// IMPORTANT: the arithmetic here is mirrored natively in
/// `WirdProgressWidgetProvider.kt` (so the home-screen widget stays date-fresh
/// without launching the app). Keep the two in sync.
class WirdProgressStatus {
  final WirdPace pace;

  /// Number of days the user is behind (0 unless [pace] is behind).
  final int daysLate;

  /// Number of days the user is ahead (0 unless [pace] is ahead).
  final int daysAhead;

  /// First incomplete day index — the "current wird" the user should read.
  /// -1 when finished or there is no schedule.
  final int currentDayIndex;

  /// Whether every day in the plan has been completed.
  final bool isFinished;

  const WirdProgressStatus({
    required this.pace,
    required this.daysLate,
    required this.daysAhead,
    required this.currentDayIndex,
    required this.isFinished,
  });

  static const WirdProgressStatus notStarted = WirdProgressStatus(
    pace: WirdPace.notStarted,
    daysLate: 0,
    daysAhead: 0,
    currentDayIndex: -1,
    isFinished: false,
  );
}

/// Pure logic for turning a [WirdPlanModel] into a day-by-day schedule and
/// deriving progress metrics. No persistence, no Flutter dependencies (other
/// than the quran_library used purely for juz labels).
class WirdScheduleService {
  const WirdScheduleService();

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Resolve the juz number (1..30) for a real 1-based [page].
  ///
  /// NOTE the off-by-one: quran_library's `getJuzByPageNumber` matches
  /// `ayah.page == pageNumber + 1`, so to look up real page P we pass P - 1.
  /// Wrapped defensively so a package hiccup never breaks the schedule.
  int? juzForPage(int page) {
    try {
      final ayah = QuranLibrary().getJuzByPageNumber(pageNumber: page - 1);
      final juz = ayah.juz;
      return juz >= 1 && juz <= 30 ? juz : null;
    } catch (e) {
      log('WirdScheduleService.juzForPage($page) failed: $e');
      return null;
    }
  }

  WirdDay _makeDay(int index, int start, int end, DateTime base) {
    final juz = juzForPage(start);
    return WirdDay(
      dayIndex: index,
      dayNumber: index + 1,
      startPage: start,
      endPage: end,
      date: base.add(Duration(days: index)),
      juzLabel: juz != null ? 'الجزء $juz' : '',
    );
  }

  /// Build the full schedule for [plan].
  List<WirdDay> buildSchedule(WirdPlanModel plan) {
    final startPage = plan.startPage.clamp(1, kTotalPages);
    final amount = plan.amountPerDay < 1 ? 1 : plan.amountPerDay;
    final base = _dateOnly(plan.planStartDate ?? DateTime.now());
    final days = <WirdDay>[];

    if (plan.unit == WirdUnit.pages) {
      var cursor = startPage;
      var index = 0;
      while (cursor <= kTotalPages) {
        final end = (cursor + amount - 1).clamp(1, kTotalPages);
        days.add(_makeDay(index, cursor, end, base));
        cursor = end + 1;
        index++;
      }
      return days;
    }

    // Unit-boundary modes (juz / hizb / rub): group `amount` segments per day.
    final allStarts = quranUnitStartPages(plan.unit);
    // Segment starts at or after the plan's start page. The first day always
    // begins exactly at startPage even if it falls mid-segment.
    final segStarts = <int>[startPage];
    for (final p in allStarts) {
      if (p > startPage && p <= kTotalPages) segStarts.add(p);
    }

    var index = 0;
    for (var i = 0; i < segStarts.length; i += amount) {
      final dayStart = segStarts[i];
      final nextIndex = i + amount;
      final dayEnd = nextIndex < segStarts.length
          ? segStarts[nextIndex] - 1
          : kTotalPages;
      days.add(_makeDay(index, dayStart, dayEnd.clamp(1, kTotalPages), base));
      index++;
    }
    return days;
  }

  /// Total number of days in the plan.
  int totalDays(WirdPlanModel plan) => buildSchedule(plan).length;

  /// Expected completion date — the date of the last day in the schedule.
  /// Uses `now` as the base when the plan hasn't started yet (setup preview).
  DateTime? expectedCompletionDate(WirdPlanModel plan) {
    final schedule = buildSchedule(plan);
    return schedule.isEmpty ? null : schedule.last.date;
  }

  /// Total pages covered by all completed days.
  int pagesReadCount(WirdPlanModel plan, [List<WirdDay>? schedule]) {
    final days = schedule ?? buildSchedule(plan);
    var total = 0;
    for (final d in days) {
      if (plan.completedDayIndices.contains(d.dayIndex)) total += d.pageCount;
    }
    return total;
  }

  /// Completion fraction in 0.0..1.0.
  double progressFraction(WirdPlanModel plan, [List<WirdDay>? schedule]) {
    final days = schedule ?? buildSchedule(plan);
    if (days.isEmpty) return 0;
    final completed = plan.completedDayIndices
        .where((i) => i >= 0 && i < days.length)
        .length;
    return (completed / days.length).clamp(0.0, 1.0);
  }

  /// Number of days not yet completed.
  int remainingDays(WirdPlanModel plan, [List<WirdDay>? schedule]) {
    final days = schedule ?? buildSchedule(plan);
    final completed = plan.completedDayIndices
        .where((i) => i >= 0 && i < days.length)
        .length;
    return (days.length - completed).clamp(0, days.length);
  }

  /// Index of "today" within the schedule, clamped to the valid range.
  /// Returns -1 if the plan hasn't started or has no days.
  int todayDayIndex(WirdPlanModel plan, [List<WirdDay>? schedule]) {
    final days = schedule ?? buildSchedule(plan);
    if (days.isEmpty || plan.planStartDate == null) return -1;
    final start = _dateOnly(plan.planStartDate!);
    final today = _dateOnly(DateTime.now());
    final diff = today.difference(start).inDays;
    return diff.clamp(0, days.length - 1);
  }

  /// Index of the "current wird" — the first day NOT marked complete. This is
  /// what the today card targets, and it only advances when the user marks the
  /// current day complete (so the plan never silently rolls forward). Returns
  /// -1 when every day is complete or there is no schedule.
  int currentDayIndex(WirdPlanModel plan, [List<WirdDay>? schedule]) {
    final days = schedule ?? buildSchedule(plan);
    if (days.isEmpty) return -1;
    for (var i = 0; i < days.length; i++) {
      if (!plan.completedDayIndices.contains(i)) return i;
    }
    return -1; // all complete
  }

  /// Derive the pace (late / on-track / ahead / finished) and current day.
  ///
  /// Forgiving model: the start day is never counted "late". `expected` is the
  /// number of *fully elapsed* days since the start, capped at the plan length;
  /// being behind/ahead is measured by the volume of completed days vs that.
  WirdProgressStatus progressStatus(
    WirdPlanModel plan, [
    List<WirdDay>? schedule,
    DateTime? now,
  ]) {
    final days = schedule ?? buildSchedule(plan);
    final total = days.length;
    if (total == 0 || plan.planStartDate == null || !plan.isActive) {
      return WirdProgressStatus.notStarted;
    }

    final start = _dateOnly(plan.planStartDate!);
    final today = _dateOnly(now ?? DateTime.now());
    final elapsed = today.difference(start).inDays;
    final expected = elapsed.clamp(0, total);
    final completed = plan.completedDayIndices
        .where((i) => i >= 0 && i < total)
        .length;

    final current = currentDayIndex(plan, days);
    final isFinished = completed >= total;
    if (isFinished) {
      return const WirdProgressStatus(
        pace: WirdPace.finished,
        daysLate: 0,
        daysAhead: 0,
        currentDayIndex: -1,
        isFinished: true,
      );
    }

    final daysLate = (expected - completed) > 0 ? expected - completed : 0;
    final daysAhead = (completed - expected) > 0 ? completed - expected : 0;
    final WirdPace pace = daysLate > 0
        ? WirdPace.behind
        : (daysAhead > 0 ? WirdPace.ahead : WirdPace.onTrack);

    return WirdProgressStatus(
      pace: pace,
      daysLate: daysLate,
      daysAhead: daysAhead,
      currentDayIndex: current,
      isFinished: false,
    );
  }
}
