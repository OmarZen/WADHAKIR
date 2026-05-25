import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'floating_dhikr_settings.dart';

/// SharedPreferences-backed store for [FloatingDhikrSettings]. Mirrors the
/// JSON-blob pattern already used by `AppSettingsRepositoryImpl` so future
/// developers don't need to learn a new convention.
class FloatingDhikrRepository {
  Future<FloatingDhikrSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(FloatingDhikrSettings.prefsKey);
      if (raw == null || raw.isEmpty) {
        return const FloatingDhikrSettings();
      }
      return FloatingDhikrSettings.decode(raw);
    } catch (e) {
      debugPrint('FloatingDhikrRepository.load error: $e');
      return const FloatingDhikrSettings();
    }
  }

  Future<void> save(FloatingDhikrSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      FloatingDhikrSettings.prefsKey,
      settings.encode(),
    );
  }
}
