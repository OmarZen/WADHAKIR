import '../../data/models/bookmark_model.dart';
import 'package:wadhakir/domain/repositories/bookmark_repository.dart';

/// Use case for getting all bookmarks
class GetAllBookmarksUseCase {
  final BookmarkRepository _repository;

  GetAllBookmarksUseCase(this._repository);

  Future<List<BookmarkModel>> call() async {
    return await _repository.getAllBookmarks();
  }
}
