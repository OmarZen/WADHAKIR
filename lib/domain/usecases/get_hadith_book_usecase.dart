import '../../data/models/hadith_model.dart';
import 'package:wadhakir/domain/repositories/hadith_repository.dart';

/// Use case for loading hadiths from a specific book
class GetHadithBookUseCase {
  final HadithRepository _repository;

  GetHadithBookUseCase(this._repository);

  Future<List<HadithModel>> call({
    required String collection,
    required int bookNumber,
    List<String> languages = const ['arabic', 'english'],
  }) async {
    return await _repository.loadBook(
      collection: collection,
      bookNumber: bookNumber,
      languages: languages,
    );
  }
}
