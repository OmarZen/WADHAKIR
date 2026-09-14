/// The content category a daily-inspiration item belongs to. [mixed] is only
/// used as a *filter* selection (settings), never as an item's own kind.
enum DailyContentType { mixed, ayah, dua, hadith }

/// One curated daily-inspiration entry loaded from
/// `assets/json_data/daily_inspiration.json`.
class DailyInspirationItem {
  /// One of `ayah` | `dua` | `hadith`.
  final String type;
  final String arabic;
  final String reference;
  final String translation;

  const DailyInspirationItem({
    required this.type,
    required this.arabic,
    required this.reference,
    required this.translation,
  });

  /// Whether this item matches a [DailyContentType] filter ([mixed] matches all).
  bool matches(DailyContentType filter) {
    if (filter == DailyContentType.mixed) return true;
    return type == filter.name;
  }

  factory DailyInspirationItem.fromJson(Map<String, dynamic> json) {
    return DailyInspirationItem(
      type: (json['type'] as String? ?? 'ayah').trim(),
      arabic: json['arabic'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
    );
  }
}
