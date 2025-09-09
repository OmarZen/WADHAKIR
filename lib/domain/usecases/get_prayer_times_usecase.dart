import 'package:adhan/adhan.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/domain/repositories/prayer_times_repository.dart';

class GetPrayerTimesUseCase {
  final PrayerTimesRepository _repository;

  GetPrayerTimesUseCase(this._repository);

  Future<PrayerTimesModel> call({
    required DateTime date,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
  }) async {
    return await _repository.getPrayerTimes(
      date: date,
      calculationMethod: calculationMethod,
      madhab: madhab,
    );
  }
}
