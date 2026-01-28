import 'package:equatable/equatable.dart';
import '../../../data/models/bookmark_model.dart';
import '../../../data/models/user_collection_model.dart';

/// Base state for Bookmark management
abstract class BookmarkState extends Equatable {
  const BookmarkState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BookmarkInitial extends BookmarkState {
  const BookmarkInitial();
}

/// Loading state
class BookmarkLoading extends BookmarkState {
  const BookmarkLoading();
}

/// Bookmarks loaded
class BookmarksLoaded extends BookmarkState {
  final List<BookmarkModel> bookmarks;
  final List<UserCollectionModel> collections;
  final String? selectedCollectionId;
  final int totalCount;

  const BookmarksLoaded({
    required this.bookmarks,
    required this.collections,
    this.selectedCollectionId,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [
        bookmarks,
        collections,
        selectedCollectionId,
        totalCount,
      ];
}

/// Bookmark added successfully
class BookmarkAdded extends BookmarkState {
  final String hadithId;

  const BookmarkAdded(this.hadithId);

  @override
  List<Object?> get props => [hadithId];
}

/// Bookmark removed successfully
class BookmarkRemoved extends BookmarkState {
  final String hadithId;

  const BookmarkRemoved(this.hadithId);

  @override
  List<Object?> get props => [hadithId];
}

/// Collection created successfully
class CollectionCreated extends BookmarkState {
  final UserCollectionModel collection;

  const CollectionCreated(this.collection);

  @override
  List<Object?> get props => [collection];
}

/// Error state
class BookmarkError extends BookmarkState {
  final String message;

  const BookmarkError(this.message);

  @override
  List<Object?> get props => [message];
}
