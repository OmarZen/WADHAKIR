import 'package:wadhakir/data/models/verse_model.dart';
import 'package:wadhakir/domain/repositories/quran_repository.dart';

class GetVersesBySurahUseCase {
  final QuranRepository _repository;

  GetVersesBySurahUseCase(this._repository);

  Future<List<VerseModel>> call(int surahNumber) async {
    return await _repository.getVersesBySurah(surahNumber);
  }
}
