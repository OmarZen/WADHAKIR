import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/data/models/zakat_settings_model.dart';

/// Thin persistence wrapper for the Zakat Calculator's last inputs.
///
/// Intentionally lightweight: the calculator is a single self-contained screen
/// with no other listeners, so there is no StreamController here (unlike
/// [AppSettingsRepositoryImpl]). It just JSON-encodes the model under one
/// SharedPreferences key, with an in-memory cache.
class ZakatSettingsRepositoryImpl {
  ZakatSettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;
  ZakatSettingsModel? _cache;

  /// Load the saved settings (or defaults). Synchronous because the caller
  /// already holds an initialized [SharedPreferences].
  ZakatSettingsModel getSettings() {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = _prefs.getString(AppConstants.zakatSettingsKey);
    ZakatSettingsModel settings;
    if (raw == null) {
      settings = ZakatSettingsModel.defaultSettings();
    } else {
      try {
        settings = ZakatSettingsModel.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        // Corrupt/legacy payload — fall back to defaults rather than crash.
        settings = ZakatSettingsModel.defaultSettings();
      }
    }
    _cache = settings;
    return settings;
  }

  Future<void> saveSettings(ZakatSettingsModel settings) async {
    _cache = settings;
    await _prefs.setString(
      AppConstants.zakatSettingsKey,
      jsonEncode(settings.toJson()),
    );
  }
}
