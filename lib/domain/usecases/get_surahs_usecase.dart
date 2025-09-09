import 'package:wadhakir/data/models/surah_model.dart';
import 'package:wadhakir/domain/repositories/quran_repository.dart';

class GetSurahsUseCase {
  final QuranRepository _repository;

  GetSurahsUseCase(this._repository);

  Future<List<SurahModel>> call() async {
    return await _repository.getSurahs();
  }
}
