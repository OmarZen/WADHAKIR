import '../../data/models/bookmark_model.dart';
import 'package:wadhakir/domain/repositories/bookmark_repository.dart';

/// Use case for adding a bookmark
class AddBookmarkUseCase {
  final BookmarkRepository _repository;

  AddBookmarkUseCase(this._repository);

  Future<void> call(BookmarkModel bookmark) async {
    await _repository.addBookmark(bookmark);
  }
}
