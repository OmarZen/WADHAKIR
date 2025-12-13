import 'package:wadhakir/data/models/hadith_model.dart';

/// Repository interface for hadith operations
abstract class HadithRepository {
  /// Load hadiths from a specific book
  Future<List<HadithModel>> loadBook({
    required String collection,
    required int bookNumber,
    List<String> languages = const ['arabic', 'english'],
  });

  /// Load all books metadata for a collection
  Future<Map<int, String>> getBooksList(String collection);

  /// Search hadiths by text
  Future<List<HadithModel>> searchHadiths({
    required String query,
    String? collection,
    int? bookNumber,
  });

  /// Get a single hadith by ID
  Future<HadithModel?> getHadithById(String hadithId);

  /// Get random hadith
  Future<HadithModel> getRandomHadith({String? collection});

  /// Clear cache
  void clearCache();
}
