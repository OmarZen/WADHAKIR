import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/app_lock_settings_model.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';

abstract class AppSettingsRepository {
  Future<AppSettingsModel> getSettings();

  Future<void> setThemeMode(ThemeMode themeMode);

  Future<void> setLanguage(String languageCode);

  Future<void> setShowBasmala(bool showBasmala);

  Future<void> setNotificationSettings(NotificationSettingsModel settings);

  Future<void> setAppLockSettings(AppLockSettingsModel settings);

  Stream<AppSettingsModel> get settingsStream;
}
