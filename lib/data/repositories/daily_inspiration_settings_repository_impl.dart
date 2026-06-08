import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/data/models/daily_inspiration_settings_model.dart';

/// Persists "Verse/Dua of the Day" settings, broadcasting changes so both the
/// cubit and the settings page stay in sync (mirrors [AppSettingsRepositoryImpl]
/// — cache + broadcast stream + a single JSON-encoded key).
class DailyInspirationSettingsRepositoryImpl {
  DailyInspirationSettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;
  final StreamController<DailyInspirationSettingsModel> _controller =
      StreamController<DailyInspirationSettingsModel>.broadcast();
  DailyInspirationSettingsModel? _cache;

  Stream<DailyInspirationSettingsModel> get settingsStream =>
      _controller.stream;

  Future<DailyInspirationSettingsModel> getSettings() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = _prefs.getString(AppConstants.dailyInspirationSettingsKey);
    DailyInspirationSettingsModel settings;
    if (raw == null) {
      settings = DailyInspirationSettingsModel.defaultSettings();
    } else {
      try {
        settings = DailyInspirationSettingsModel.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        settings = DailyInspirationSettingsModel.defaultSettings();
      }
    }
    _cache = settings;
    // Note: no emit on read — the cubit reads directly via getSettings(); the
    // stream only propagates subsequent saves (avoids a duplicate apply).
    return settings;
  }

  Future<void> saveSettings(DailyInspirationSettingsModel settings) async {
    _cache = settings;
    await _prefs.setString(
      AppConstants.dailyInspirationSettingsKey,
      jsonEncode(settings.toJson()),
    );
    _controller.add(settings);
  }

  void dispose() {
    _controller.close();
  }
}
