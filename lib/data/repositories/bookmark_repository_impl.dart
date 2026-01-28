import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wadhakir/data/models/bookmark_model.dart';
import 'package:wadhakir/data/models/user_collection_model.dart';
import 'package:wadhakir/domain/repositories/bookmark_repository.dart';
import 'package:wadhakir/data/datasources/bookmark_database_helper.dart';

/// Implementation of BookmarkRepository using SQLite
class BookmarkRepositoryImpl implements BookmarkRepository {
  final BookmarkDatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  BookmarkRepositoryImpl({BookmarkDatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? BookmarkDatabaseHelper.instance;

  // ===== Bookmark Operations =====

  @override
  Future<void> addBookmark(BookmarkModel bookmark) async {
    final db = await _dbHelper.database;
    await db.insert(
      'bookmarks',
      bookmark.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Add to favorites collection by default if it's favorited
    if (bookmark.isFavorite) {
      await addBookmarkToCollection(bookmark.id, 'favorites');
    }
  }

  @override
  Future<void> removeBookmark(String hadithId) async {
    final db = await _dbHelper.database;
    await db.delete('bookmarks', where: 'hadith_id = ?', whereArgs: [hadithId]);
  }

  @override
  Future<bool> isBookmarked(String hadithId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'bookmarks',
      where: 'hadith_id = ?',
      whereArgs: [hadithId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  @override
  Future<List<BookmarkModel>> getAllBookmarks() async {
    final db = await _dbHelper.database;
    final maps = await db.query('bookmarks', orderBy: 'created_at DESC');

    final bookmarks = <BookmarkModel>[];
    for (final map in maps) {
      final bookmark = BookmarkModel.fromMap(map);
      final collections = await getCollectionsForBookmark(bookmark.id);
      final tags = await getTagsForBookmark(bookmark.id);

      bookmarks.add(
        bookmark.copyWith(
          collectionIds: collections.map((c) => c.id).toList(),
          tags: tags,
        ),
      );
    }

    return bookmarks;
  }

  @override
  Future<List<BookmarkModel>> getBookmarksByCollection(
    String collectionId,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT b.* FROM bookmarks b
      INNER JOIN bookmark_collections bc ON b.id = bc.bookmark_id
      WHERE bc.collection_id = ?
      ORDER BY b.created_at DESC
    ''',
      [collectionId],
    );

    final bookmarks = <BookmarkModel>[];
    for (final map in maps) {
      final bookmark = BookmarkModel.fromMap(map);
      final collections = await getCollectionsForBookmark(bookmark.id);
      final tags = await getTagsForBookmark(bookmark.id);

      bookmarks.add(
        bookmark.copyWith(
          collectionIds: collections.map((c) => c.id).toList(),
          tags: tags,
        ),
      );
    }

    return bookmarks;
  }

  @override
  Future<List<BookmarkModel>> getFavoriteBookmarks() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'bookmarks',
      where: 'is_favorite = 1',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => BookmarkModel.fromMap(map)).toList();
  }

  @override
  Future<void> updateBookmarkNote(String hadithId, String note) async {
    final db = await _dbHelper.database;
    await db.update(
      'bookmarks',
      {'note': note, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'hadith_id = ?',
      whereArgs: [hadithId],
    );
  }

  @override
  Future<void> toggleFavorite(String hadithId) async {
    final db = await _dbHelper.database;
    final bookmark = await getBookmarkByHadithId(hadithId);

    if (bookmark != null) {
      final newFavoriteStatus = !bookmark.isFavorite;
      await db.update(
        'bookmarks',
        {
          'is_favorite': newFavoriteStatus ? 1 : 0,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'hadith_id = ?',
        whereArgs: [hadithId],
      );

      // Update favorites collection
      if (newFavoriteStatus) {
        await addBookmarkToCollection(bookmark.id, 'favorites');
      } else {
        await removeBookmarkFromCollection(bookmark.id, 'favorites');
      }
    }
  }

  @override
  Future<BookmarkModel?> getBookmarkByHadithId(String hadithId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'bookmarks',
      where: 'hadith_id = ?',
      whereArgs: [hadithId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final bookmark = BookmarkModel.fromMap(maps.first);
    final collections = await getCollectionsForBookmark(bookmark.id);
    final tags = await getTagsForBookmark(bookmark.id);

    return bookmark.copyWith(
      collectionIds: collections.map((c) => c.id).toList(),
      tags: tags,
    );
  }

  // ===== Collection Operations =====

  @override
  Future<void> createCollection(UserCollectionModel collection) async {
    final db = await _dbHelper.database;
    await db.insert(
      'collections',
      collection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateCollection(UserCollectionModel collection) async {
    final db = await _dbHelper.database;
    await db.update(
      'collections',
      collection.toMap(),
      where: 'id = ?',
      whereArgs: [collection.id],
    );
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    final db = await _dbHelper.database;

    // Don't delete default collection
    final collection = await getCollectionById(collectionId);
    if (collection?.isDefault == true) return;

    await db.delete('collections', where: 'id = ?', whereArgs: [collectionId]);
  }

  @override
  Future<List<UserCollectionModel>> getAllCollections() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'collections',
      orderBy: 'is_default DESC, created_at ASC',
    );

    final collections = <UserCollectionModel>[];
    for (final map in maps) {
      final count = await getBookmarkCountForCollection(map['id'] as String);
      collections.add(
        UserCollectionModel.fromMap(map).copyWith(bookmarkCount: count),
      );
    }

    return collections;
  }

  @override
  Future<UserCollectionModel?> getCollectionById(String collectionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'collections',
      where: 'id = ?',
      whereArgs: [collectionId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final count = await getBookmarkCountForCollection(collectionId);
    return UserCollectionModel.fromMap(
      maps.first,
    ).copyWith(bookmarkCount: count);
  }

  @override
  Future<void> addBookmarkToCollection(
    String bookmarkId,
    String collectionId,
  ) async {
    final db = await _dbHelper.database;
    await db.insert(
        'bookmark_collections',
        {
          'bookmark_id': bookmarkId,
          'collection_id': collectionId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<void> removeBookmarkFromCollection(
    String bookmarkId,
    String collectionId,
  ) async {
    final db = await _dbHelper.database;
    await db.delete(
      'bookmark_collections',
      where: 'bookmark_id = ? AND collection_id = ?',
      whereArgs: [bookmarkId, collectionId],
    );
  }

  @override
  Future<List<UserCollectionModel>> getCollectionsForBookmark(
    String bookmarkId,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT c.* FROM collections c
      INNER JOIN bookmark_collections bc ON c.id = bc.collection_id
      WHERE bc.bookmark_id = ?
      ORDER BY c.is_default DESC, c.name ASC
    ''',
      [bookmarkId],
    );

    return maps.map((map) => UserCollectionModel.fromMap(map)).toList();
  }

  @override
  Future<int> getBookmarkCountForCollection(String collectionId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM bookmark_collections
      WHERE collection_id = ?
    ''',
      [collectionId],
    );

    return (result.first['count'] as int?) ?? 0;
  }

  // ===== Tag Operations =====

  @override
  Future<void> addTag(String bookmarkId, String tagName) async {
    final db = await _dbHelper.database;

    // Get or create tag
    var tagId = _uuid.v4();
    final existingTags = await db.query(
      'tags',
      where: 'name = ?',
      whereArgs: [tagName],
      limit: 1,
    );

    if (existingTags.isNotEmpty) {
      tagId = existingTags.first['id'] as String;
    } else {
      await db.insert('tags', {'id': tagId, 'name': tagName});
    }

    // Link bookmark to tag
    await db.insert(
        'bookmark_tags',
        {
          'bookmark_id': bookmarkId,
          'tag_id': tagId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<void> removeTag(String bookmarkId, String tagId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'bookmark_tags',
      where: 'bookmark_id = ? AND tag_id = ?',
      whereArgs: [bookmarkId, tagId],
    );
  }

  @override
  Future<List<String>> getAllTags() async {
    final db = await _dbHelper.database;
    final maps = await db.query('tags', orderBy: 'name ASC');
    return maps.map((map) => map['name'] as String).toList();
  }

  @override
  Future<List<String>> getTagsForBookmark(String bookmarkId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT t.name FROM tags t
      INNER JOIN bookmark_tags bt ON t.id = bt.tag_id
      WHERE bt.bookmark_id = ?
      ORDER BY t.name ASC
    ''',
      [bookmarkId],
    );

    return maps.map((map) => map['name'] as String).toList();
  }

  // ===== Reading History =====

  @override
  Future<void> recordRead(String hadithId) async {
    final db = await _dbHelper.database;
    final existing = await db.query(
      'reading_history',
      where: 'hadith_id = ?',
      whereArgs: [hadithId],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('reading_history', {
        'hadith_id': hadithId,
        'last_read': DateTime.now().millisecondsSinceEpoch,
        'read_count': 1,
      });
    } else {
      final count = (existing.first['read_count'] as int?) ?? 0;
      await db.update(
        'reading_history',
        {
          'last_read': DateTime.now().millisecondsSinceEpoch,
          'read_count': count + 1,
        },
        where: 'hadith_id = ?',
        whereArgs: [hadithId],
      );
    }
  }

  @override
  Future<Map<String, DateTime>> getReadingHistory({int limit = 50}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'reading_history',
      orderBy: 'last_read DESC',
      limit: limit,
    );

    return Map.fromEntries(
      maps.map(
        (map) => MapEntry(
          map['hadith_id'] as String,
          DateTime.fromMillisecondsSinceEpoch(map['last_read'] as int),
        ),
      ),
    );
  }

  @override
  Future<String?> getLastReadHadithId() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'reading_history',
      orderBy: 'last_read DESC',
      limit: 1,
    );

    return maps.isEmpty ? null : maps.first['hadith_id'] as String;
  }

  // ===== Statistics =====

  @override
  Future<int> getTotalBookmarkCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM bookmarks');
    return (result.first['count'] as int?) ?? 0;
  }

  @override
  Future<int> getBookmarksCreatedInRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM bookmarks
      WHERE created_at >= ? AND created_at <= ?
    ''',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );

    return (result.first['count'] as int?) ?? 0;
  }
}
