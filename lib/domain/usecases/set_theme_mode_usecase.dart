import 'package:flutter/material.dart';
import 'package:wadhakir/domain/repositories/app_settings_repository.dart';

class SetThemeModeUseCase {
  final AppSettingsRepository _repository;

  SetThemeModeUseCase(this._repository);

  Future<void> call(ThemeMode themeMode) async {
    await _repository.setThemeMode(themeMode);
  }
}
