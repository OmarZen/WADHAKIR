import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class AppLockHadithQuote {
  final String message;
  final String reference;

  const AppLockHadithQuote({required this.message, required this.reference});
}

class AppLockHadithQuotesService {
  static const String _assetPath =
      'assets/json_data/app_lock_hadith_quotes.json';

  const AppLockHadithQuotesService();

  Future<List<AppLockHadithQuote>> getAllQuotes({
    required bool useArabic,
  }) async {
    try {
      final items = await _loadQuoteItems();
      if (items.isEmpty) {
        return const [
          AppLockHadithQuote(
            message: 'Use this time in something beneficial.',
            reference: '',
          ),
        ];
      }

      return items
          .map((item) => _mapToQuote(item, useArabic: useArabic))
          .toList();
    } catch (_) {
      return const [
        AppLockHadithQuote(
          message: 'Use this time in something beneficial.',
          reference: '',
        ),
      ];
    }
  }

  Future<AppLockHadithQuote> getRandomQuote({required bool useArabic}) async {
    try {
      final items = await _loadQuoteItems();

      if (items.isEmpty) {
        return const AppLockHadithQuote(
          message: 'Use this time in something beneficial.',
          reference: '',
        );
      }

      final selected = items[Random().nextInt(items.length)];
      return _mapToQuote(selected, useArabic: useArabic);
    } catch (_) {
      return const AppLockHadithQuote(
        message: 'Use this time in something beneficial.',
        reference: '',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadQuoteItems() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return (decoded['quotes'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  AppLockHadithQuote _mapToQuote(
    Map<String, dynamic> selected, {
    required bool useArabic,
  }) {
    final messageKey = useArabic ? 'arabicText' : 'englishText';
    final narratorKey = useArabic ? 'narratorArabic' : 'narratorEnglish';
    final sourceKey = useArabic ? 'sourceArabic' : 'sourceEnglish';
    final gradeKey = useArabic ? 'gradeArabic' : 'gradeEnglish';

    final message = (selected[messageKey] as String?)?.trim();
    final narrator = (selected[narratorKey] as String?)?.trim();
    final source = (selected[sourceKey] as String?)?.trim();
    final grade = (selected[gradeKey] as String?)?.trim();
    final link = (selected['referenceLink'] as String?)?.trim();

    final referenceParts = <String>[
      if (narrator != null && narrator.isNotEmpty) narrator,
      if (source != null && source.isNotEmpty) source,
      if (grade != null && grade.isNotEmpty) grade,
      if (link != null && link.isNotEmpty) link,
    ];

    return AppLockHadithQuote(
      message: (message == null || message.isEmpty)
          ? 'Use this time in something beneficial.'
          : message,
      reference: referenceParts.join(' • '),
    );
  }
}
