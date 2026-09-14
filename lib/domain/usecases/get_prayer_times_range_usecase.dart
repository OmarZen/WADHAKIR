import 'package:adhan_dart/adhan_dart.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/domain/repositories/prayer_times_repository.dart';

class GetPrayerTimesRangeUseCase {
  final PrayerTimesRepository _repository;

  GetPrayerTimesRangeUseCase(this._repository);

  Future<Map<DateTime, PrayerTimesModel>> call({
    required DateTime startDate,
    required DateTime endDate,
    CalculationParameters? calculationParameters,
    Madhab? madhab,
  }) async {
    return await _repository.getPrayerTimesForRange(
      startDate: startDate,
      endDate: endDate,
      calculationParameters: calculationParameters,
      madhab: madhab,
    );
  }
}
