import 'package:wadhakir/data/repositories/hadith_nawawi_repository_impl.dart';
import 'package:wadhakir/features/app_lock/services/app_lock_hadith_quotes_service.dart';
import 'package:wadhakir/features/islamic_backgrounds/models/background_quote.dart';

/// The three sources a user can pick a ready-made sentence from.
enum QuoteSource { curated, appQuotes, hadith }

/// Aggregates the ready-made Arabic phrases offered in the text editor:
/// curated short verses/adhkar, the app's existing hadith quotes, and the
/// 40 Nawawi hadith. Reuses the existing loaders so there's one source of
/// truth per dataset.
class BackgroundQuotesService {
  BackgroundQuotesService({
    HadithNawawiRepository? hadithRepository,
    AppLockHadithQuotesService? appQuotesService,
  }) : _hadithRepository = hadithRepository ?? HadithNawawiRepository(),
       _appQuotesService =
           appQuotesService ?? const AppLockHadithQuotesService();

  final HadithNawawiRepository _hadithRepository;
  final AppLockHadithQuotesService _appQuotesService;

  List<BackgroundQuote> get curated => CuratedQuotes.all;

  Future<List<BackgroundQuote>> appQuotes() async {
    final quotes = await _appQuotesService.getAllQuotes(useArabic: true);
    return quotes
        .where((q) => q.message.trim().isNotEmpty)
        .map(
          (q) => BackgroundQuote(
            q.message.trim(),
            q.reference.isEmpty ? null : q.reference,
          ),
        )
        .toList();
  }

  Future<List<BackgroundQuote>> hadith() async {
    final hadiths = await _hadithRepository.getHadiths();
    return hadiths
        .where((h) => h.arabic.trim().isNotEmpty)
        .map((h) => BackgroundQuote(h.arabic.trim(), 'الحديث ${h.id}'))
        .toList();
  }

  Future<List<BackgroundQuote>> forSource(QuoteSource source) {
    switch (source) {
      case QuoteSource.curated:
        return Future.value(curated);
      case QuoteSource.appQuotes:
        return appQuotes();
      case QuoteSource.hadith:
        return hadith();
    }
  }
}
