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

  /// Last Mushaf page (1..604) the user stopped reading on, used to resume the
  /// reader at the exact page instead of restarting at the day's first page.
  /// Null when the user has not opened the reader yet, or after the current
  /// day is marked complete (so the next day resumes at its own start page).
  final int? lastReadPage;

  /// Who or what this khatma is dedicated to. [WirdIntention.none] by default.
  final WirdIntention intention;

  /// Free text accompanying [intention] — a name, usually. Null or empty when
  /// the user did not write one. Capped at [maxDedicationLength] on write so it
  /// always fits the reminder body and the completion card.
  final String? dedication;

  static const int maxDedicationLength = 60;

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
    this.lastReadPage,
    this.intention = WirdIntention.none,
    this.dedication,
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
      lastReadPage: null,
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
    Object? lastReadPage = _undefined,
    WirdIntention? intention,
    Object? dedication = _undefined,
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
      lastReadPage: lastReadPage == _undefined
          ? this.lastReadPage
          : lastReadPage as int?,
      intention: intention ?? this.intention,
      dedication: dedication == _undefined
          ? this.dedication
          : dedication as String?,
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
      'lastReadPage': lastReadPage,
      // Both omitted when unset, so an existing stored plan is byte-identical
      // until the user actually dedicates a khatma.
      if (intention != WirdIntention.none) 'intention': intention.index,
      if (dedication != null && dedication!.isNotEmpty)
        'dedication': dedication,
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
      lastReadPage: json['lastReadPage'] as int?,
      // Tolerant read: a plan stored before dedications existed simply has
      // neither key, so no migration is needed.
      intention:
          WirdIntention.values[(json['intention'] as int? ?? 0).clamp(
            0,
            WirdIntention.values.length - 1,
          )],
      dedication: json['dedication'] is String
          ? (json['dedication'] as String)
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
    lastReadPage,
    intention,
    dedication,
  ];

  @override
  String toString() =>
      'WirdPlanModel(active: $isActive, unit: $unit, amount: $amountPerDay, '
      'start: $startPage, completed: ${completedDayIndices.length})';
}
