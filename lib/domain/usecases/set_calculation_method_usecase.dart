import 'package:adhan_dart/adhan_dart.dart';
import 'package:wadhakir/domain/repositories/prayer_times_repository.dart';

class SetCalculationMethodUseCase {
  final PrayerTimesRepository _repository;

  SetCalculationMethodUseCase(this._repository);

  Future<void> call(CalculationParameters parameters) async {
    await _repository.setCalculationParameters(parameters);
  }
}
