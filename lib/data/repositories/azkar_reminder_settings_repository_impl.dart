import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/data/models/azkar_reminder_settings_model.dart';

/// Persists daily-azkar-reminder settings, broadcasting changes so the cubit,
/// the settings page, and the contextual prayer-page toggles stay in sync.
/// Mirrors [DailyInspirationSettingsRepositoryImpl] — cache + broadcast stream
/// + a single JSON-encoded key.
class AzkarReminderSettingsRepositoryImpl {
  AzkarReminderSettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;
  final StreamController<AzkarReminderSettingsModel> _controller =
      StreamController<AzkarReminderSettingsModel>.broadcast();
  AzkarReminderSettingsModel? _cache;

  Stream<AzkarReminderSettingsModel> get settingsStream => _controller.stream;

  Future<AzkarReminderSettingsModel> getSettings() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = _prefs.getString(AppConstants.azkarReminderSettingsKey);
    AzkarReminderSettingsModel settings;
    if (raw == null) {
      settings = AzkarReminderSettingsModel.defaultSettings();
    } else {
      try {
        settings = AzkarReminderSettingsModel.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        settings = AzkarReminderSettingsModel.defaultSettings();
      }
    }
    _cache = settings;
    return settings;
  }

  /// Synchronous best-effort read for callers that already have the cache warm
  /// (e.g. the prayer-times cubit on a midnight rollover). Falls back to
  /// parsing the stored JSON, then to defaults.
  AzkarReminderSettingsModel getCachedOrParse() {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = _prefs.getString(AppConstants.azkarReminderSettingsKey);
    if (raw == null) return AzkarReminderSettingsModel.defaultSettings();
    try {
      final s = AzkarReminderSettingsModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      _cache = s;
      return s;
    } catch (_) {
      return AzkarReminderSettingsModel.defaultSettings();
    }
  }

  Future<void> saveSettings(AzkarReminderSettingsModel settings) async {
    _cache = settings;
    await _prefs.setString(
      AppConstants.azkarReminderSettingsKey,
      jsonEncode(settings.toJson()),
    );
    _controller.add(settings);
  }

  void dispose() {
    _controller.close();
  }
}
