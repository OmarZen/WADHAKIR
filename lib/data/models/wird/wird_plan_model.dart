import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/wird/wird_enums.dart';

// Sentinel to distinguish "not provided" from "explicitly set to null" in
// copyWith — same pattern as FastingReminderSettings.
const Object _undefined = Object();

/// Persisted configuration + progress for the Quran wird (ختم القرآن) plan.
///
/// Design decision: the daily schedule is NOT stored. It is a pure function
/// of (unit, amountPerDay, startPage, planStartDate) computed on the fly by
/// [WirdScheduleService]. We persist only the configuration and the set of
/// completed day indices, which keeps storage compact and avoids stale
/// day-rows if the configuration ever changes.
class WirdPlanModel extends Equatable {
  /// Whether a plan is currently active. When false the UI shows the setup
  /// screen; when true it shows the progress screen.
  final bool isActive;

  /// Goal type. Only [WirdGoalMode.fixedDailyAmount] is implemented now.
  final WirdGoalMode goalMode;

  /// Tracking unit (pages / rub / hizb / juz).
  final WirdUnit unit;

  /// Amount of [unit]s to read per day.
  final int amountPerDay;

  /// First Mushaf page of the plan (1..604).
  final int startPage;

  /// Daily reminder time in 24-hour `HH:mm` format.
  final String reminderTime;

  /// Whether the daily reminder notification is enabled.
  final bool reminderEnabled;

  /// Date the plan was started (date-only). Null when inactive.
  final DateTime? planStartDate;

  /// 0-based indices of days the user has marked complete.
  final Set<int> completedDayIndices;

  /// Optional target completion date — only used by the future
  /// [WirdGoalMode.finishByDate] mode. Kept for forward-compat.
  final DateTime? targetDate;

  const WirdPlanModel({
    required this.isActive,
    required this.goalMode,
    required this.unit,
    required this.amountPerDay,
    required this.startPage,
    required this.reminderTime,
    required this.reminderEnabled,
    required this.completedDayIndices,
    this.planStartDate,
    this.targetDate,
  });

  /// Default (inactive) plan — the setup screen is shown.
  factory WirdPlanModel.defaultSettings() {
    return const WirdPlanModel(
      isActive: false,
      goalMode: WirdGoalMode.fixedDailyAmount,
      unit: WirdUnit.pages,
      amountPerDay: 4,
      startPage: 1,
      reminderTime: '20:00',
      reminderEnabled: true,
      completedDayIndices: <int>{},
      planStartDate: null,
      targetDate: null,
    );
  }

  WirdPlanModel copyWith({
    bool? isActive,
    WirdGoalMode? goalMode,
    WirdUnit? unit,
    int? amountPerDay,
    int? startPage,
    String? reminderTime,
    bool? reminderEnabled,
    Set<int>? completedDayIndices,
    Object? planStartDate = _undefined,
    Object? targetDate = _undefined,
  }) {
    return WirdPlanModel(
      isActive: isActive ?? this.isActive,
      goalMode: goalMode ?? this.goalMode,
      unit: unit ?? this.unit,
      amountPerDay: amountPerDay ?? this.amountPerDay,
      startPage: startPage ?? this.startPage,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      completedDayIndices: completedDayIndices ?? this.completedDayIndices,
      planStartDate: planStartDate == _undefined
          ? this.planStartDate
          : planStartDate as DateTime?,
      targetDate: targetDate == _undefined
          ? this.targetDate
          : targetDate as DateTime?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'goalMode': goalMode.index,
      'unit': unit.index,
      'amountPerDay': amountPerDay,
      'startPage': startPage,
      'reminderTime': reminderTime,
      'reminderEnabled': reminderEnabled,
      'completedDayIndices': completedDayIndices.toList(),
      'planStartDate': planStartDate?.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
    };
  }

  factory WirdPlanModel.fromJson(Map<String, dynamic> json) {
    return WirdPlanModel(
      isActive: json['isActive'] as bool? ?? false,
      goalMode:
          WirdGoalMode.values[(json['goalMode'] as int? ?? 0).clamp(
            0,
            WirdGoalMode.values.length - 1,
          )],
      unit:
          WirdUnit.values[(json['unit'] as int? ?? 0).clamp(
            0,
            WirdUnit.values.length - 1,
          )],
      amountPerDay: json['amountPerDay'] as int? ?? 4,
      startPage: json['startPage'] as int? ?? 1,
      reminderTime: json['reminderTime'] as String? ?? '20:00',
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      completedDayIndices:
          (json['completedDayIndices'] as List?)
              ?.map((e) => e as int)
              .toSet() ??
          <int>{},
      planStartDate: json['planStartDate'] != null
          ? DateTime.tryParse(json['planStartDate'] as String)
          : null,
      targetDate: json['targetDate'] != null
          ? DateTime.tryParse(json['targetDate'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    isActive,
    goalMode,
    unit,
    amountPerDay,
    startPage,
    reminderTime,
    reminderEnabled,
    completedDayIndices,
    planStartDate,
    targetDate,
  ];

  @override
  String toString() =>
      'WirdPlanModel(active: $isActive, unit: $unit, amount: $amountPerDay, '
      'start: $startPage, completed: ${completedDayIndices.length})';
}
