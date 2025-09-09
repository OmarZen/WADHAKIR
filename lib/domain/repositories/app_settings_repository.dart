import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';

abstract class AppSettingsRepository {
  Future<AppSettingsModel> getSettings();

  Future<void> setThemeMode(ThemeMode themeMode);

  Future<void> setLanguage(String languageCode);

  Future<void> setShowBasmala(bool showBasmala);

  Future<void> setFontSize(double fontSize);

  Stream<AppSettingsModel> get settingsStream;
}
