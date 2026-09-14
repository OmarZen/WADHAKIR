import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/data/models/fasting/fasting_reminder_settings_model.dart';
import 'package:wadhakir/domain/repositories/fasting_reminders_repository.dart';

/// Implementation of FastingRemindersRepository using SharedPreferences
class FastingRemindersRepositoryImpl implements FastingRemindersRepository {
  static const String _settingsKey = 'fasting_reminder_settings';

  final SharedPreferences _sharedPreferences;
  final StreamController<FastingReminderSettings> _settingsController =
      StreamController<FastingReminderSettings>.broadcast();

  FastingReminderSettings? _cachedSettings;

  FastingRemindersRepositoryImpl(this._sharedPreferences);

  @override
  Future<FastingReminderSettings> getSettings() async {
    // Return cached settings if available
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    // Load from SharedPreferences
    final settingsJson = _sharedPreferences.getString(_settingsKey);

    if (settingsJson != null && settingsJson.isNotEmpty) {
      try {
        // Parse JSON string to Map
        final Map<String, dynamic> jsonMap = jsonDecode(settingsJson);
        // Create settings from JSON map
        _cachedSettings = FastingReminderSettings.fromJson(jsonMap);
      } catch (e) {
        // If parsing fails, use default settings and clear corrupted data
        await _sharedPreferences.remove(_settingsKey);
        _cachedSettings = FastingReminderSettings.defaultSettings();
      }
    } else {
      // No settings found, use defaults
      _cachedSettings = FastingReminderSettings.defaultSettings();
    }

    // Notify stream listeners
    _settingsController.add(_cachedSettings!);
    return _cachedSettings!;
  }

  @override
  Future<void> setSettings(FastingReminderSettings settings) async {
    try {
      // Convert settings to JSON map
      final jsonMap = settings.toJson();
      // Encode to JSON string
      final jsonString = jsonEncode(jsonMap);
      // Save to preferences
      await _sharedPreferences.setString(_settingsKey, jsonString);

      // Update cache
      _cachedSettings = settings;

      // Notify stream listeners
      _settingsController.add(_cachedSettings!);
    } catch (e) {
      // Rethrow to be caught by use case
      rethrow;
    }
  }

  @override
  Stream<FastingReminderSettings> get settingsStream =>
      _settingsController.stream;

  @override
  Future<void> clearSettings() async {
    await _sharedPreferences.remove(_settingsKey);
    _cachedSettings = FastingReminderSettings.defaultSettings();
    _settingsController.add(_cachedSettings!);
  }

  /// Dispose the stream controller when no longer needed
  void dispose() {
    _settingsController.close();
  }
}
