import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'notification_settings_model.dart';

class AppSettingsModel extends Equatable {
  final ThemeMode themeMode;
  final String languageCode;
  final bool showBasmala;
  final NotificationSettingsModel notificationSettings;

  const AppSettingsModel({
    required this.themeMode,
    required this.languageCode,
    required this.showBasmala,
    required this.notificationSettings,
  });

  factory AppSettingsModel.defaultSettings() {
    return AppSettingsModel(
      themeMode: ThemeMode.light,
      languageCode: 'ar',
      showBasmala: true,
      notificationSettings: NotificationSettingsModel.defaultSettings(),
    );
  }

  AppSettingsModel copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? showBasmala,
    NotificationSettingsModel? notificationSettings,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      showBasmala: showBasmala ?? this.showBasmala,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    languageCode,
    showBasmala,
    notificationSettings,
  ];
}
