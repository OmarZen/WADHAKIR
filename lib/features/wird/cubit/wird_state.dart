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

  /// Index of "today" within the schedule, or -1 if not applicable.
  final int todayDayIndex;

  const WirdLoaded({
    required this.plan,
    required this.schedule,
    required this.totalDays,
    required this.pagesRead,
    required this.progress,
    required this.expectedCompletionDate,
    required this.remainingDays,
    required this.todayDayIndex,
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
  ];
}

class WirdError extends WirdState {
  final String message;

  const WirdError(this.message);

  @override
  List<Object?> get props => [message];
}
