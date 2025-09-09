import 'package:wadhakir/domain/repositories/quran_repository.dart';

class GetPlaceOfRevelationUseCase {
  final QuranRepository _repository;

  GetPlaceOfRevelationUseCase(this._repository);

  Future<String> call(int number) async {
    return await _repository.getPlaceOfRevelation(number);
  }
}
