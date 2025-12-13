import 'package:wadhakir/domain/repositories/hadith_repository.dart';

/// Use case for getting list of books in a collection
class GetBooksListUseCase {
  final HadithRepository _repository;

  GetBooksListUseCase(this._repository);

  Future<Map<int, String>> call(String collection) async {
    return await _repository.getBooksList(collection);
  }
}
