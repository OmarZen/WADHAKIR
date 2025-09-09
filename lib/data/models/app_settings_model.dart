import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class AppSettingsModel extends Equatable {
  final ThemeMode themeMode;
  final String languageCode;
  final bool showBasmala;
  final double fontSize;

  const AppSettingsModel({
    required this.themeMode,
    required this.languageCode,
    required this.showBasmala,
    required this.fontSize,
  });

  factory AppSettingsModel.defaultSettings() {
    return const AppSettingsModel(
      themeMode: ThemeMode.system,
      languageCode: 'ar',
      showBasmala: true,
      fontSize: 1.0, // 1.0 is the default, can be scaled up or down
    );
  }

  AppSettingsModel copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? showBasmala,
    double? fontSize,
    bool? enableNotifications,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      showBasmala: showBasmala ?? this.showBasmala,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        languageCode,
        showBasmala,
        fontSize,
      ];
}
