import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'notification_settings_model.dart';

class AppSettingsModel extends Equatable {
  final ThemeMode themeMode;
  final String languageCode;
  final bool showBasmala;
  final double fontSize;
  final NotificationSettingsModel notificationSettings;

  const AppSettingsModel({
    required this.themeMode,
    required this.languageCode,
    required this.showBasmala,
    required this.fontSize,
    required this.notificationSettings,
  });

  factory AppSettingsModel.defaultSettings() {
    return AppSettingsModel(
      themeMode: ThemeMode.light,
      languageCode: 'ar',
      showBasmala: true,
      fontSize: 1.0, // 1.0 is the default, can be scaled up or down
      notificationSettings: NotificationSettingsModel.defaultSettings(),
    );
  }

  AppSettingsModel copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? showBasmala,
    double? fontSize,
    NotificationSettingsModel? notificationSettings,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      showBasmala: showBasmala ?? this.showBasmala,
      fontSize: fontSize ?? this.fontSize,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        languageCode,
        showBasmala,
        fontSize,
        notificationSettings,
      ];
}
