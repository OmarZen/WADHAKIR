import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/domain/usecases/get_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_language_usecase.dart';
import 'package:wadhakir/domain/usecases/set_font_size_usecase.dart';
import 'package:wadhakir/domain/usecases/set_theme_mode_usecase.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';
import 'package:wadhakir/domain/usecases/get_settings_stream_usecase.dart';
import 'package:wadhakir/domain/usecases/set_notification_settings_usecase.dart';
import 'package:wadhakir/features/pray_times/services/prayer_notification_service.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetSettingsUseCase _getSettingsUseCase;
  final GetSettingsStreamUseCase _getSettingsStreamUseCase;
  final SetThemeModeUseCase _setThemeModeUseCase;
  final SetLanguageUseCase _setLanguageUseCase;
  final SetFontSizeUseCase _setFontSizeUseCase;
  final SetNotificationSettingsUseCase _setNotificationSettingsUseCase;
  final PrayerNotificationService _notificationService;

  StreamSubscription? _settingsSubscription;

  SettingsCubit({
    required GetSettingsUseCase getSettingsUseCase,
    required GetSettingsStreamUseCase getSettingsStreamUseCase,
    required SetThemeModeUseCase setThemeModeUseCase,
    required SetLanguageUseCase setLanguageUseCase,
    required SetFontSizeUseCase setFontSizeUseCase,
    required SetNotificationSettingsUseCase setNotificationSettingsUseCase,
    PrayerNotificationService? notificationService,
  })  : _getSettingsUseCase = getSettingsUseCase,
        _getSettingsStreamUseCase = getSettingsStreamUseCase,
        _setThemeModeUseCase = setThemeModeUseCase,
        _setLanguageUseCase = setLanguageUseCase,
        _setFontSizeUseCase = setFontSizeUseCase,
        _setNotificationSettingsUseCase = setNotificationSettingsUseCase,
        _notificationService =
            notificationService ?? PrayerNotificationService(),
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

  /// Update notification settings
  Future<void> setNotificationSettings(
      NotificationSettingsModel settings) async {
    try {
      await _setNotificationSettingsUseCase(settings);

      // After settings are saved, reschedule all notifications
      // This ensures old notifications are cancelled and new ones are created
      // Note: This requires prayer times to be loaded first
      debugPrint(
          'Notification settings updated, rescheduling notifications...');
      // Settings will be updated through the stream listener
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  /// Toggle master notification setting
  Future<void> toggleNotifications(bool enabled) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final newNotificationSettings =
          currentSettings.notificationSettings.copyWith(masterEnabled: enabled);

      await setNotificationSettings(newNotificationSettings);

      // Cancel all notifications if disabled
      if (!enabled) {
        await _notificationService.cancelAllNotifications();
      }
    }
  }

  /// Update notification settings for a specific prayer
  Future<void> updatePrayerNotificationSettings({
    required String prayerName,
    required PrayerNotificationSettings prayerSettings,
  }) async {
    debugPrint('🔔 CUBIT: updatePrayerNotificationSettings called');
    debugPrint('🔔 CUBIT: Prayer name: $prayerName');
    debugPrint('🔔 CUBIT: customSoundPath: ${prayerSettings.customSoundPath}');

    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final currentNotificationSettings = currentSettings.notificationSettings;

      NotificationSettingsModel newNotificationSettings;

      switch (prayerName.toLowerCase()) {
        case 'fajr':
        case 'الفجر':
          debugPrint('🔔 CUBIT: Updating Fajr settings');
          newNotificationSettings = currentNotificationSettings.copyWith(
              fajrSettings: prayerSettings);
          break;
        case 'dhuhr':
        case 'الظهر':
          debugPrint('🔔 CUBIT: Updating Dhuhr settings');
          newNotificationSettings = currentNotificationSettings.copyWith(
              dhuhrSettings: prayerSettings);
          break;
        case 'asr':
        case 'العصر':
          debugPrint('🔔 CUBIT: Updating Asr settings');
          newNotificationSettings =
              currentNotificationSettings.copyWith(asrSettings: prayerSettings);
          break;
        case 'maghrib':
        case 'المغرب':
          debugPrint('🔔 CUBIT: Updating Maghrib settings');
          newNotificationSettings = currentNotificationSettings.copyWith(
              maghribSettings: prayerSettings);
          break;
        case 'isha':
        case 'العشاء':
          debugPrint('🔔 CUBIT: Updating Isha settings');
          newNotificationSettings = currentNotificationSettings.copyWith(
              ishaSettings: prayerSettings);
          break;
        default:
          debugPrint('🔔 CUBIT: Unknown prayer name: $prayerName');
          return;
      }

      debugPrint('🔔 CUBIT: Calling setNotificationSettings...');
      await setNotificationSettings(newNotificationSettings);
      debugPrint('🔔 CUBIT: setNotificationSettings completed');
    } else {
      debugPrint(
          '🔔 CUBIT: State is not SettingsLoaded, current state: $state');
    }
  }

  /// Update all regular prayers (Dhuhr, Asr, Maghrib, Isha) with the same sound in a single batch
  Future<void> updateAllRegularPrayersSounds(String? customSoundPath) async {
    debugPrint('🔔 CUBIT: updateAllRegularPrayersSounds called');
    debugPrint('🔔 CUBIT: customSoundPath: $customSoundPath');

    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final notificationSettings = currentSettings.notificationSettings;

      debugPrint('🔔 CUBIT: Updating all 4 regular prayers in single batch');

      // Update all 4 prayers at once
      final newNotificationSettings = notificationSettings.copyWith(
        dhuhrSettings: notificationSettings.dhuhrSettings
            .copyWith(customSoundPath: customSoundPath),
        asrSettings: notificationSettings.asrSettings
            .copyWith(customSoundPath: customSoundPath),
        maghribSettings: notificationSettings.maghribSettings
            .copyWith(customSoundPath: customSoundPath),
        ishaSettings: notificationSettings.ishaSettings
            .copyWith(customSoundPath: customSoundPath),
      );

      debugPrint(
          '🔔 CUBIT: Calling setNotificationSettings (single update)...');
      await setNotificationSettings(newNotificationSettings);
      debugPrint(
          '🔔 CUBIT: All regular prayers updated successfully with sound: $customSoundPath');
    } else {
      debugPrint(
          '🔔 CUBIT: State is not SettingsLoaded, current state: $state');
    }
  }

  /// Toggle persistent notification
  Future<void> togglePersistentNotification(bool enabled) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final newNotificationSettings = currentSettings.notificationSettings
          .copyWith(persistentNotificationEnabled: enabled);

      await setNotificationSettings(newNotificationSettings);

      // Note: The actual start/stop of persistent notification is handled
      // by PrayerTimesCubit.scheduleNotificationsWithSettings() which gets
      // called automatically when settings change
    }
  }

  @override
  Future<void> close() {
    _settingsSubscription?.cancel();
    return super.close();
  }
}
