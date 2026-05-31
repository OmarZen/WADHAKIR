import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/data/models/app_lock_settings_model.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';
import 'package:wadhakir/domain/repositories/app_settings_repository.dart';

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  final StreamController<AppSettingsModel> _settingsController =
      StreamController<AppSettingsModel>.broadcast();
  final SharedPreferences _sharedPreferences;
  AppSettingsModel? _cachedSettings;

  AppSettingsRepositoryImpl(this._sharedPreferences);

  @override
  Future<AppSettingsModel> getSettings() async {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    // Get theme setting
    final themeInt = _sharedPreferences.getInt(AppConstants.themeKey);
    final ThemeMode themeMode = themeInt != null
        ? ThemeMode.values[themeInt]
        : ThemeMode.light;

    // Get language setting
    final languageCode =
        _sharedPreferences.getString(AppConstants.languageKey) ?? 'ar';

    // Get other settings
    final showBasmala =
        _sharedPreferences.getBool(AppConstants.showBasmalaKey) ?? true;

    // Get notification settings
    final notificationSettingsJson = _sharedPreferences.getString(
      AppConstants.notificationSettingsKey,
    );
    NotificationSettingsModel notificationSettings;
    if (notificationSettingsJson != null) {
      try {
        notificationSettings = NotificationSettingsModel.fromJson(
          jsonDecode(notificationSettingsJson) as Map<String, dynamic>,
        );
      } catch (e) {
        notificationSettings = NotificationSettingsModel.defaultSettings();
      }
    } else {
      notificationSettings = NotificationSettingsModel.defaultSettings();
    }

    // Get app lock settings
    final appLockSettingsJson = _sharedPreferences.getString(
      AppConstants.appLockSettingsKey,
    );
    AppLockSettingsModel appLockSettings;
    if (appLockSettingsJson != null) {
      try {
        appLockSettings = AppLockSettingsModel.fromJson(
          jsonDecode(appLockSettingsJson) as Map<String, dynamic>,
        );
      } catch (e) {
        appLockSettings = AppLockSettingsModel.defaultSettings();
      }
    } else {
      appLockSettings = AppLockSettingsModel.defaultSettings();
    }

    // Get onboarding completed flag
    final onboardingCompleted =
        _sharedPreferences.getBool(AppConstants.onboardingCompletedKey) ??
        false;

    _cachedSettings = AppSettingsModel(
      themeMode: themeMode,
      languageCode: languageCode,
      showBasmala: showBasmala,
      notificationSettings: notificationSettings,
      appLockSettings: appLockSettings,
      onboardingCompleted: onboardingCompleted,
    );

    _settingsController.add(_cachedSettings!);
    return _cachedSettings!;
  }

  @override
  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _sharedPreferences.setInt(AppConstants.themeKey, themeMode.index);

    final settings = await getSettings();
    _cachedSettings = settings.copyWith(themeMode: themeMode);
    _settingsController.add(_cachedSettings!);
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    await _sharedPreferences.setString(AppConstants.languageKey, languageCode);

    final settings = await getSettings();
    _cachedSettings = settings.copyWith(languageCode: languageCode);
    _settingsController.add(_cachedSettings!);
  }

  @override
  Future<void> setShowBasmala(bool showBasmala) async {
    await _sharedPreferences.setBool(AppConstants.showBasmalaKey, showBasmala);

    final settings = await getSettings();
    _cachedSettings = settings.copyWith(showBasmala: showBasmala);
    _settingsController.add(_cachedSettings!);
  }

  @override
  Future<void> setNotificationSettings(
    NotificationSettingsModel notificationSettings,
  ) async {
    await _sharedPreferences.setString(
      AppConstants.notificationSettingsKey,
      jsonEncode(notificationSettings.toJson()),
    );

    final settings = await getSettings();
    _cachedSettings = settings.copyWith(
      notificationSettings: notificationSettings,
    );
    _settingsController.add(_cachedSettings!);
  }

  @override
  Future<void> setAppLockSettings(AppLockSettingsModel appLockSettings) async {
    await _sharedPreferences.setString(
      AppConstants.appLockSettingsKey,
      jsonEncode(appLockSettings.toJson()),
    );

    final settings = await getSettings();
    _cachedSettings = settings.copyWith(appLockSettings: appLockSettings);
    _settingsController.add(_cachedSettings!);
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await _sharedPreferences.setBool(
      AppConstants.onboardingCompletedKey,
      completed,
    );

    final settings = await getSettings();
    _cachedSettings = settings.copyWith(onboardingCompleted: completed);
    _settingsController.add(_cachedSettings!);
  }

  @override
  Stream<AppSettingsModel> get settingsStream => _settingsController.stream;

  void dispose() {
    _settingsController.close();
  }
}
