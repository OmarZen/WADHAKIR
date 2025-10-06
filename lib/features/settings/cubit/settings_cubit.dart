import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/domain/usecases/set_basmala_usecase.dart';
import 'package:wadhakir/domain/usecases/get_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_language_usecase.dart';
import 'package:wadhakir/domain/usecases/set_font_size_usecase.dart';
import 'package:wadhakir/domain/usecases/set_theme_mode_usecase.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/domain/usecases/get_settings_stream_usecase.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetSettingsUseCase _getSettingsUseCase;
  final GetSettingsStreamUseCase _getSettingsStreamUseCase;
  final SetThemeModeUseCase _setThemeModeUseCase;
  final SetLanguageUseCase _setLanguageUseCase;
  final SetFontSizeUseCase _setFontSizeUseCase;
  final SetBasmalaUseCase _setBasmalaUseCase;

  StreamSubscription? _settingsSubscription;

  SettingsCubit({
    required GetSettingsUseCase getSettingsUseCase,
    required GetSettingsStreamUseCase getSettingsStreamUseCase,
    required SetThemeModeUseCase setThemeModeUseCase,
    required SetLanguageUseCase setLanguageUseCase,
    required SetFontSizeUseCase setFontSizeUseCase,
    required SetBasmalaUseCase setBasmalaUseCase,
  })  : _getSettingsUseCase = getSettingsUseCase,
        _getSettingsStreamUseCase = getSettingsStreamUseCase,
        _setThemeModeUseCase = setThemeModeUseCase,
        _setLanguageUseCase = setLanguageUseCase,
        _setFontSizeUseCase = setFontSizeUseCase,
        _setBasmalaUseCase = setBasmalaUseCase,
        super(const SettingsInitial()) {
    loadSettings();
    _listenToSettingsChanges();
  }

  void _listenToSettingsChanges() {
    _settingsSubscription = _getSettingsStreamUseCase().listen(
      (settings) => emit(SettingsLoaded(settings)),
      onError: (error) => emit(SettingsError(error.toString())),
    );
  }

  Future<void> loadSettings() async {
    emit(const SettingsLoading());
    try {
      final settings = await _getSettingsUseCase();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      await _setThemeModeUseCase(themeMode);
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      await _setLanguageUseCase(language);
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> setFontSize(double fontSize) async {
    try {
      await _setFontSizeUseCase(fontSize);
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> setShowBasmala(bool show) async {
    try {
      await _setBasmalaUseCase(show);
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _settingsSubscription?.cancel();
    return super.close();
  }
}
