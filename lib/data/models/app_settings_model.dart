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

  /// The user's first name, used to personalize the home greeting. Empty
  /// string means "not set" (default for fresh installs and existing users
  /// who haven't entered it yet).
  final String userName;

  const AppSettingsModel({
    required this.themeMode,
    required this.languageCode,
    required this.showBasmala,
    required this.notificationSettings,
    required this.appLockSettings,
    this.onboardingCompleted = false,
    this.userName = '',
  });

  factory AppSettingsModel.defaultSettings() {
    return AppSettingsModel(
      themeMode: ThemeMode.light,
      languageCode: 'ar',
      showBasmala: true,
      notificationSettings: NotificationSettingsModel.defaultSettings(),
      appLockSettings: AppLockSettingsModel.defaultSettings(),
      onboardingCompleted: false,
      userName: '',
    );
  }

  AppSettingsModel copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? showBasmala,
    NotificationSettingsModel? notificationSettings,
    AppLockSettingsModel? appLockSettings,
    bool? onboardingCompleted,
    String? userName,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      showBasmala: showBasmala ?? this.showBasmala,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      appLockSettings: appLockSettings ?? this.appLockSettings,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      userName: userName ?? this.userName,
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
    userName,
  ];
}
