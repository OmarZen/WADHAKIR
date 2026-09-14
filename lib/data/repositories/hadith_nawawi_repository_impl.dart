import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:wadhakir/data/models/hadith_nawawi_model.dart';

/// Loads the 40 Hadith Nawawi collection from the bundled JSON asset.
class HadithNawawiRepository {
  static const String _asset = 'assets/json_data/40-hadith-nawawi.json';

  List<HadithNawawi>? _cache;

  Future<List<HadithNawawi>> getHadiths() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_asset);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = (map['hadiths'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(HadithNawawi.fromJson)
        .toList();
    _cache = list;
    return list;
  }
}
