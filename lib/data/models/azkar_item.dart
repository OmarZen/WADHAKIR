class AdhkarItem {
  final int id;
  final String text;
  final int count;
  final String? audio;
  final String? filename;
  // Hadith / Quran source for this dhikr. Optional — older JSON entries may
  // omit it, in which case the UI hides the source row. `source` and
  // `reference` are accepted as aliases since the two existing data files in
  // the app use different key names.
  final String? reference;

  AdhkarItem({
    required this.id,
    required this.text,
    required this.count,
    this.audio,
    this.filename,
    this.reference,
  });

  factory AdhkarItem.fromJson(Map<String, dynamic> json) {
    final reference = (json['reference'] ?? json['source']) as String?;
    return AdhkarItem(
      id: json['id'] as int? ?? 0,
      text: json['text'] as String,
      // adhkar.json uses `count`; pray_azkar.json uses `repeat`. Accept both
      // so the same model can back either data source.
      count: (json['count'] ?? json['repeat']) as int? ?? 1,
      audio: json['audio'] as String?,
      filename: json['filename'] as String?,
      reference: (reference != null && reference.isNotEmpty) ? reference : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'count': count,
      'audio': audio,
      'filename': filename,
      if (reference != null) 'reference': reference,
    };
  }
}
