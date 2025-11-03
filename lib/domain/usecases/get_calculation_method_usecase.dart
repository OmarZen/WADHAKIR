import 'package:adhan_dart/adhan_dart.dart';
import 'package:wadhakir/domain/repositories/prayer_times_repository.dart';

class GetCalculationMethodUseCase {
  final PrayerTimesRepository _repository;

  GetCalculationMethodUseCase(this._repository);

  Future<CalculationParameters> call() async {
    return await _repository.getCalculationParameters();
  }
}
