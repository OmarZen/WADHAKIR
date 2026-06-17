import 'package:equatable/equatable.dart';

/// How the Qiyam al-Layl reminder time is derived.
enum QiyamMode {
  /// Auto: the last third of the night, computed from prayer times.
  lastThird,

  /// A fixed time the user picks.
  fixed,
}

/// User preferences for the daily azkar reminders feature.
///
/// All reminders default OFF (opt-in). "Repeating" reminders (morning, evening,
/// witr, sleep, Friday Al-Kahf, and fixed-mode Qiyam) are scheduled by
/// [AzkarRemindersCubit]; "prayer-driven" ones (after-each-prayer, Duha, and
/// last-third Qiyam) are scheduled from [PrayerTimesCubit] because they depend
/// on the day's computed prayer times.
class AzkarReminderSettingsModel extends Equatable {
  // Morning azkar — daily, repeating.
  final bool morningEnabled;
  final int morningHour;
  final int morningMinute;

  // Evening azkar — daily, repeating.
  final bool eveningEnabled;
  final int eveningHour;
  final int eveningMinute;

  // After each of the 5 prayers — one-shot at prayerTime + delay.
  final bool afterPrayerEnabled;
  final int afterPrayerDelayMinutes;

  // Qiyam al-Layl.
  final bool qiyamEnabled;
  final QiyamMode qiyamMode;
  final int qiyamHour; // used only when qiyamMode == fixed
  final int qiyamMinute;

  // ── Extras ──────────────────────────────────────────────────────────────
  // Friday: Surah Al-Kahf + salah ʿala an-Nabi — weekly (Friday), repeating.
  final bool fridayKahfEnabled;
  final int fridayKahfHour;
  final int fridayKahfMinute;

  // Witr — daily fixed, repeating.
  final bool witrEnabled;
  final int witrHour;
  final int witrMinute;

  // Duha — one-shot at sunrise + offset.
  final bool duhaEnabled;
  final int duhaOffsetMinutes;

  // Sleeping azkar — daily fixed, repeating.
  final bool sleepEnabled;
  final int sleepHour;
  final int sleepMinute;

  const AzkarReminderSettingsModel({
    required this.morningEnabled,
    required this.morningHour,
    required this.morningMinute,
    required this.eveningEnabled,
    required this.eveningHour,
    required this.eveningMinute,
    required this.afterPrayerEnabled,
    required this.afterPrayerDelayMinutes,
    required this.qiyamEnabled,
    required this.qiyamMode,
    required this.qiyamHour,
    required this.qiyamMinute,
    required this.fridayKahfEnabled,
    required this.fridayKahfHour,
    required this.fridayKahfMinute,
    required this.witrEnabled,
    required this.witrHour,
    required this.witrMinute,
    required this.duhaEnabled,
    required this.duhaOffsetMinutes,
    required this.sleepEnabled,
    required this.sleepHour,
    required this.sleepMinute,
  });

  factory AzkarReminderSettingsModel.defaultSettings() {
    return const AzkarReminderSettingsModel(
      morningEnabled: false,
      morningHour: 6,
      morningMinute: 30,
      eveningEnabled: false,
      eveningHour: 17,
      eveningMinute: 0,
      afterPrayerEnabled: false,
      afterPrayerDelayMinutes: 20,
      qiyamEnabled: false,
      qiyamMode: QiyamMode.lastThird,
      qiyamHour: 3,
      qiyamMinute: 30,
      fridayKahfEnabled: false,
      fridayKahfHour: 9,
      fridayKahfMinute: 0,
      witrEnabled: false,
      witrHour: 22,
      witrMinute: 30,
      duhaEnabled: false,
      duhaOffsetMinutes: 20,
      sleepEnabled: false,
      sleepHour: 22,
      sleepMinute: 0,
    );
  }

  /// True when at least one reminder is enabled — used by feature-discovery
  /// (so the "enable azkar reminders" nudge stops) and the home card subtitle.
  bool get anyEnabled =>
      morningEnabled ||
      eveningEnabled ||
      afterPrayerEnabled ||
      qiyamEnabled ||
      fridayKahfEnabled ||
      witrEnabled ||
      duhaEnabled ||
      sleepEnabled;

  AzkarReminderSettingsModel copyWith({
    bool? morningEnabled,
    int? morningHour,
    int? morningMinute,
    bool? eveningEnabled,
    int? eveningHour,
    int? eveningMinute,
    bool? afterPrayerEnabled,
    int? afterPrayerDelayMinutes,
    bool? qiyamEnabled,
    QiyamMode? qiyamMode,
    int? qiyamHour,
    int? qiyamMinute,
    bool? fridayKahfEnabled,
    int? fridayKahfHour,
    int? fridayKahfMinute,
    bool? witrEnabled,
    int? witrHour,
    int? witrMinute,
    bool? duhaEnabled,
    int? duhaOffsetMinutes,
    bool? sleepEnabled,
    int? sleepHour,
    int? sleepMinute,
  }) {
    return AzkarReminderSettingsModel(
      morningEnabled: morningEnabled ?? this.morningEnabled,
      morningHour: morningHour ?? this.morningHour,
      morningMinute: morningMinute ?? this.morningMinute,
      eveningEnabled: eveningEnabled ?? this.eveningEnabled,
      eveningHour: eveningHour ?? this.eveningHour,
      eveningMinute: eveningMinute ?? this.eveningMinute,
      afterPrayerEnabled: afterPrayerEnabled ?? this.afterPrayerEnabled,
      afterPrayerDelayMinutes:
          afterPrayerDelayMinutes ?? this.afterPrayerDelayMinutes,
      qiyamEnabled: qiyamEnabled ?? this.qiyamEnabled,
      qiyamMode: qiyamMode ?? this.qiyamMode,
      qiyamHour: qiyamHour ?? this.qiyamHour,
      qiyamMinute: qiyamMinute ?? this.qiyamMinute,
      fridayKahfEnabled: fridayKahfEnabled ?? this.fridayKahfEnabled,
      fridayKahfHour: fridayKahfHour ?? this.fridayKahfHour,
      fridayKahfMinute: fridayKahfMinute ?? this.fridayKahfMinute,
      witrEnabled: witrEnabled ?? this.witrEnabled,
      witrHour: witrHour ?? this.witrHour,
      witrMinute: witrMinute ?? this.witrMinute,
      duhaEnabled: duhaEnabled ?? this.duhaEnabled,
      duhaOffsetMinutes: duhaOffsetMinutes ?? this.duhaOffsetMinutes,
      sleepEnabled: sleepEnabled ?? this.sleepEnabled,
      sleepHour: sleepHour ?? this.sleepHour,
      sleepMinute: sleepMinute ?? this.sleepMinute,
    );
  }

  Map<String, dynamic> toJson() => {
    'morningEnabled': morningEnabled,
    'morningHour': morningHour,
    'morningMinute': morningMinute,
    'eveningEnabled': eveningEnabled,
    'eveningHour': eveningHour,
    'eveningMinute': eveningMinute,
    'afterPrayerEnabled': afterPrayerEnabled,
    'afterPrayerDelayMinutes': afterPrayerDelayMinutes,
    'qiyamEnabled': qiyamEnabled,
    'qiyamMode': qiyamMode.index,
    'qiyamHour': qiyamHour,
    'qiyamMinute': qiyamMinute,
    'fridayKahfEnabled': fridayKahfEnabled,
    'fridayKahfHour': fridayKahfHour,
    'fridayKahfMinute': fridayKahfMinute,
    'witrEnabled': witrEnabled,
    'witrHour': witrHour,
    'witrMinute': witrMinute,
    'duhaEnabled': duhaEnabled,
    'duhaOffsetMinutes': duhaOffsetMinutes,
    'sleepEnabled': sleepEnabled,
    'sleepHour': sleepHour,
    'sleepMinute': sleepMinute,
  };

  factory AzkarReminderSettingsModel.fromJson(Map<String, dynamic> json) {
    final d = AzkarReminderSettingsModel.defaultSettings();
    final modeIndex = json['qiyamMode'] as int? ?? d.qiyamMode.index;
    return AzkarReminderSettingsModel(
      morningEnabled: json['morningEnabled'] as bool? ?? d.morningEnabled,
      morningHour: json['morningHour'] as int? ?? d.morningHour,
      morningMinute: json['morningMinute'] as int? ?? d.morningMinute,
      eveningEnabled: json['eveningEnabled'] as bool? ?? d.eveningEnabled,
      eveningHour: json['eveningHour'] as int? ?? d.eveningHour,
      eveningMinute: json['eveningMinute'] as int? ?? d.eveningMinute,
      afterPrayerEnabled:
          json['afterPrayerEnabled'] as bool? ?? d.afterPrayerEnabled,
      afterPrayerDelayMinutes:
          json['afterPrayerDelayMinutes'] as int? ?? d.afterPrayerDelayMinutes,
      qiyamEnabled: json['qiyamEnabled'] as bool? ?? d.qiyamEnabled,
      qiyamMode: QiyamMode.values[modeIndex.clamp(
        0,
        QiyamMode.values.length - 1,
      )],
      qiyamHour: json['qiyamHour'] as int? ?? d.qiyamHour,
      qiyamMinute: json['qiyamMinute'] as int? ?? d.qiyamMinute,
      fridayKahfEnabled:
          json['fridayKahfEnabled'] as bool? ?? d.fridayKahfEnabled,
      fridayKahfHour: json['fridayKahfHour'] as int? ?? d.fridayKahfHour,
      fridayKahfMinute: json['fridayKahfMinute'] as int? ?? d.fridayKahfMinute,
      witrEnabled: json['witrEnabled'] as bool? ?? d.witrEnabled,
      witrHour: json['witrHour'] as int? ?? d.witrHour,
      witrMinute: json['witrMinute'] as int? ?? d.witrMinute,
      duhaEnabled: json['duhaEnabled'] as bool? ?? d.duhaEnabled,
      duhaOffsetMinutes:
          json['duhaOffsetMinutes'] as int? ?? d.duhaOffsetMinutes,
      sleepEnabled: json['sleepEnabled'] as bool? ?? d.sleepEnabled,
      sleepHour: json['sleepHour'] as int? ?? d.sleepHour,
      sleepMinute: json['sleepMinute'] as int? ?? d.sleepMinute,
    );
  }

  @override
  List<Object?> get props => [
    morningEnabled,
    morningHour,
    morningMinute,
    eveningEnabled,
    eveningHour,
    eveningMinute,
    afterPrayerEnabled,
    afterPrayerDelayMinutes,
    qiyamEnabled,
    qiyamMode,
    qiyamHour,
    qiyamMinute,
    fridayKahfEnabled,
    fridayKahfHour,
    fridayKahfMinute,
    witrEnabled,
    witrHour,
    witrMinute,
    duhaEnabled,
    duhaOffsetMinutes,
    sleepEnabled,
    sleepHour,
    sleepMinute,
  ];
}
