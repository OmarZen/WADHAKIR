import 'package:adhan/adhan.dart';
import 'package:wadhakir/domain/repositories/prayer_times_repository.dart';

class GetCalculationMethodUseCase {
  final PrayerTimesRepository _repository;

  GetCalculationMethodUseCase(this._repository);

  Future<CalculationMethod> call() async {
    return await _repository.getCalculationMethod();
  }
} 