import 'package:wadhakir/domain/repositories/bookmark_repository.dart';

/// Use case for removing a bookmark
class RemoveBookmarkUseCase {
  final BookmarkRepository _repository;

  RemoveBookmarkUseCase(this._repository);

  Future<void> call(String hadithId) async {
    await _repository.removeBookmark(hadithId);
  }
}
