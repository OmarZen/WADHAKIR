import 'package:adhan_dart/adhan_dart.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/domain/repositories/prayer_times_repository.dart';

class GetPrayerTimesUseCase {
  final PrayerTimesRepository _repository;

  GetPrayerTimesUseCase(this._repository);

  Future<PrayerTimesModel> call({
    required DateTime date,
    CalculationParameters? calculationParameters,
    Madhab? madhab,
  }) async {
    return await _repository.getPrayerTimes(
      date: date,
      calculationParameters: calculationParameters,
      madhab: madhab,
    );
  }
}
