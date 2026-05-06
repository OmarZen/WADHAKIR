import 'package:equatable/equatable.dart';

class AppLockSettingsModel extends Equatable {
  final bool enabled;
  final bool useAccessibilityFallback;
  final int? lockDurationMinutes;
  final bool emergencyBypassEnabled;
  final List<String> lockedAppPackageNames;
  final List<String> excludedAppPackageNames;

  const AppLockSettingsModel({
    required this.enabled,
    required this.useAccessibilityFallback,
    required this.lockDurationMinutes,
    required this.emergencyBypassEnabled,
    required this.lockedAppPackageNames,
    required this.excludedAppPackageNames,
  });

  factory AppLockSettingsModel.defaultSettings() {
    return const AppLockSettingsModel(
      enabled: false,
      useAccessibilityFallback: false,
      lockDurationMinutes: 15,
      emergencyBypassEnabled: true,
      lockedAppPackageNames: [],
      excludedAppPackageNames: [
        'com.android.dialer',
        'com.google.android.dialer',
        'com.android.contacts',
        'com.android.settings',
        'com.google.android.apps.maps',
        'com.android.messaging',
        'com.google.android.apps.messaging',
      ],
    );
  }

  AppLockSettingsModel copyWith({
    bool? enabled,
    bool? useAccessibilityFallback,
    int? lockDurationMinutes,
    bool clearLockDurationMinutes = false,
    bool? emergencyBypassEnabled,
    List<String>? lockedAppPackageNames,
    List<String>? excludedAppPackageNames,
  }) {
    return AppLockSettingsModel(
      enabled: enabled ?? this.enabled,
      useAccessibilityFallback:
          useAccessibilityFallback ?? this.useAccessibilityFallback,
      lockDurationMinutes: clearLockDurationMinutes
          ? null
          : (lockDurationMinutes ?? this.lockDurationMinutes),
      emergencyBypassEnabled:
          emergencyBypassEnabled ?? this.emergencyBypassEnabled,
      lockedAppPackageNames:
          lockedAppPackageNames ?? this.lockedAppPackageNames,
      excludedAppPackageNames:
          excludedAppPackageNames ?? this.excludedAppPackageNames,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'useAccessibilityFallback': useAccessibilityFallback,
      'lockDurationMinutes': lockDurationMinutes,
      'emergencyBypassEnabled': emergencyBypassEnabled,
      'lockedAppPackageNames': lockedAppPackageNames,
      'excludedAppPackageNames': excludedAppPackageNames,
    };
  }

  factory AppLockSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppLockSettingsModel(
      enabled: json['enabled'] as bool? ?? false,
      useAccessibilityFallback:
          json['useAccessibilityFallback'] as bool? ?? false,
      lockDurationMinutes: json['lockDurationMinutes'] as int?,
      emergencyBypassEnabled: json['emergencyBypassEnabled'] as bool? ?? true,
      lockedAppPackageNames:
          (json['lockedAppPackageNames'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      excludedAppPackageNames:
          (json['excludedAppPackageNames'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
    );
  }

  @override
  List<Object?> get props => [
        enabled,
        useAccessibilityFallback,
        lockDurationMinutes,
        emergencyBypassEnabled,
        lockedAppPackageNames,
        excludedAppPackageNames,
      ];
}
