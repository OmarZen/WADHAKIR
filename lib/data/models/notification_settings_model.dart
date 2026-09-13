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
  // NOTE: [customSoundPath] is the single source of truth for which adhan
  // plays. This [sound] enum is retained only for JSON back-compat and is NOT
  // consulted by the scheduler (which maps customSoundPath → a per-sound
  // notification channel). See AdhanSounds / NotificationRepository.
  final NotificationSound sound;
  final bool vibration;
  final String? customSoundPath; // Flutter asset path of the selected adhan

  /// Whether the adhan sounds through a silenced phone.
  ///
  /// On Android the adhan plays from a foreground service on
  /// `AudioAttributes.USAGE_ALARM`, so it follows the ALARM slider and ignores
  /// silent and vibrate mode the way an alarm clock does. That is what the
  /// `USE_EXACT_ALARM` exemption is for and almost certainly what a prayer app
  /// should do — but it is a change people notice on day one, so it has a
  /// switch. False makes the fire path post the adhan card, and vibrate, but
  /// play nothing while the ringer is off.
  ///
  /// Modelled per prayer for symmetry with everything else here; the settings
  /// screen writes all five together, the same way the adhan picker does.
  /// Inert on iOS, where the OS decides.
  final bool overrideSilentMode;

  const PrayerNotificationSettings({
    required this.enabled,
    required this.timing,
    required this.sound,
    required this.vibration,
    this.customSoundPath,
    this.overrideSilentMode = true,
  });

  factory PrayerNotificationSettings.defaultSettings() {
    return const PrayerNotificationSettings(
      enabled: true,
      timing: NotificationTiming.onTime,
      sound: NotificationSound.defaultSound,
      vibration: true,
      customSoundPath: null,
      overrideSilentMode: true,
    );
  }

  PrayerNotificationSettings copyWith({
    bool? enabled,
    NotificationTiming? timing,
    NotificationSound? sound,
    bool? vibration,
    Object? customSoundPath = _undefined,
    bool? overrideSilentMode,
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
      overrideSilentMode: overrideSilentMode ?? this.overrideSilentMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'timing': timing.index,
      'sound': sound.index,
      'vibration': vibration,
      'customSoundPath': customSoundPath,
      'overrideSilentMode': overrideSilentMode,
    };
  }

  factory PrayerNotificationSettings.fromJson(Map<String, dynamic> json) {
    return PrayerNotificationSettings(
      enabled: json['enabled'] as bool? ?? true,
      timing: NotificationTiming.values[json['timing'] as int? ?? 0],
      sound: NotificationSound.values[json['sound'] as int? ?? 0],
      vibration: json['vibration'] as bool? ?? true,
      customSoundPath: json['customSoundPath'] as String?,
      // Absent on every install that predates Stage 3, which is all of them.
      // Defaulting to true is what makes the new alarm-clock behaviour the
      // default the user chose, rather than something only new installs get.
      overrideSilentMode: json['overrideSilentMode'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    enabled,
    timing,
    sound,
    vibration,
    customSoundPath,
    overrideSilentMode,
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

  const NotificationSettingsModel({
    required this.masterEnabled,
    this.persistentNotificationEnabled = false,
    required this.fajrSettings,
    required this.dhuhrSettings,
    required this.asrSettings,
    required this.maghribSettings,
    required this.ishaSettings,
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
  ];
}
