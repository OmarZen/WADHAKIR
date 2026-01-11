import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Database helper for managing bookmarks and user collections
class BookmarkDatabaseHelper {
  static final BookmarkDatabaseHelper instance =
      BookmarkDatabaseHelper._internal();
  static Database? _database;
  static bool _isInitialized = false;

  BookmarkDatabaseHelper._internal();

  factory BookmarkDatabaseHelper() => instance;

  /// Initialize database factory for desktop platforms
  static void initializeDatabaseFactory() {
    if (!_isInitialized &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _isInitialized = true;
    }
  }

  Future<Database> get database async {
    // Ensure factory is initialized for desktop
    initializeDatabaseFactory();

    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get appropriate database path for all platforms
    String dbPath;
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final appDir = await getApplicationDocumentsDirectory();
        dbPath = appDir.path;
      } else {
        dbPath = await getDatabasesPath();
      }
    } catch (e) {
      // Fallback to getDatabasesPath if getApplicationDocumentsDirectory fails
      dbPath = await getDatabasesPath();
    }

    final path = join(dbPath, 'wadhakir_bookmarks.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Bookmarks table
    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY,
        hadith_id TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        note TEXT,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    // Collections table
    await db.execute('''
      CREATE TABLE collections (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT DEFAULT '📚',
        color TEXT DEFAULT '#3B82F6',
        created_at INTEGER NOT NULL,
        is_default INTEGER DEFAULT 0
      )
    ''');

    // Bookmark-Collection junction table
    await db.execute('''
      CREATE TABLE bookmark_collections (
        bookmark_id TEXT NOT NULL,
        collection_id TEXT NOT NULL,
        PRIMARY KEY (bookmark_id, collection_id),
        FOREIGN KEY (bookmark_id) REFERENCES bookmarks(id) ON DELETE CASCADE,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
      )
    ''');

    // Tags table
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE NOT NULL
      )
    ''');

    // Bookmark-Tag junction table
    await db.execute('''
      CREATE TABLE bookmark_tags (
        bookmark_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (bookmark_id, tag_id),
        FOREIGN KEY (bookmark_id) REFERENCES bookmarks(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    // Reading history table
    await db.execute('''
      CREATE TABLE reading_history (
        hadith_id TEXT PRIMARY KEY,
        last_read INTEGER NOT NULL,
        read_count INTEGER DEFAULT 1
      )
    ''');

    // Create indexes for better query performance
    await db
        .execute('CREATE INDEX idx_bookmarks_hadith ON bookmarks(hadith_id)');
    await db.execute(
        'CREATE INDEX idx_bookmarks_favorite ON bookmarks(is_favorite)');
    await db.execute(
        'CREATE INDEX idx_bookmark_collections_bookmark ON bookmark_collections(bookmark_id)');
    await db.execute(
        'CREATE INDEX idx_bookmark_collections_collection ON bookmark_collections(collection_id)');
    await db.execute(
        'CREATE INDEX idx_reading_history_last_read ON reading_history(last_read)');

    // Insert default "Favorites" collection
    await db.insert('collections', {
      'id': 'favorites',
      'name': 'Favorites',
      'description': 'Your favorite hadiths',
      'icon': '⭐',
      'color': '#FFD700',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'is_default': 1,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    // For now, we'll just recreate tables
    if (oldVersion < newVersion) {
      // Add migration logic here in future versions
    }
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('bookmark_tags');
    await db.delete('bookmark_collections');
    await db.delete('bookmarks');
    await db.delete('tags');
    await db.delete('collections',
        where: 'is_default = 0'); // Keep favorites collection
    await db.delete('reading_history');
  }

  /// Delete database (for complete reset)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wadhakir_bookmarks.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
