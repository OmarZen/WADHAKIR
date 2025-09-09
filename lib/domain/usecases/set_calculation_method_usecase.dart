import 'package:adhan/adhan.dart';
import 'package:wadhakir/domain/repositories/prayer_times_repository.dart';

class SetCalculationMethodUseCase {
  final PrayerTimesRepository _repository;

  SetCalculationMethodUseCase(this._repository);

  Future<void> call(CalculationMethod method) async {
    await _repository.setCalculationMethod(method);
  }
}
