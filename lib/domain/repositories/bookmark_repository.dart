import 'package:wadhakir/data/models/bookmark_model.dart';
import 'package:wadhakir/data/models/user_collection_model.dart';

/// Repository interface for bookmark operations
abstract class BookmarkRepository {
  // ===== Bookmark Operations =====

  /// Add a bookmark
  Future<void> addBookmark(BookmarkModel bookmark);

  /// Remove a bookmark
  Future<void> removeBookmark(String hadithId);

  /// Check if hadith is bookmarked
  Future<bool> isBookmarked(String hadithId);

  /// Get all bookmarks
  Future<List<BookmarkModel>> getAllBookmarks();

  /// Get bookmarks by collection
  Future<List<BookmarkModel>> getBookmarksByCollection(String collectionId);

  /// Get favorite bookmarks
  Future<List<BookmarkModel>> getFavoriteBookmarks();

  /// Update bookmark note
  Future<void> updateBookmarkNote(String hadithId, String note);

  /// Toggle favorite status
  Future<void> toggleFavorite(String hadithId);

  /// Get bookmark by hadith ID
  Future<BookmarkModel?> getBookmarkByHadithId(String hadithId);

  // ===== Collection Operations =====

  /// Create a new collection
  Future<void> createCollection(UserCollectionModel collection);

  /// Update collection
  Future<void> updateCollection(UserCollectionModel collection);

  /// Delete collection
  Future<void> deleteCollection(String collectionId);

  /// Get all collections
  Future<List<UserCollectionModel>> getAllCollections();

  /// Get collection by ID
  Future<UserCollectionModel?> getCollectionById(String collectionId);

  /// Add bookmark to collection
  Future<void> addBookmarkToCollection(String bookmarkId, String collectionId);

  /// Remove bookmark from collection
  Future<void> removeBookmarkFromCollection(
    String bookmarkId,
    String collectionId,
  );

  /// Get collections for a bookmark
  Future<List<UserCollectionModel>> getCollectionsForBookmark(
    String bookmarkId,
  );

  /// Get bookmark count for a collection
  Future<int> getBookmarkCountForCollection(String collectionId);

  // ===== Tag Operations =====

  /// Add tag to bookmark
  Future<void> addTag(String bookmarkId, String tagName);

  /// Remove tag from bookmark
  Future<void> removeTag(String bookmarkId, String tagId);

  /// Get all tags
  Future<List<String>> getAllTags();

  /// Get tags for a bookmark
  Future<List<String>> getTagsForBookmark(String bookmarkId);

  // ===== Reading History =====

  /// Record a hadith as read
  Future<void> recordRead(String hadithId);

  /// Get reading history
  Future<Map<String, DateTime>> getReadingHistory({int limit = 50});

  /// Get last read hadith
  Future<String?> getLastReadHadithId();

  // ===== Statistics =====

  /// Get total bookmark count
  Future<int> getTotalBookmarkCount();

  /// Get bookmarks created in date range
  Future<int> getBookmarksCreatedInRange(DateTime start, DateTime end);
}
