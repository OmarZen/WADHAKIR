import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/hadith_collection_metadata.dart';
import 'package:wadhakir/domain/usecases/get_books_list_usecase.dart';
import 'package:wadhakir/domain/usecases/get_hadith_book_usecase.dart';
import 'package:wadhakir/domain/repositories/bookmark_repository.dart';
import 'package:wadhakir/features/hadith_library/cubit/hadith_library_state.dart';

/// Cubit for managing hadith library state
class HadithLibraryCubit extends Cubit<HadithLibraryState> {
  final GetHadithBookUseCase _getHadithBookUseCase;
  final GetBooksListUseCase _getBooksListUseCase;
  final BookmarkRepository _bookmarkRepository;

  HadithLibraryCubit({
    required GetHadithBookUseCase getHadithBookUseCase,
    required GetBooksListUseCase getBooksListUseCase,
    required BookmarkRepository bookmarkRepository,
  })  : _getHadithBookUseCase = getHadithBookUseCase,
        _getBooksListUseCase = getBooksListUseCase,
        _bookmarkRepository = bookmarkRepository,
        super(const HadithLibraryInitial());

  /// Load all collections (home screen)
  Future<void> loadCollections() async {
    try {
      emit(const HadithLibraryLoading());

      final allCollections = HadithCollectionMetadata.getAllCollections();
      final popularCollections =
          HadithCollectionMetadata.getPopularCollections();

      emit(
        HadithCollectionsLoaded(
          collections: allCollections,
          popularCollections: popularCollections,
        ),
      );
    } catch (e) {
      emit(HadithLibraryError('Failed to load collections: ${e.toString()}'));
    }
  }

  /// Load books for a specific collection
  Future<void> loadBooks(String collectionId) async {
    try {
      emit(const HadithLibraryLoading());

      final collection = HadithCollectionMetadata.getById(collectionId);
      if (collection == null) {
        emit(const HadithLibraryError('Collection not found'));
        return;
      }

      final books = await _getBooksListUseCase(collectionId);

      emit(
        HadithBooksLoaded(
          collectionId: collectionId,
          collection: collection,
          books: books,
        ),
      );
    } catch (e) {
      emit(HadithLibraryError('Failed to load books: ${e.toString()}'));
    }
  }

  /// Load hadiths for a specific book
  Future<void> loadHadiths({
    required String collectionId,
    required int bookNumber,
    List<String> languages = const ['arabic', 'english'],
  }) async {
    try {
      emit(const HadithLibraryLoading());

      final hadiths = await _getHadithBookUseCase(
        collection: collectionId,
        bookNumber: bookNumber,
        languages: languages,
      );

      if (hadiths.isEmpty) {
        emit(const HadithLibraryError('No hadiths found in this book'));
        return;
      }

      final bookName = hadiths.first.bookName;

      emit(
        HadithsLoaded(
          collectionId: collectionId,
          bookNumber: bookNumber,
          bookName: bookName,
          hadiths: hadiths,
          activeLanguages: languages,
        ),
      );
    } catch (e) {
      emit(HadithLibraryError('Failed to load hadiths: ${e.toString()}'));
    }
  }

  /// Load a single hadith for reader view
  Future<void> loadHadithForReader(
    String hadithId, {
    List<String> languages = const ['arabic', 'english'],
  }) async {
    try {
      emit(const HadithLibraryLoading());

      // Parse hadith ID: "bukhari_1_1"
      final parts = hadithId.split('_');
      if (parts.length != 3) {
        emit(const HadithLibraryError('Invalid hadith ID'));
        return;
      }

      final collection = parts[0];
      final bookNumber = int.parse(parts[1]);

      final hadiths = await _getHadithBookUseCase(
        collection: collection,
        bookNumber: bookNumber,
        languages: languages,
      );

      final hadith = hadiths.firstWhere((h) => h.id == hadithId);

      // Check if bookmarked
      final isBookmarked = await _bookmarkRepository.isBookmarked(hadithId);

      // Get available languages from metadata
      final collectionMetadata = HadithCollectionMetadata.getById(collection);
      final availableLanguages =
          collectionMetadata?.availableLanguages ?? ['arabic', 'english'];

      emit(
        HadithReaderLoaded(
          hadith: hadith,
          availableLanguages: availableLanguages,
          activeLanguages: languages,
          isBookmarked: isBookmarked,
        ),
      );

      // Record as read
      await _bookmarkRepository.recordRead(hadithId);
    } catch (e) {
      emit(HadithLibraryError('Failed to load hadith: ${e.toString()}'));
    }
  }

  /// Toggle language in reader
  Future<void> toggleLanguage(String language) async {
    final currentState = state;
    if (currentState is HadithReaderLoaded) {
      final activeLanguages = List<String>.from(currentState.activeLanguages);

      if (activeLanguages.contains(language)) {
        activeLanguages.remove(language);
      } else {
        activeLanguages.add(language);
      }

      // Need at least one language active
      if (activeLanguages.isEmpty) return;

      await loadHadithForReader(
        currentState.hadith.id,
        languages: activeLanguages,
      );
    }
  }

  /// Refresh bookmark status
  Future<void> refreshBookmarkStatus() async {
    final currentState = state;
    if (currentState is HadithReaderLoaded) {
      final isBookmarked = await _bookmarkRepository.isBookmarked(
        currentState.hadith.id,
      );

      emit(
        HadithReaderLoaded(
          hadith: currentState.hadith,
          availableLanguages: currentState.availableLanguages,
          activeLanguages: currentState.activeLanguages,
          isBookmarked: isBookmarked,
        ),
      );
    }
  }
}
