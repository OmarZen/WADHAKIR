import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'app_lock_settings_model.dart';
import 'notification_settings_model.dart';

class AppSettingsModel extends Equatable {
  final ThemeMode themeMode;
  final String languageCode;
  final bool showBasmala;
  final NotificationSettingsModel notificationSettings;
  final AppLockSettingsModel appLockSettings;
  final bool onboardingCompleted;

  const AppSettingsModel({
    required this.themeMode,
    required this.languageCode,
    required this.showBasmala,
    required this.notificationSettings,
    required this.appLockSettings,
    this.onboardingCompleted = false,
  });

  factory AppSettingsModel.defaultSettings() {
    return AppSettingsModel(
      themeMode: ThemeMode.light,
      languageCode: 'ar',
      showBasmala: true,
      notificationSettings: NotificationSettingsModel.defaultSettings(),
      appLockSettings: AppLockSettingsModel.defaultSettings(),
      onboardingCompleted: false,
    );
  }

  AppSettingsModel copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? showBasmala,
    NotificationSettingsModel? notificationSettings,
    AppLockSettingsModel? appLockSettings,
    bool? onboardingCompleted,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      showBasmala: showBasmala ?? this.showBasmala,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      appLockSettings: appLockSettings ?? this.appLockSettings,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        languageCode,
        showBasmala,
        notificationSettings,
        appLockSettings,
        onboardingCompleted,
      ];
}
