import 'package:equatable/equatable.dart';

/// Represents a single hadith from any collection
class HadithModel extends Equatable {
  final String id; // Unique: "bukhari_1_1"
  final String collection; // "bukhari", "muslim", etc.
  final int volumeNumber;
  final int bookNumber;
  final String bookName;
  final String? babName;
  final String hadithNumber;
  final String hadithTextArabic;
  final String? hadithTextEnglish;
  final String? hadithTextUrdu;
  final String? hadithTextBangla;
  final String? narrator; // Extracted from sanad
  final String? grade; // Authenticity grade
  final int ourHadithNumber;
  final DateTime? lastRead; // Track reading history

  const HadithModel({
    required this.id,
    required this.collection,
    required this.volumeNumber,
    required this.bookNumber,
    required this.bookName,
    this.babName,
    required this.hadithNumber,
    required this.hadithTextArabic,
    this.hadithTextEnglish,
    this.hadithTextUrdu,
    this.hadithTextBangla,
    this.narrator,
    this.grade,
    required this.ourHadithNumber,
    this.lastRead,
  });

  /// Creates HadithModel from JSON (from asset files)
  factory HadithModel.fromJson(
    Map<String, dynamic> json,
    String collection,
    String language,
  ) {
    // Generate unique ID using ourHadithNumber for consistency across languages
    final id = '${collection}_${json['bookNumber']}_${json['ourHadithNumber']}';

    if (language == 'arabic') {
      return HadithModel(
        id: id,
        collection: collection,
        volumeNumber: json['volumeNumber'] ?? 0,
        bookNumber: json['bookNumber'] ?? 0,
        bookName: json['bookName'] ?? '',
        babName: json['babName'],
        hadithNumber: json['hadithNumber']?.toString() ?? '',
        hadithTextArabic: _cleanHtmlTags(json['hadithText'] ?? ''),
        narrator: _extractNarrator(json['hadithText']),
        grade: json['grade1'],
        ourHadithNumber: json['ourHadithNumber'] ?? 0,
      );
    } else if (language == 'english') {
      return HadithModel(
        id: id,
        collection: collection,
        volumeNumber: json['volumeNumber'] ?? 0,
        bookNumber: json['bookNumber'] ?? 0,
        bookName: json['bookName'] ?? '',
        babName: json['babName'],
        hadithNumber: json['hadithNumber']?.toString() ?? '',
        hadithTextArabic: '', // Will be merged later
        hadithTextEnglish: _cleanHtmlTags(json['hadithText'] ?? ''),
        grade: json['grade1'],
        ourHadithNumber: json['ourHadithNumber'] ?? 0,
      );
    } else if (language == 'urdu') {
      return HadithModel(
        id: id,
        collection: collection,
        volumeNumber: json['volumeNumber'] ?? 0,
        bookNumber: json['bookNumber'] ?? 0,
        bookName: json['bookName'] ?? '',
        babName: json['babName'],
        hadithNumber: json['hadithNumber']?.toString() ?? '',
        hadithTextArabic: '', // Will be merged later
        hadithTextUrdu: _cleanHtmlTags(json['hadithText'] ?? ''),
        grade: json['grade1'],
        ourHadithNumber: json['ourHadithNumber'] ?? 0,
      );
    } else if (language == 'bangla') {
      return HadithModel(
        id: id,
        collection: collection,
        volumeNumber: json['volumeNumber'] ?? 0,
        bookNumber: json['bookNumber'] ?? 0,
        bookName: json['bookName'] ?? '',
        babName: json['babName'],
        hadithNumber: json['hadithNumber']?.toString() ?? '',
        hadithTextArabic: '', // Will be merged later
        hadithTextBangla: _cleanHtmlTags(json['hadithText'] ?? ''),
        grade: json['grade1'],
        ourHadithNumber: json['ourHadithNumber'] ?? 0,
      );
    }

    throw Exception('Unsupported language: $language');
  }

  /// Merges translations into single hadith model
  HadithModel mergeTranslation(HadithModel other) {
    return HadithModel(
      id: id,
      collection: collection,
      volumeNumber: volumeNumber,
      bookNumber: bookNumber,
      bookName: bookName.isNotEmpty ? bookName : other.bookName,
      babName: babName ?? other.babName,
      hadithNumber: hadithNumber,
      hadithTextArabic: hadithTextArabic.isNotEmpty
          ? hadithTextArabic
          : other.hadithTextArabic,
      hadithTextEnglish: hadithTextEnglish ?? other.hadithTextEnglish,
      hadithTextUrdu: hadithTextUrdu ?? other.hadithTextUrdu,
      hadithTextBangla: hadithTextBangla ?? other.hadithTextBangla,
      narrator: narrator ?? other.narrator,
      grade: grade ?? other.grade,
      ourHadithNumber: ourHadithNumber,
      lastRead: lastRead ?? other.lastRead,
    );
  }

  /// Clean HTML tags from hadith text
  static String _cleanHtmlTags(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\r\n|\n|\r'), '\n')
        .trim();
  }

  /// Extract narrator from hadith text (simplified)
  static String? _extractNarrator(String? text) {
    if (text == null || text.isEmpty) return null;

    // Look for common narrator patterns in Arabic
    final narratorPattern = RegExp(r'عن\s+([^،]+)');
    final match = narratorPattern.firstMatch(text);
    if (match != null) {
      return match.group(1)?.trim();
    }

    return null;
  }

  /// Copy with method for updating fields
  HadithModel copyWith({
    String? id,
    String? collection,
    int? volumeNumber,
    int? bookNumber,
    String? bookName,
    String? babName,
    String? hadithNumber,
    String? hadithTextArabic,
    String? hadithTextEnglish,
    String? hadithTextUrdu,
    String? hadithTextBangla,
    String? narrator,
    String? grade,
    int? ourHadithNumber,
    DateTime? lastRead,
  }) {
    return HadithModel(
      id: id ?? this.id,
      collection: collection ?? this.collection,
      volumeNumber: volumeNumber ?? this.volumeNumber,
      bookNumber: bookNumber ?? this.bookNumber,
      bookName: bookName ?? this.bookName,
      babName: babName ?? this.babName,
      hadithNumber: hadithNumber ?? this.hadithNumber,
      hadithTextArabic: hadithTextArabic ?? this.hadithTextArabic,
      hadithTextEnglish: hadithTextEnglish ?? this.hadithTextEnglish,
      hadithTextUrdu: hadithTextUrdu ?? this.hadithTextUrdu,
      hadithTextBangla: hadithTextBangla ?? this.hadithTextBangla,
      narrator: narrator ?? this.narrator,
      grade: grade ?? this.grade,
      ourHadithNumber: ourHadithNumber ?? this.ourHadithNumber,
      lastRead: lastRead ?? this.lastRead,
    );
  }

  @override
  List<Object?> get props => [
    id,
    collection,
    volumeNumber,
    bookNumber,
    bookName,
    babName,
    hadithNumber,
    hadithTextArabic,
    hadithTextEnglish,
    hadithTextUrdu,
    hadithTextBangla,
    narrator,
    grade,
    ourHadithNumber,
    lastRead,
  ];
}
