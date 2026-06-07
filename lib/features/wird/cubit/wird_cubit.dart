import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_library/quran_library.dart';
import 'package:wadhakir/data/models/wird/wird_enums.dart';
import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/domain/usecases/get_wird_plan_usecase.dart';
import 'package:wadhakir/domain/usecases/set_wird_plan_usecase.dart';
import 'package:wadhakir/domain/usecases/get_wird_plan_stream_usecase.dart';
import 'package:wadhakir/domain/usecases/clear_wird_plan_usecase.dart';
import 'package:wadhakir/features/wird/cubit/wird_state.dart';
import 'package:wadhakir/features/wird/services/wird_schedule_service.dart';
import 'package:wadhakir/features/wird/services/wird_notification_service.dart';
import 'package:wadhakir/features/home_screen_widgets/presentation/widgets/wird_home_widget.dart';

/// Cubit managing the Quran wird (ختم القرآن) plan.
/// Mirrors FastingRemindersCubit: load + emit immediately, schedule
/// notifications fire-and-forget.
class WirdCubit extends Cubit<WirdState> {
  final GetWirdPlanUseCase _getPlanUseCase;
  final SetWirdPlanUseCase _setPlanUseCase;
  final GetWirdPlanStreamUseCase _getPlanStreamUseCase;
  final ClearWirdPlanUseCase _clearPlanUseCase;
  final WirdScheduleService _scheduleService;
  final WirdNotificationService _notificationService;

  StreamSubscription? _planSubscription;

  WirdCubit({
    required this._getPlanUseCase,
    required this._setPlanUseCase,
    required this._getPlanStreamUseCase,
    required this._clearPlanUseCase,
    WirdScheduleService? scheduleService,
    WirdNotificationService? notificationService,
  }) : _scheduleService = scheduleService ?? const WirdScheduleService(),
       _notificationService = notificationService ?? WirdNotificationService(),
       super(const WirdInitial()) {
    loadPlan();
    _listenToPlanChanges();
  }

  void _listenToPlanChanges() {
    _planSubscription = _getPlanStreamUseCase().listen(
      _updateStateWithPlan,
      onError: (error) => emit(WirdError(error.toString())),
    );
  }

  void _updateStateWithPlan(WirdPlanModel plan) {
    if (!plan.isActive) {
      emit(
        WirdLoaded(
          plan: plan,
          schedule: const [],
          totalDays: 0,
          pagesRead: 0,
          progress: 0,
          expectedCompletionDate: null,
          remainingDays: 0,
          todayDayIndex: -1,
          currentDayIndex: -1,
          daysLate: 0,
          daysAhead: 0,
          pace: WirdPace.notStarted,
          isFinished: false,
        ),
      );
      unawaited(WirdHomeWidget.update(plan, const [], WirdProgressStatus.notStarted));
      return;
    }

    final schedule = _scheduleService.buildSchedule(plan);
    final status = _scheduleService.progressStatus(plan, schedule);
    emit(
      WirdLoaded(
        plan: plan,
        schedule: schedule,
        totalDays: schedule.length,
        pagesRead: _scheduleService.pagesReadCount(plan, schedule),
        progress: _scheduleService.progressFraction(plan, schedule),
        expectedCompletionDate: schedule.isEmpty ? null : schedule.last.date,
        remainingDays: _scheduleService.remainingDays(plan, schedule),
        todayDayIndex: _scheduleService.todayDayIndex(plan, schedule),
        currentDayIndex: status.currentDayIndex,
        daysLate: status.daysLate,
        daysAhead: status.daysAhead,
        pace: status.pace,
        isFinished: status.isFinished,
      ),
    );
    unawaited(WirdHomeWidget.update(plan, schedule, status));
  }

  Future<void> loadPlan() async {
    emit(const WirdLoading());
    try {
      final plan = await _getPlanUseCase();
      _updateStateWithPlan(plan);
      unawaited(_scheduleSafely(plan));
    } catch (e, st) {
      log('🟥 WirdCubit.loadPlan: ERROR $e\n$st');
      emit(WirdError(e.toString()));
    }
  }

  Future<void> _persist(WirdPlanModel plan) async {
    try {
      await _setPlanUseCase(plan);
      // State updates via the plan stream.
      unawaited(_scheduleSafely(plan));
    } catch (e, st) {
      log('🟥 WirdCubit._persist: ERROR $e\n$st');
      emit(WirdError(e.toString()));
    }
  }

  Future<void> _scheduleSafely(WirdPlanModel plan) async {
    try {
      await _notificationService.scheduleDailyReminder(plan);
    } catch (e) {
      log('🟥 WirdCubit._scheduleSafely: $e');
    }
  }

  /// Start a new plan from the setup screen.
  Future<void> startPlan({
    required WirdUnit unit,
    required int amountPerDay,
    required int startPage,
    required String reminderTime,
    bool reminderEnabled = true,
  }) async {
    final now = DateTime.now();
    final plan = WirdPlanModel(
      isActive: true,
      goalMode: WirdGoalMode.fixedDailyAmount,
      unit: unit,
      amountPerDay: amountPerDay < 1 ? 1 : amountPerDay,
      startPage: startPage.clamp(1, 604),
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
      completedDayIndices: const <int>{},
      planStartDate: DateTime(now.year, now.month, now.day),
    );
    await _persist(plan);
  }

  WirdPlanModel? get _currentPlan {
    final s = state;
    return s is WirdLoaded ? s.plan : null;
  }

  /// Toggle a day's completion (works for any day index — past or future).
  ///
  /// When the day being *completed* is the current wird, also clear
  /// [WirdPlanModel.lastReadPage] so the next day resumes at its own first
  /// page instead of a stale mid-page from this day.
  Future<void> toggleDayComplete(int dayIndex) async {
    final plan = _currentPlan;
    if (plan == null || !plan.isActive) return;
    final wasCurrent =
        _scheduleService.currentDayIndex(plan) == dayIndex;
    final updated = Set<int>.from(plan.completedDayIndices);
    final isCompleting = !updated.contains(dayIndex);
    if (isCompleting) {
      updated.add(dayIndex);
    } else {
      updated.remove(dayIndex);
    }
    final shouldClearPage = isCompleting && wasCurrent;
    // Pass lastReadPage: null only when clearing — omitting it leaves the
    // stored page unchanged (copyWith uses a private sentinel).
    final next = shouldClearPage
        ? plan.copyWith(completedDayIndices: updated, lastReadPage: null)
        : plan.copyWith(completedDayIndices: updated);
    await _persist(next);
  }

  Future<void> markDayComplete(int dayIndex) async {
    final plan = _currentPlan;
    if (plan == null || plan.completedDayIndices.contains(dayIndex)) return;
    final wasCurrent = _scheduleService.currentDayIndex(plan) == dayIndex;
    final updated = Set<int>.from(plan.completedDayIndices)..add(dayIndex);
    final next = wasCurrent
        ? plan.copyWith(completedDayIndices: updated, lastReadPage: null)
        : plan.copyWith(completedDayIndices: updated);
    await _persist(next);
  }

  Future<void> markDayIncomplete(int dayIndex) async {
    final plan = _currentPlan;
    if (plan == null || !plan.completedDayIndices.contains(dayIndex)) return;
    final updated = Set<int>.from(plan.completedDayIndices)..remove(dayIndex);
    await _persist(plan.copyWith(completedDayIndices: updated));
  }

  /// Toggle the current wird's completion (the first incomplete day).
  Future<void> toggleTodayComplete() async {
    final s = state;
    if (s is! WirdLoaded || s.currentDayIndex < 0) return;
    await toggleDayComplete(s.currentDayIndex);
  }

  Future<void> updateReminderTime(String hhmm) async {
    final plan = _currentPlan;
    if (plan == null) return;
    await _persist(plan.copyWith(reminderTime: hhmm));
  }

  Future<void> setReminderEnabled(bool enabled) async {
    final plan = _currentPlan;
    if (plan == null) return;
    await _persist(plan.copyWith(reminderEnabled: enabled));
  }

  /// Reset (delete) the plan — "إعادة ضبط الختمة".
  Future<void> resetPlan() async {
    try {
      await _notificationService.cancel();
      await _clearPlanUseCase();
    } catch (e, st) {
      log('🟥 WirdCubit.resetPlan: ERROR $e\n$st');
      emit(WirdError(e.toString()));
    }
  }

  /// Open the in-app Quran reader at [page] (1-based).
  void openReaderAtPage(int page) {
    try {
      QuranLibrary().jumpToPage(page);
    } catch (e) {
      log('🟥 WirdCubit.openReaderAtPage($page): $e');
    }
  }

  /// Page (1-based) at which the reader should open for the current wird.
  ///
  /// Returns the user's saved [WirdPlanModel.lastReadPage] when it lies within
  /// the current day's page range (resume where they stopped); otherwise the
  /// current day's first page. Falls back to the schedule's first page / 1.
  int resumePageForCurrentDay() {
    final s = state;
    if (s is! WirdLoaded || s.schedule.isEmpty) return 1;
    final idx = s.currentDayIndex;
    if (idx < 0 || idx >= s.schedule.length) {
      return s.schedule.first.startPage;
    }
    final day = s.schedule[idx];
    final last = s.plan.lastReadPage;
    if (last != null && last >= day.startPage && last <= day.endPage) {
      return last;
    }
    return day.startPage;
  }

  /// Whether the current wird has a saved resume point past its first page
  /// (used to switch the read button between "اقرأ الآن" and "متابعة القراءة").
  bool get hasResumePoint {
    final s = state;
    if (s is! WirdLoaded || s.currentDayIndex < 0) return false;
    if (s.currentDayIndex >= s.schedule.length) return false;
    final day = s.schedule[s.currentDayIndex];
    return resumePageForCurrentDay() > day.startPage;
  }

  /// Persist the exact page the user stopped on after leaving the reader, so
  /// the next "متابعة القراءة" resumes there. Reads the live current page from
  /// the Quran library; out-of-range values are harmless because
  /// [resumePageForCurrentDay] validates against the current day's range.
  Future<void> saveReaderStopPage() async {
    final plan = _currentPlan;
    if (plan == null || !plan.isActive) return;
    try {
      final page = QuranLibrary().currentPageNumber;
      if (page < 1) return;
      final clamped = page.clamp(1, 604);
      if (clamped == plan.lastReadPage) return;
      await _persist(plan.copyWith(lastReadPage: clamped));
    } catch (e) {
      log('🟥 WirdCubit.saveReaderStopPage: $e');
    }
  }

  @override
  Future<void> close() {
    _planSubscription?.cancel();
    return super.close();
  }
}
