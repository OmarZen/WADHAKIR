import 'package:wadhakir/data/models/surah_model.dart';
import 'package:wadhakir/domain/repositories/quran_repository.dart';

class GetSurahByNumberUseCase {
  final QuranRepository _repository;

  GetSurahByNumberUseCase(this._repository);

  Future<SurahModel> call(int number) async {
    return await _repository.getSurahByNumber(number);
  }
}
