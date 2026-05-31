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
        ),
      );
      return;
    }

    final schedule = _scheduleService.buildSchedule(plan);
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
      ),
    );
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
  Future<void> toggleDayComplete(int dayIndex) async {
    final plan = _currentPlan;
    if (plan == null || !plan.isActive) return;
    final updated = Set<int>.from(plan.completedDayIndices);
    if (updated.contains(dayIndex)) {
      updated.remove(dayIndex);
    } else {
      updated.add(dayIndex);
    }
    await _persist(plan.copyWith(completedDayIndices: updated));
  }

  Future<void> markDayComplete(int dayIndex) async {
    final plan = _currentPlan;
    if (plan == null || plan.completedDayIndices.contains(dayIndex)) return;
    final updated = Set<int>.from(plan.completedDayIndices)..add(dayIndex);
    await _persist(plan.copyWith(completedDayIndices: updated));
  }

  Future<void> markDayIncomplete(int dayIndex) async {
    final plan = _currentPlan;
    if (plan == null || !plan.completedDayIndices.contains(dayIndex)) return;
    final updated = Set<int>.from(plan.completedDayIndices)..remove(dayIndex);
    await _persist(plan.copyWith(completedDayIndices: updated));
  }

  /// Toggle today's completion.
  Future<void> toggleTodayComplete() async {
    final s = state;
    if (s is! WirdLoaded || s.todayDayIndex < 0) return;
    await toggleDayComplete(s.todayDayIndex);
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

  @override
  Future<void> close() {
    _planSubscription?.cancel();
    return super.close();
  }
}
