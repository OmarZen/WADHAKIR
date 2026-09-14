import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// A single after-prayer dhikr: its text and the number of times to repeat it.
class PrayerDhikr {
  final String id;
  final String text;
  final int count;

  const PrayerDhikr({
    required this.id,
    required this.text,
    required this.count,
  });
}

/// Loads and tracks the "الأذكار بعد السلام من الصلاة" category from the
/// bundled adhkar.json, with per-dhikr completion counters in SharedPreferences.
class PrayerAdhkarData {
  PrayerAdhkarData._();

  static const String _asset = 'assets/json_data/adhkar.json';
  static const String _category = 'الأذكار بعد السلام من الصلاة';

  static List<PrayerDhikr>? _cache;

  /// SharedPreferences key for a dhikr's saved counter.
  static String prefsKey(String text) => 'prayer_adhkar_${text.hashCode}';

  static Future<List<PrayerDhikr>> getItems() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_asset);
    final list = jsonDecode(raw) as List<dynamic>;
    final cat = list.whereType<Map<String, dynamic>>().firstWhere(
      (c) => c['category'] == _category,
      orElse: () => <String, dynamic>{},
    );
    final array = (cat['array'] as List<dynamic>? ?? []);
    _cache = array.whereType<Map<String, dynamic>>().map((e) {
      return PrayerDhikr(
        id: '${e['id'] ?? ''}',
        text: e['text'] as String? ?? '',
        count: int.tryParse('${e['count'] ?? '1'}') ?? 1,
      );
    }).toList();
    return _cache!;
  }

  /// Fraction (0..1) of dhikr fully completed (counter reached its required
  /// count). Used by the home daily-progress strip.
  static Future<double> completionFraction() async {
    try {
      final items = await getItems();
      if (items.isEmpty) return 0;
      final prefs = await SharedPreferences.getInstance();
      var done = 0;
      for (final it in items) {
        if ((prefs.getInt(prefsKey(it.text)) ?? 0) >= it.count) done += 1;
      }
      return done / items.length;
    } catch (_) {
      return 0;
    }
  }
}
