import 'package:equatable/equatable.dart';

// Sentinel value to distinguish between "not provided" and "explicitly set to null"
const Object _undefined = Object();

/// Enum for notification timing options
enum NotificationTiming { onTime, before5Min, before10Min, before15Min }

/// Enum for notification sound options
enum NotificationSound { defaultSound, adhan, silent }

/// Model for individual prayer notification settings
class PrayerNotificationSettings extends Equatable {
  final bool enabled;
  final NotificationTiming timing;
  final NotificationSound sound;
  final bool vibration;
  final String? customSoundPath; // Path to custom adhan sound file

  const PrayerNotificationSettings({
    required this.enabled,
    required this.timing,
    required this.sound,
    required this.vibration,
    this.customSoundPath,
  });

  factory PrayerNotificationSettings.defaultSettings() {
    return const PrayerNotificationSettings(
      enabled: true,
      timing: NotificationTiming.onTime,
      sound: NotificationSound.defaultSound,
      vibration: true,
      customSoundPath: null,
    );
  }

  PrayerNotificationSettings copyWith({
    bool? enabled,
    NotificationTiming? timing,
    NotificationSound? sound,
    bool? vibration,
    Object? customSoundPath = _undefined,
  }) {
    return PrayerNotificationSettings(
      enabled: enabled ?? this.enabled,
      timing: timing ?? this.timing,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      // Use sentinel pattern to distinguish between "not provided" and "set to null"
      customSoundPath: customSoundPath == _undefined
          ? this.customSoundPath
          : customSoundPath as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'timing': timing.index,
      'sound': sound.index,
      'vibration': vibration,
      'customSoundPath': customSoundPath,
    };
  }

  factory PrayerNotificationSettings.fromJson(Map<String, dynamic> json) {
    return PrayerNotificationSettings(
      enabled: json['enabled'] as bool? ?? true,
      timing: NotificationTiming.values[json['timing'] as int? ?? 0],
      sound: NotificationSound.values[json['sound'] as int? ?? 0],
      vibration: json['vibration'] as bool? ?? true,
      customSoundPath: json['customSoundPath'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        enabled,
        timing,
        sound,
        vibration,
        customSoundPath,
      ];
}

/// Complete notification settings model
class NotificationSettingsModel extends Equatable {
  final bool masterEnabled;
  final bool persistentNotificationEnabled;
  final PrayerNotificationSettings fajrSettings;
  final PrayerNotificationSettings dhuhrSettings;
  final PrayerNotificationSettings asrSettings;
  final PrayerNotificationSettings maghribSettings;
  final PrayerNotificationSettings ishaSettings;

  // Fasting notifications
  final bool mondayFastingEnabled;
  final bool thursdayFastingEnabled;
  final String fastingNotificationTime; // Format: "HH:mm" (24-hour format)
  final bool fastingVibration;

  const NotificationSettingsModel({
    required this.masterEnabled,
    this.persistentNotificationEnabled = false,
    required this.fajrSettings,
    required this.dhuhrSettings,
    required this.asrSettings,
    required this.maghribSettings,
    required this.ishaSettings,
    required this.mondayFastingEnabled,
    required this.thursdayFastingEnabled,
    required this.fastingNotificationTime,
    required this.fastingVibration,
  });

  factory NotificationSettingsModel.defaultSettings() {
    return NotificationSettingsModel(
      masterEnabled: false,
      persistentNotificationEnabled: false,
      fajrSettings: PrayerNotificationSettings.defaultSettings().copyWith(
        // Fajr is critical - use maximum importance
        timing: NotificationTiming.onTime,
      ),
      dhuhrSettings: PrayerNotificationSettings.defaultSettings(),
      asrSettings: PrayerNotificationSettings.defaultSettings(),
      maghribSettings: PrayerNotificationSettings.defaultSettings(),
      ishaSettings: PrayerNotificationSettings.defaultSettings(),
      mondayFastingEnabled: false,
      thursdayFastingEnabled: false,
      fastingNotificationTime: '21:00', // 9 PM night before
      fastingVibration: true,
    );
  }

  NotificationSettingsModel copyWith({
    bool? masterEnabled,
    bool? persistentNotificationEnabled,
    PrayerNotificationSettings? fajrSettings,
    PrayerNotificationSettings? dhuhrSettings,
    PrayerNotificationSettings? asrSettings,
    PrayerNotificationSettings? maghribSettings,
    PrayerNotificationSettings? ishaSettings,
    bool? mondayFastingEnabled,
    bool? thursdayFastingEnabled,
    String? fastingNotificationTime,
    bool? fastingVibration,
  }) {
    return NotificationSettingsModel(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      persistentNotificationEnabled:
          persistentNotificationEnabled ?? this.persistentNotificationEnabled,
      fajrSettings: fajrSettings ?? this.fajrSettings,
      dhuhrSettings: dhuhrSettings ?? this.dhuhrSettings,
      asrSettings: asrSettings ?? this.asrSettings,
      maghribSettings: maghribSettings ?? this.maghribSettings,
      ishaSettings: ishaSettings ?? this.ishaSettings,
      mondayFastingEnabled: mondayFastingEnabled ?? this.mondayFastingEnabled,
      thursdayFastingEnabled:
          thursdayFastingEnabled ?? this.thursdayFastingEnabled,
      fastingNotificationTime:
          fastingNotificationTime ?? this.fastingNotificationTime,
      fastingVibration: fastingVibration ?? this.fastingVibration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'masterEnabled': masterEnabled,
      'persistentNotificationEnabled': persistentNotificationEnabled,
      'fajrSettings': fajrSettings.toJson(),
      'dhuhrSettings': dhuhrSettings.toJson(),
      'asrSettings': asrSettings.toJson(),
      'maghribSettings': maghribSettings.toJson(),
      'ishaSettings': ishaSettings.toJson(),
      'mondayFastingEnabled': mondayFastingEnabled,
      'thursdayFastingEnabled': thursdayFastingEnabled,
      'fastingNotificationTime': fastingNotificationTime,
      'fastingVibration': fastingVibration,
    };
  }

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      masterEnabled: json['masterEnabled'] as bool? ?? true,
      persistentNotificationEnabled:
          json['persistentNotificationEnabled'] as bool? ?? false,
      fajrSettings: json['fajrSettings'] != null
          ? PrayerNotificationSettings.fromJson(
              json['fajrSettings'] as Map<String, dynamic>,
            )
          : PrayerNotificationSettings.defaultSettings(),
      dhuhrSettings: json['dhuhrSettings'] != null
          ? PrayerNotificationSettings.fromJson(
              json['dhuhrSettings'] as Map<String, dynamic>,
            )
          : PrayerNotificationSettings.defaultSettings(),
      asrSettings: json['asrSettings'] != null
          ? PrayerNotificationSettings.fromJson(
              json['asrSettings'] as Map<String, dynamic>,
            )
          : PrayerNotificationSettings.defaultSettings(),
      maghribSettings: json['maghribSettings'] != null
          ? PrayerNotificationSettings.fromJson(
              json['maghribSettings'] as Map<String, dynamic>,
            )
          : PrayerNotificationSettings.defaultSettings(),
      ishaSettings: json['ishaSettings'] != null
          ? PrayerNotificationSettings.fromJson(
              json['ishaSettings'] as Map<String, dynamic>,
            )
          : PrayerNotificationSettings.defaultSettings(),
      mondayFastingEnabled: json['mondayFastingEnabled'] as bool? ?? false,
      thursdayFastingEnabled: json['thursdayFastingEnabled'] as bool? ?? false,
      fastingNotificationTime:
          json['fastingNotificationTime'] as String? ?? '21:00',
      fastingVibration: json['fastingVibration'] as bool? ?? true,
    );
  }

  /// Get settings for a specific prayer by name
  PrayerNotificationSettings getSettingsForPrayer(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
      case 'الفجر':
        return fajrSettings;
      case 'dhuhr':
      case 'الظهر':
        return dhuhrSettings;
      case 'asr':
      case 'العصر':
        return asrSettings;
      case 'maghrib':
      case 'المغرب':
        return maghribSettings;
      case 'isha':
      case 'العشاء':
        return ishaSettings;
      default:
        return PrayerNotificationSettings.defaultSettings();
    }
  }

  @override
  List<Object?> get props => [
        masterEnabled,
        persistentNotificationEnabled,
        fajrSettings,
        dhuhrSettings,
        asrSettings,
        maghribSettings,
        ishaSettings,
        mondayFastingEnabled,
        thursdayFastingEnabled,
        fastingNotificationTime,
        fastingVibration,
      ];
}
