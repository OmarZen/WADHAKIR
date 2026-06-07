import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/features/wird/services/wird_schedule_service.dart';

/// Base state for the wird feature.
abstract class WirdState extends Equatable {
  const WirdState();

  @override
  List<Object?> get props => [];
}

class WirdInitial extends WirdState {
  const WirdInitial();
}

class WirdLoading extends WirdState {
  const WirdLoading();
}

/// Loaded state. When [plan.isActive] is false the schedule is empty and the
/// UI shows the setup screen; otherwise it shows progress.
class WirdLoaded extends WirdState {
  final WirdPlanModel plan;
  final List<WirdDay> schedule;
  final int totalDays;
  final int pagesRead;
  final double progress;
  final DateTime? expectedCompletionDate;
  final int remainingDays;

  /// Index of "today" within the schedule (pure-calendar), or -1 if not
  /// applicable. Used only for the schedule list's "today" highlight.
  final int todayDayIndex;

  /// Index of the "current wird" — the first incomplete day the user should
  /// read. Advances only when the current day is marked complete. -1 when
  /// finished or inactive.
  final int currentDayIndex;

  /// Days behind schedule (متأخر). 0 unless [pace] is behind.
  final int daysLate;

  /// Days ahead of schedule (متقدم). 0 unless [pace] is ahead.
  final int daysAhead;

  /// Overall pace relative to the plan.
  final WirdPace pace;

  /// Whether every day has been completed (the ختمة is done).
  final bool isFinished;

  const WirdLoaded({
    required this.plan,
    required this.schedule,
    required this.totalDays,
    required this.pagesRead,
    required this.progress,
    required this.expectedCompletionDate,
    required this.remainingDays,
    required this.todayDayIndex,
    required this.currentDayIndex,
    required this.daysLate,
    required this.daysAhead,
    required this.pace,
    required this.isFinished,
  });

  @override
  List<Object?> get props => [
    plan,
    schedule.length,
    totalDays,
    pagesRead,
    progress,
    expectedCompletionDate,
    remainingDays,
    todayDayIndex,
    currentDayIndex,
    daysLate,
    daysAhead,
    pace,
    isFinished,
  ];
}

class WirdError extends WirdState {
  final String message;

  const WirdError(this.message);

  @override
  List<Object?> get props => [message];
}
