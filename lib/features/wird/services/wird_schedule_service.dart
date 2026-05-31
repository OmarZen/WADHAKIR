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
}
