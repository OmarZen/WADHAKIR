import '../../data/models/hadith_model.dart';
import 'package:wadhakir/domain/repositories/hadith_repository.dart';

/// Use case for getting a random hadith
class GetRandomHadithUseCase {
  final HadithRepository _repository;

  GetRandomHadithUseCase(this._repository);

  Future<HadithModel> call({String? collection}) async {
    return await _repository.getRandomHadith(collection: collection);
  }
}
