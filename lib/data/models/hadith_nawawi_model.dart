/// A single hadith from Imam an-Nawawi's Forty Hadith collection.
class HadithNawawi {
  final int id;
  final String arabic;
  final String englishNarrator;
  final String englishText;

  const HadithNawawi({
    required this.id,
    required this.arabic,
    required this.englishNarrator,
    required this.englishText,
  });

  factory HadithNawawi.fromJson(Map<String, dynamic> json) {
    final english = json['english'];
    return HadithNawawi(
      id: json['id'] as int? ?? 0,
      arabic: json['arabic'] as String? ?? '',
      englishNarrator:
          (english is Map<String, dynamic> ? english['narrator'] : null)
              as String? ??
          '',
      englishText:
          (english is Map<String, dynamic> ? english['text'] : null)
              as String? ??
          '',
    );
  }
}
