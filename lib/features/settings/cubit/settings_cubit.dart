import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/domain/usecases/get_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_language_usecase.dart';
import 'package:wadhakir/domain/usecases/set_theme_mode_usecase.dart';
import 'package:wadhakir/domain/usecases/set_onboarding_completed_usecase.dart';
import 'package:wadhakir/domain/usecases/set_user_name_usecase.dart';
import 'package:wadhakir/domain/usecases/set_text_scale_usecase.dart';
import 'package:wadhakir/data/models/app_lock_settings_model.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';
import 'package:wadhakir/domain/usecases/set_app_lock_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/get_settings_stream_usecase.dart';
import 'package:wadhakir/domain/usecases/set_notification_settings_usecase.dart';
import 'package:wadhakir/features/pray_times/services/prayer_notification_service.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetSettingsUseCase _getSettingsUseCase;
  final GetSettingsStreamUseCase _getSettingsStreamUseCase;
  final SetThemeModeUseCase _setThemeModeUseCase;
  final SetLanguageUseCase _setLanguageUseCase;
  final SetNotificationSettingsUseCase _setNotificationSettingsUseCase;
  final SetAppLockSettingsUseCase _setAppLockSettingsUseCase;
  final SetOnboardingCompletedUseCase? _setOnboardingCompletedUseCase;
  final SetUserNameUseCase? _setUserNameUseCase;
  final SetTextScaleUseCase? _setTextScaleUseCase;
  final PrayerNotificationService _notificationService;

  StreamSubscription? _settingsSubscription;

  SettingsCubit({
    required this._getSettingsUseCase,
    required this._getSettingsStreamUseCase,
    required this._setThemeModeUseCase,
    required this._setLanguageUseCase,
    required this._setNotificationSettingsUseCase,
    required this._setAppLockSettingsUseCase,
    this._setOnboardingCompletedUseCase,
    this._setUserNameUseCase,
    this._setTextScaleUseCase,
    PrayerNotificationService? notificationService,
  }) : _notificationService =
           notificationService ?? PrayerNotificationService(),
       super(const SettingsInitial()) {
    loadSettings();
    _listenToSettingsChanges();
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    if (_setOnboardingCompletedUseCase == null) return;
    try {
      await _setOnboardingCompletedUseCase.call(completed);
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  /// Persist the user's name. State re-emits via the settings stream listener,
  /// so the home greeting and any name UI update reactively.
  Future<void> setUserName(String name) async {
    if (_setUserNameUseCase == null) return;
    try {
      await _setUserNameUseCase.call(name.trim());
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  /// Persist the user's text scale. Nullable use case mirrors the other
  /// optional mutations here, so tests can build the cubit without it.
  Future<void> setTextScale(double scale) async {
    if (_setTextScaleUseCase == null) return;
    try {
      await _setTextScaleUseCase.call(scale);
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
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

  /// Update notification settings
  Future<void> setNotificationSettings(
    NotificationSettingsModel settings,
  ) async {
    try {
      await _setNotificationSettingsUseCase(settings);

      // After settings are saved, reschedule all notifications
      // This ensures old notifications are cancelled and new ones are created
      // Note: This requires prayer times to be loaded first
      debugPrint(
        'Notification settings updated, rescheduling notifications...',
      );
      // Settings will be updated through the stream listener
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  /// Toggle master notification setting
  Future<void> toggleNotifications(bool enabled) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final newNotificationSettings = currentSettings.notificationSettings
          .copyWith(masterEnabled: enabled);

      await setNotificationSettings(newNotificationSettings);

      // Turning the PRAYER master toggle off must cancel prayer notifications
      // only. cancelAllNotifications() would also wipe azkar/wird/fasting/
      // daily-inspiration reminders, which live on the same plugin under their
      // own ids and only re-arm on their own settings change or cold start —
      // so the user would silently lose them for days.
      if (!enabled) {
        await _notificationService.cancelPrayerSchedules();
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
            fajrSettings: prayerSettings,
          );
          break;
        case 'dhuhr':
        case 'الظهر':
          debugPrint('🔔 CUBIT: Updating Dhuhr settings');
          newNotificationSettings = currentNotificationSettings.copyWith(
            dhuhrSettings: prayerSettings,
          );
          break;
        case 'asr':
        case 'العصر':
          debugPrint('🔔 CUBIT: Updating Asr settings');
          newNotificationSettings = currentNotificationSettings.copyWith(
            asrSettings: prayerSettings,
          );
          break;
        case 'maghrib':
        case 'المغرب':
          debugPrint('🔔 CUBIT: Updating Maghrib settings');
          newNotificationSettings = currentNotificationSettings.copyWith(
            maghribSettings: prayerSettings,
          );
          break;
        case 'isha':
        case 'العشاء':
          debugPrint('🔔 CUBIT: Updating Isha settings');
          newNotificationSettings = currentNotificationSettings.copyWith(
            ishaSettings: prayerSettings,
          );
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
        '🔔 CUBIT: State is not SettingsLoaded, current state: $state',
      );
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
        dhuhrSettings: notificationSettings.dhuhrSettings.copyWith(
          customSoundPath: customSoundPath,
        ),
        asrSettings: notificationSettings.asrSettings.copyWith(
          customSoundPath: customSoundPath,
        ),
        maghribSettings: notificationSettings.maghribSettings.copyWith(
          customSoundPath: customSoundPath,
        ),
        ishaSettings: notificationSettings.ishaSettings.copyWith(
          customSoundPath: customSoundPath,
        ),
      );

      debugPrint(
        '🔔 CUBIT: Calling setNotificationSettings (single update)...',
      );
      await setNotificationSettings(newNotificationSettings);
      debugPrint(
        '🔔 CUBIT: All regular prayers updated successfully with sound: $customSoundPath',
      );
    } else {
      debugPrint(
        '🔔 CUBIT: State is not SettingsLoaded, current state: $state',
      );
    }
  }

  /// Whether the adhan sounds through a silenced phone.
  ///
  /// One switch, written to all five prayers — the same fan-out
  /// [updateAllRegularPrayersSounds] does. The flag is modelled per prayer so a
  /// future "Fajr only" reading of it costs no migration, but there is no
  /// per-prayer control in the UI and there should not be one until somebody
  /// asks: five switches for an alarm-clock behaviour is the kind of settings
  /// sprawl PRODUCT.md exists to refuse.
  Future<void> toggleAdhanOverridesSilentMode(bool enabled) async {
    if (state is! SettingsLoaded) return;

    final notificationSettings =
        (state as SettingsLoaded).settings.notificationSettings;

    await setNotificationSettings(
      notificationSettings.copyWith(
        fajrSettings: notificationSettings.fajrSettings.copyWith(
          overrideSilentMode: enabled,
        ),
        dhuhrSettings: notificationSettings.dhuhrSettings.copyWith(
          overrideSilentMode: enabled,
        ),
        asrSettings: notificationSettings.asrSettings.copyWith(
          overrideSilentMode: enabled,
        ),
        maghribSettings: notificationSettings.maghribSettings.copyWith(
          overrideSilentMode: enabled,
        ),
        ishaSettings: notificationSettings.ishaSettings.copyWith(
          overrideSilentMode: enabled,
        ),
      ),
    );
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

  Future<void> setAppLockSettings(AppLockSettingsModel settings) async {
    try {
      await _setAppLockSettingsUseCase(settings);
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> toggleAppLock(bool enabled) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final updated = currentSettings.appLockSettings.copyWith(
        enabled: enabled,
      );
      await setAppLockSettings(updated);
    }
  }

  Future<void> toggleAccessibilityFallback(bool enabled) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final updated = currentSettings.appLockSettings.copyWith(
        useAccessibilityFallback: enabled,
      );
      await setAppLockSettings(updated);
    }
  }

  Future<void> setLockedAppPackageNames(List<String> packageNames) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final updated = currentSettings.appLockSettings.copyWith(
        lockedAppPackageNames: packageNames,
      );
      await setAppLockSettings(updated);
    }
  }

  Future<void> setLockDurationMinutes(int? lockDurationMinutes) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final updated = currentSettings.appLockSettings.copyWith(
        lockDurationMinutes: lockDurationMinutes,
        clearLockDurationMinutes: lockDurationMinutes == null,
      );
      await setAppLockSettings(updated);
    }
  }

  Future<void> toggleEmergencyBypass(bool enabled) async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final updated = currentSettings.appLockSettings.copyWith(
        emergencyBypassEnabled: enabled,
      );
      await setAppLockSettings(updated);
    }
  }

  @override
  Future<void> close() {
    _settingsSubscription?.cancel();
    return super.close();
  }
}
