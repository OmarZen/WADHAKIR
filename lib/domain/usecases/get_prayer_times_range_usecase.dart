import 'package:adhan/adhan.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/domain/repositories/prayer_times_repository.dart';

class GetPrayerTimesRangeUseCase {
  final PrayerTimesRepository _repository;

  GetPrayerTimesRangeUseCase(this._repository);

  Future<Map<DateTime, PrayerTimesModel>> call({
    required DateTime startDate,
    required DateTime endDate,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
  }) async {
    return await _repository.getPrayerTimesForRange(
      startDate: startDate,
      endDate: endDate,
      calculationMethod: calculationMethod,
      madhab: madhab,
    );
  }
}
