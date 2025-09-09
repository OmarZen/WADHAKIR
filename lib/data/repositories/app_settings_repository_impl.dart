import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
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
    final ThemeMode themeMode =
        themeInt != null ? ThemeMode.values[themeInt] : ThemeMode.system;

    // Get language setting
    final languageCode =
        _sharedPreferences.getString(AppConstants.languageKey) ?? 'ar';

    // Get other settings
    final showBasmala =
        _sharedPreferences.getBool(AppConstants.showBasmalaKey) ?? true;
    final fontSize =
        _sharedPreferences.getDouble(AppConstants.fontSizeKey) ?? 1.0;
    
    _cachedSettings = AppSettingsModel(
      themeMode: themeMode,
      languageCode: languageCode,
      showBasmala: showBasmala,
      fontSize: fontSize,
      
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
  Future<void> setFontSize(double fontSize) async {
    await _sharedPreferences.setDouble(AppConstants.fontSizeKey, fontSize);

    final settings = await getSettings();
    _cachedSettings = settings.copyWith(fontSize: fontSize);
    _settingsController.add(_cachedSettings!);
  }

 

  @override
  Stream<AppSettingsModel> get settingsStream => _settingsController.stream;

  void dispose() {
    _settingsController.close();
  }
}
