import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';
import 'package:wadhakir/data/models/salah/salah_log_model.dart';

abstract class SalahTrackerState extends Equatable {
  const SalahTrackerState();

  @override
  List<Object?> get props => [];
}

class SalahTrackerInitial extends SalahTrackerState {
  const SalahTrackerInitial();
}

class SalahTrackerLoaded extends SalahTrackerState {
  /// The full persisted log (source of truth; widgets derive richer stats from
  /// it via SalahStatsService).
  final SalahLogModel log;

  /// The day the cheap derived fields below were computed for (normalized).
  final DateTime today;

  // Precomputed for cheap UI access (functions of [log] + [today]).
  final int currentStreak;
  final int bestStreak;
  final Map<PrayerSlot, PrayerStatus> todayStatuses;
  final double todayCompletion; // 0..1
  final int totalMakeUp;

  const SalahTrackerLoaded({
    required this.log,
    required this.today,
    required this.currentStreak,
    required this.bestStreak,
    required this.todayStatuses,
    required this.todayCompletion,
    required this.totalMakeUp,
  });

  /// Number of prayed fard today (0..5).
  int get todayPrayedCount =>
      todayStatuses.values.where((s) => s.isPrayed).length;

  @override
  List<Object?> get props => [log, today];
}

class SalahTrackerError extends SalahTrackerState {
  final String message;

  const SalahTrackerError(this.message);

  @override
  List<Object?> get props => [message];
}
