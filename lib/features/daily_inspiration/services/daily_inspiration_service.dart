import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:wadhakir/data/models/daily_inspiration_item.dart';

/// Loads and selects the daily-inspiration content.
///
/// The selection index is `dayOfYear % length` so the same item shows all day
/// and rotates at midnight. The native widget recomputes the same index in
/// Kotlin (`(Calendar.DAY_OF_YEAR - 1) % len`) so the widget, the notification
/// and the in-app card always agree on a given day.
class DailyInspirationService {
  DailyInspirationService._internal();
  static final DailyInspirationService _instance =
      DailyInspirationService._internal();
  factory DailyInspirationService() => _instance;

  static const String _assetPath = 'assets/json_data/daily_inspiration.json';

  List<DailyInspirationItem>? _all;

  Future<List<DailyInspirationItem>> _loadAll() async {
    final cached = _all;
    if (cached != null) return cached;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final list = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(DailyInspirationItem.fromJson)
          .where((e) => e.arabic.isNotEmpty)
          .toList();
      _all = list;
      return list;
    } catch (_) {
      _all = const [];
      return const [];
    }
  }

  /// 0-based day-of-year modulo [length]. Matches the Kotlin widget side.
  static int indexFor(int length, DateTime date) {
    if (length <= 0) return 0;
    final dayOfYear = date.difference(DateTime(date.year)).inDays;
    return dayOfYear % length;
  }

  /// All items matching [type] (falls back to the full set if a type filters to
  /// nothing, so a surface never goes blank).
  Future<List<DailyInspirationItem>> filteredItems(
    DailyContentType type,
  ) async {
    final all = await _loadAll();
    if (type == DailyContentType.mixed) return all;
    final filtered = all.where((e) => e.matches(type)).toList();
    return filtered.isEmpty ? all : filtered;
  }

  /// Today's item for the chosen [type], or null when no content is available.
  Future<DailyInspirationItem?> todayItem(
    DailyContentType type, [
    DateTime? now,
  ]) async {
    final items = await filteredItems(type);
    if (items.isEmpty) return null;
    return items[indexFor(items.length, now ?? DateTime.now())];
  }
}
