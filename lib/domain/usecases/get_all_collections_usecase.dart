import '../../data/models/user_collection_model.dart';
import 'package:wadhakir/domain/repositories/bookmark_repository.dart';

/// Use case for getting all user collections
class GetAllCollectionsUseCase {
  final BookmarkRepository _repository;

  GetAllCollectionsUseCase(this._repository);

  Future<List<UserCollectionModel>> call() async {
    return await _repository.getAllCollections();
  }
}
