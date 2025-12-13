import 'package:uuid/uuid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/bookmark_model.dart';
import '../../../data/models/user_collection_model.dart';
import 'package:wadhakir/domain/usecases/add_bookmark_usecase.dart';
import 'package:wadhakir/domain/usecases/remove_bookmark_usecase.dart';
import 'package:wadhakir/domain/repositories/bookmark_repository.dart';
import 'package:wadhakir/domain/usecases/get_all_bookmarks_usecase.dart';
import 'package:wadhakir/domain/usecases/get_all_collections_usecase.dart';
import 'package:wadhakir/features/hadith_library/cubit/bookmark_state.dart';

/// Cubit for managing bookmarks
class BookmarkCubit extends Cubit<BookmarkState> {
  final AddBookmarkUseCase _addBookmarkUseCase;
  final RemoveBookmarkUseCase _removeBookmarkUseCase;
  final GetAllBookmarksUseCase _getAllBookmarksUseCase;
  final GetAllCollectionsUseCase _getAllCollectionsUseCase;
  final BookmarkRepository _bookmarkRepository;
  final Uuid _uuid = const Uuid();

  BookmarkCubit({
    required AddBookmarkUseCase addBookmarkUseCase,
    required RemoveBookmarkUseCase removeBookmarkUseCase,
    required GetAllBookmarksUseCase getAllBookmarksUseCase,
    required GetAllCollectionsUseCase getAllCollectionsUseCase,
    required BookmarkRepository bookmarkRepository,
  })  : _addBookmarkUseCase = addBookmarkUseCase,
        _removeBookmarkUseCase = removeBookmarkUseCase,
        _getAllBookmarksUseCase = getAllBookmarksUseCase,
        _getAllCollectionsUseCase = getAllCollectionsUseCase,
        _bookmarkRepository = bookmarkRepository,
        super(const BookmarkInitial());

  /// Load all bookmarks
  Future<void> loadBookmarks({String? collectionId}) async {
    try {
      emit(const BookmarkLoading());

      final bookmarks = collectionId != null
          ? await _bookmarkRepository.getBookmarksByCollection(collectionId)
          : await _getAllBookmarksUseCase();

      final collections = await _getAllCollectionsUseCase();
      final totalCount = await _bookmarkRepository.getTotalBookmarkCount();

      emit(BookmarksLoaded(
        bookmarks: bookmarks,
        collections: collections,
        selectedCollectionId: collectionId,
        totalCount: totalCount,
      ));
    } catch (e) {
      emit(BookmarkError('Failed to load bookmarks: ${e.toString()}'));
    }
  }

  /// Add a bookmark
  Future<void> addBookmark({
    required String hadithId,
    List<String>? collectionIds,
    bool isFavorite = false,
  }) async {
    try {
      final bookmark = BookmarkModel(
        id: _uuid.v4(),
        hadithId: hadithId,
        createdAt: DateTime.now(),
        collectionIds: collectionIds ?? [],
        isFavorite: isFavorite,
      );

      await _addBookmarkUseCase(bookmark);

      // Add to collections
      if (collectionIds != null && collectionIds.isNotEmpty) {
        for (final collectionId in collectionIds) {
          await _bookmarkRepository.addBookmarkToCollection(
            bookmark.id,
            collectionId,
          );
        }
      }

      emit(BookmarkAdded(hadithId));

      // Reload bookmarks to refresh UI
      await loadBookmarks();
    } catch (e) {
      emit(BookmarkError('Failed to add bookmark: ${e.toString()}'));
    }
  }

  /// Remove a bookmark
  Future<void> removeBookmark(String hadithId) async {
    try {
      await _removeBookmarkUseCase(hadithId);
      emit(BookmarkRemoved(hadithId));

      // Reload bookmarks to refresh UI
      await loadBookmarks();
    } catch (e) {
      emit(BookmarkError('Failed to remove bookmark: ${e.toString()}'));
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String hadithId) async {
    try {
      await _bookmarkRepository.toggleFavorite(hadithId);
      await loadBookmarks();
    } catch (e) {
      emit(BookmarkError('Failed to toggle favorite: ${e.toString()}'));
    }
  }

  /// Create a new collection
  Future<void> createCollection({
    required String name,
    String? description,
    String icon = '📚',
    String color = '#3B82F6',
  }) async {
    try {
      final collection = UserCollectionModel(
        id: _uuid.v4(),
        name: name,
        description: description,
        icon: icon,
        color: color,
        createdAt: DateTime.now(),
      );

      await _bookmarkRepository.createCollection(collection);
      emit(CollectionCreated(collection));

      // Reload to show new collection
      await loadBookmarks();
    } catch (e) {
      emit(BookmarkError('Failed to create collection: ${e.toString()}'));
    }
  }

  /// Delete a collection
  Future<void> deleteCollection(String collectionId) async {
    try {
      await _bookmarkRepository.deleteCollection(collectionId);
      await loadBookmarks();
    } catch (e) {
      emit(BookmarkError('Failed to delete collection: ${e.toString()}'));
    }
  }

  /// Check if hadith is bookmarked
  Future<bool> isBookmarked(String hadithId) async {
    return await _bookmarkRepository.isBookmarked(hadithId);
  }

  /// Add bookmark to collection
  Future<void> addToCollection(String hadithId, String collectionId) async {
    try {
      final bookmark =
          await _bookmarkRepository.getBookmarkByHadithId(hadithId);
      if (bookmark != null) {
        await _bookmarkRepository.addBookmarkToCollection(
          bookmark.id,
          collectionId,
        );
        await loadBookmarks();
      }
    } catch (e) {
      emit(BookmarkError('Failed to add to collection: ${e.toString()}'));
    }
  }

  /// Filter bookmarks by collection
  Future<void> filterByCollection(String? collectionId) async {
    await loadBookmarks(collectionId: collectionId);
  }
}
