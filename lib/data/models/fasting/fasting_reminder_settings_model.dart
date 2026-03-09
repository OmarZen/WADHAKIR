import 'package:equatable/equatable.dart';

// Sentinel value to distinguish between "not provided" and "explicitly set to null"
const Object _undefined = Object();

/// Model for fasting reminder settings
/// Manages user preferences for monthly, weekly, and special fasting day notifications
class FastingReminderSettings extends Equatable {
  // === Hijri Calendar Fasting Settings ===

  /// Master toggle for all monthly fasting reminders
  final bool monthlyFastingRemindersEnabled;

  /// Enable reminders for Ayyam al-Bid (13th, 14th, 15th of each month)
  final bool ayyamAlBidEnabled;

  /// Enable reminders for 9th and 10th of each month
  final bool ninthTenthEnabled;

  /// Enable special emphasis for Muharram and Dhul Hijjah days
  final bool specialDaysEmphasis;

  // === Weekly Fasting Settings ===

  /// Enable reminders for Monday fasting
  final bool mondayFastingEnabled;

  /// Enable reminders for Thursday fasting
  final bool thursdayFastingEnabled;

  // === Notification Preferences ===

  /// Number of days before to send notification (1, 2, or 3)
  final int daysBeforeNotification;

  /// Send reminder on the eve of the fasting day (after Maghrib)
  final bool eveReminder;

  /// Send reminder on the morning of the fasting day
  final bool morningReminder;

  /// Send advance reminder X days before fasting day
  final bool advanceReminder;

  /// Enable vibration for fasting notifications
  final bool vibration;

  /// Notification time for weekly fasting reminders (HH:mm format, 24-hour)
  /// Default is 21:00 (9 PM) the night before
  final String weeklyNotificationTime;

  /// Eve reminder notification time (HH:mm format, 24-hour)
  /// Time to send notification on the night before fasting day
  /// Default is 18:00 (6 PM - after Maghrib)
  final String eveReminderTime;

  /// Morning reminder notification time (HH:mm format, 24-hour)
  /// Time to send notification on the morning of fasting day
  /// Default is 05:00 (5 AM - around Fajr)
  final String morningReminderTime;

  /// Advance reminder notification time (HH:mm format, 24-hour)
  /// Time to send notification X days before fasting day
  /// Default is 20:00 (8 PM)
  final String advanceReminderTime;

  /// Timestamp of the last notification sent (to avoid duplicates)
  final DateTime? lastNotificationSent;

  /// Custom notification time for morning reminders (HH:mm format)
  /// Default is Fajr time
  final String? customMorningTime;

  const FastingReminderSettings({
    // Hijri calendar fasting
    required this.monthlyFastingRemindersEnabled,
    required this.ayyamAlBidEnabled,
    required this.ninthTenthEnabled,
    required this.specialDaysEmphasis,
    // Weekly fasting
    required this.mondayFastingEnabled,
    required this.thursdayFastingEnabled,
    // Notification preferences
    required this.daysBeforeNotification,
    required this.eveReminder,
    required this.morningReminder,
    required this.advanceReminder,
    required this.vibration,
    required this.weeklyNotificationTime,
    required this.eveReminderTime,
    required this.morningReminderTime,
    required this.advanceReminderTime,
    this.lastNotificationSent,
    this.customMorningTime,
  });

  /// Factory constructor for default settings
  factory FastingReminderSettings.defaultSettings() {
    return const FastingReminderSettings(
      // Hijri calendar defaults - ALL OFF by default
      monthlyFastingRemindersEnabled: false,
      ayyamAlBidEnabled: false,
      ninthTenthEnabled: false,
      specialDaysEmphasis: false,
      // Weekly fasting defaults
      mondayFastingEnabled: false,
      thursdayFastingEnabled: false,
      // Notification preferences defaults
      daysBeforeNotification: 1,
      eveReminder: false,
      morningReminder: false,
      advanceReminder: false,
      vibration: true,
      weeklyNotificationTime: '21:00', // 9 PM the night before
      eveReminderTime: '18:00', // 6 PM - after Maghrib
      morningReminderTime: '05:00', // 5 AM - around Fajr
      advanceReminderTime: '20:00', // 8 PM
      lastNotificationSent: null,
      customMorningTime: null,
    );
  }

  /// Create a copy with optional field updates
  FastingReminderSettings copyWith({
    // Hijri calendar fasting
    bool? monthlyFastingRemindersEnabled,
    bool? ayyamAlBidEnabled,
    bool? ninthTenthEnabled,
    bool? specialDaysEmphasis,
    // Weekly fasting
    bool? mondayFastingEnabled,
    bool? thursdayFastingEnabled,
    // Notification preferences
    int? daysBeforeNotification,
    bool? eveReminder,
    bool? morningReminder,
    bool? advanceReminder,
    bool? vibration,
    String? weeklyNotificationTime,
    String? eveReminderTime,
    String? morningReminderTime,
    String? advanceReminderTime,
    Object? lastNotificationSent = _undefined,
    Object? customMorningTime = _undefined,
  }) {
    return FastingReminderSettings(
      // Hijri calendar
      monthlyFastingRemindersEnabled:
          monthlyFastingRemindersEnabled ?? this.monthlyFastingRemindersEnabled,
      ayyamAlBidEnabled: ayyamAlBidEnabled ?? this.ayyamAlBidEnabled,
      ninthTenthEnabled: ninthTenthEnabled ?? this.ninthTenthEnabled,
      specialDaysEmphasis: specialDaysEmphasis ?? this.specialDaysEmphasis,
      // Weekly fasting
      mondayFastingEnabled: mondayFastingEnabled ?? this.mondayFastingEnabled,
      thursdayFastingEnabled:
          thursdayFastingEnabled ?? this.thursdayFastingEnabled,
      // Notification preferences
      daysBeforeNotification:
          daysBeforeNotification ?? this.daysBeforeNotification,
      eveReminder: eveReminder ?? this.eveReminder,
      morningReminder: morningReminder ?? this.morningReminder,
      advanceReminder: advanceReminder ?? this.advanceReminder,
      vibration: vibration ?? this.vibration,
      weeklyNotificationTime:
          weeklyNotificationTime ?? this.weeklyNotificationTime,
      eveReminderTime: eveReminderTime ?? this.eveReminderTime,
      morningReminderTime: morningReminderTime ?? this.morningReminderTime,
      advanceReminderTime: advanceReminderTime ?? this.advanceReminderTime,
      lastNotificationSent: lastNotificationSent == _undefined
          ? this.lastNotificationSent
          : lastNotificationSent as DateTime?,
      customMorningTime: customMorningTime == _undefined
          ? this.customMorningTime
          : customMorningTime as String?,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      // Hijri calendar fasting
      'monthlyFastingRemindersEnabled': monthlyFastingRemindersEnabled,
      'ayyamAlBidEnabled': ayyamAlBidEnabled,
      'ninthTenthEnabled': ninthTenthEnabled,
      'specialDaysEmphasis': specialDaysEmphasis,
      // Weekly fasting
      'mondayFastingEnabled': mondayFastingEnabled,
      'thursdayFastingEnabled': thursdayFastingEnabled,
      // Notification preferences
      'daysBeforeNotification': daysBeforeNotification,
      'eveReminder': eveReminder,
      'morningReminder': morningReminder,
      'advanceReminder': advanceReminder,
      'vibration': vibration,
      'weeklyNotificationTime': weeklyNotificationTime,
      'eveReminderTime': eveReminderTime,
      'morningReminderTime': morningReminderTime,
      'advanceReminderTime': advanceReminderTime,
      'lastNotificationSent': lastNotificationSent?.toIso8601String(),
      'customMorningTime': customMorningTime,
    };
  }

  /// Create from JSON
  factory FastingReminderSettings.fromJson(Map<String, dynamic> json) {
    return FastingReminderSettings(
      // Hijri calendar fasting
      monthlyFastingRemindersEnabled:
          json['monthlyFastingRemindersEnabled'] as bool? ?? true,
      ayyamAlBidEnabled: json['ayyamAlBidEnabled'] as bool? ?? true,
      ninthTenthEnabled: json['ninthTenthEnabled'] as bool? ?? false,
      specialDaysEmphasis: json['specialDaysEmphasis'] as bool? ?? true,
      // Weekly fasting - migrate from old settings if present
      mondayFastingEnabled: json['mondayFastingEnabled'] as bool? ?? false,
      thursdayFastingEnabled: json['thursdayFastingEnabled'] as bool? ?? false,
      // Notification preferences
      daysBeforeNotification: json['daysBeforeNotification'] as int? ?? 1,
      eveReminder: json['eveReminder'] as bool? ?? true,
      morningReminder: json['morningReminder'] as bool? ?? true,
      advanceReminder: json['advanceReminder'] as bool? ?? true,
      vibration: json['vibration'] as bool? ?? true,
      weeklyNotificationTime:
          json['weeklyNotificationTime'] as String? ?? '21:00',
      eveReminderTime: json['eveReminderTime'] as String? ?? '18:00',
      morningReminderTime: json['morningReminderTime'] as String? ?? '05:00',
      advanceReminderTime: json['advanceReminderTime'] as String? ?? '20:00',
      lastNotificationSent: json['lastNotificationSent'] != null
          ? DateTime.parse(json['lastNotificationSent'] as String)
          : null,
      customMorningTime: json['customMorningTime'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        // Hijri calendar fasting
        monthlyFastingRemindersEnabled,
        ayyamAlBidEnabled,
        ninthTenthEnabled,
        specialDaysEmphasis,
        // Weekly fasting
        mondayFastingEnabled,
        thursdayFastingEnabled,
        // Notification preferences
        daysBeforeNotification,
        eveReminder,
        morningReminder,
        advanceReminder,
        vibration,
        weeklyNotificationTime,
        eveReminderTime,
        morningReminderTime,
        advanceReminderTime,
        lastNotificationSent,
        customMorningTime,
      ];

  @override
  String toString() {
    return 'FastingReminderSettings('
        'monthly: $monthlyFastingRemindersEnabled, '
        'ayyamAlBid: $ayyamAlBidEnabled, '
        'ninthTenth: $ninthTenthEnabled, '
        'monday: $mondayFastingEnabled, '
        'thursday: $thursdayFastingEnabled, '
        'special: $specialDaysEmphasis)';
  }
}
