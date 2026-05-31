import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/fasting/fasting_reminder_settings_model.dart';
import 'package:wadhakir/data/models/fasting/islamic_fasting_day_model.dart';

/// Base state for fasting reminders
abstract class FastingRemindersState extends Equatable {
  const FastingRemindersState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class FastingRemindersInitial extends FastingRemindersState {
  const FastingRemindersInitial();
}

/// Loading state while fetching data
class FastingRemindersLoading extends FastingRemindersState {
  const FastingRemindersLoading();
}

/// Loaded state with fasting reminders data
class FastingRemindersLoaded extends FastingRemindersState {
  /// User's fasting reminder settings
  final FastingReminderSettings settings;

  /// List of upcoming fasting days (2 months: current + next)
  /// Used for notifications and home widgets
  final List<IslamicFastingDay> upcomingFastingDays;

  /// List of upcoming fasting days for the entire year
  /// Used for calendar display only
  final List<IslamicFastingDay> yearFastingDays;

  /// Days until the next fasting day
  final int? daysUntilNext;

  /// The next fasting day
  final IslamicFastingDay? nextFastingDay;

  /// Current Hijri month (1-12)
  final int currentHijriMonth;

  /// Current Hijri year
  final int currentHijriYear;

  /// Current Hijri day
  final int currentHijriDay;

  const FastingRemindersLoaded({
    required this.settings,
    required this.upcomingFastingDays,
    required this.yearFastingDays,
    required this.currentHijriMonth,
    required this.currentHijriYear,
    required this.currentHijriDay,
    this.daysUntilNext,
    this.nextFastingDay,
  });

  /// Create a copy with updated fields
  FastingRemindersLoaded copyWith({
    FastingReminderSettings? settings,
    List<IslamicFastingDay>? upcomingFastingDays,
    List<IslamicFastingDay>? yearFastingDays,
    int? daysUntilNext,
    IslamicFastingDay? nextFastingDay,
    int? currentHijriMonth,
    int? currentHijriYear,
    int? currentHijriDay,
  }) {
    return FastingRemindersLoaded(
      settings: settings ?? this.settings,
      upcomingFastingDays: upcomingFastingDays ?? this.upcomingFastingDays,
      yearFastingDays: yearFastingDays ?? this.yearFastingDays,
      daysUntilNext: daysUntilNext ?? this.daysUntilNext,
      nextFastingDay: nextFastingDay ?? this.nextFastingDay,
      currentHijriMonth: currentHijriMonth ?? this.currentHijriMonth,
      currentHijriYear: currentHijriYear ?? this.currentHijriYear,
      currentHijriDay: currentHijriDay ?? this.currentHijriDay,
    );
  }

  @override
  List<Object?> get props => [
    settings,
    upcomingFastingDays,
    yearFastingDays,
    daysUntilNext,
    nextFastingDay,
    currentHijriMonth,
    currentHijriYear,
    currentHijriDay,
  ];
}

/// Error state when something goes wrong
class FastingRemindersError extends FastingRemindersState {
  final String message;

  const FastingRemindersError(this.message);

  @override
  List<Object?> get props => [message];
}
