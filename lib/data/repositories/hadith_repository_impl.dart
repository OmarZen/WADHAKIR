import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:wadhakir/data/models/hadith_model.dart';
import 'package:wadhakir/domain/repositories/hadith_repository.dart';

/// Implementation of HadithRepository using local JSON files
class HadithRepositoryImpl implements HadithRepository {
  // Cache for loaded hadiths
  final Map<String, List<HadithModel>> _cache = {};

  @override
  Future<List<HadithModel>> loadBook({
    required String collection,
    required int bookNumber,
    List<String> languages = const ['arabic', 'english'],
  }) async {
    final cacheKey = '${collection}_$bookNumber';

    // Return cached if available
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Load hadiths from all requested languages
    Map<String, HadithModel> hadithsById = {};

    for (final language in languages) {
      try {
        final path =
            'assets/json_data/hadiths_json/${collection}_books/$language/$bookNumber.json';
        final jsonString = await rootBundle.loadString(path);
        final List<dynamic> jsonList = json.decode(jsonString);

        for (final jsonItem in jsonList) {
          final hadith = HadithModel.fromJson(
            jsonItem as Map<String, dynamic>,
            collection,
            language,
          );

          if (hadithsById.containsKey(hadith.id)) {
            // Merge translations
            hadithsById[hadith.id] =
                hadithsById[hadith.id]!.mergeTranslation(hadith);
          } else {
            hadithsById[hadith.id] = hadith;
          }
        }
      } catch (e) {
        // Language file might not exist, continue with other languages
        continue;
      }
    }

    final hadiths = hadithsById.values.toList()
      ..sort((a, b) => a.ourHadithNumber.compareTo(b.ourHadithNumber));

    // Cache the results
    _cache[cacheKey] = hadiths;

    return hadiths;
  }

  @override
  Future<Map<int, String>> getBooksList(String collection) async {
    // Try to load book 1 to get the structure
    try {
      final path =
          'assets/json_data/hadiths_json/${collection}_books/arabic/1.json';
      final jsonString = await rootBundle.loadString(path);
      json.decode(jsonString);

      // Get all unique books from the first file
      final Map<int, String> books = {};

      // For now, we'll need to manually define books for each collection
      // In a production app, you'd parse all files or have a metadata file
      books[1] = await _getBookName(collection, 1);

      // Load a few more to discover books
      for (int i = 2; i <= 100; i++) {
        try {
          final bookName = await _getBookName(collection, i);
          if (bookName.isNotEmpty) {
            books[i] = bookName;
          }
        } catch (e) {
          break; // No more books
        }
      }

      return books;
    } catch (e) {
      return {};
    }
  }

  Future<String> _getBookName(String collection, int bookNumber) async {
    try {
      final path =
          'assets/json_data/hadiths_json/${collection}_books/arabic/$bookNumber.json';
      final jsonString = await rootBundle.loadString(path);
      final List<dynamic> jsonList = json.decode(jsonString);

      if (jsonList.isNotEmpty) {
        final firstHadith = jsonList[0] as Map<String, dynamic>;
        return firstHadith['bookName'] ?? '';
      }
    } catch (e) {
      // File doesn't exist
    }
    return '';
  }

  @override
  Future<List<HadithModel>> searchHadiths({
    required String query,
    String? collection,
    int? bookNumber,
  }) async {
    // For now, search in cache only
    // In production, implement full-text search
    final results = <HadithModel>[];

    for (final hadiths in _cache.values) {
      for (final hadith in hadiths) {
        if (collection != null && hadith.collection != collection) continue;
        if (bookNumber != null && hadith.bookNumber != bookNumber) continue;

        if (hadith.hadithTextArabic.contains(query) ||
            (hadith.hadithTextEnglish
                    ?.toLowerCase()
                    .contains(query.toLowerCase()) ??
                false)) {
          results.add(hadith);
        }
      }
    }

    return results;
  }

  @override
  Future<HadithModel?> getHadithById(String hadithId) async {
    // Parse ID: "bukhari_1_1" (format: collection_bookNumber_ourHadithNumber)
    final parts = hadithId.split('_');
    if (parts.length != 3) return null;

    final collection = parts[0];
    final bookNumber = int.tryParse(parts[1]);
    if (bookNumber == null) return null;

    try {
      final hadiths =
          await loadBook(collection: collection, bookNumber: bookNumber);
      return hadiths.firstWhere((h) => h.id == hadithId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<HadithModel> getRandomHadith({String? collection}) async {
    final collections = collection != null
        ? [collection]
        : ['bukhari', 'muslim', 'abudawud', 'tirmidhi', 'forty'];

    final randomCollection = collections[Random().nextInt(collections.length)];

    // For simplicity, try books 1-5
    final randomBook = Random().nextInt(5) + 1;

    try {
      final hadiths =
          await loadBook(collection: randomCollection, bookNumber: randomBook);

      if (hadiths.isEmpty) {
        // Fallback to book 1
        final fallbackHadiths =
            await loadBook(collection: randomCollection, bookNumber: 1);
        return fallbackHadiths[Random().nextInt(fallbackHadiths.length)];
      }

      return hadiths[Random().nextInt(hadiths.length)];
    } catch (e) {
      // Final fallback: load Forty Hadith Nawawi
      final fortyHadiths = await loadBook(collection: 'forty', bookNumber: 1);
      return fortyHadiths[Random().nextInt(fortyHadiths.length)];
    }
  }

  @override
  void clearCache() {
    _cache.clear();
  }
}
