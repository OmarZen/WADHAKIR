import 'package:adhan_dart/adhan_dart.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';

abstract class PrayerTimesRepository {
  Future<PrayerTimesModel> getPrayerTimes({
    required DateTime date,
    CalculationParameters? calculationParameters,
    Madhab? madhab,
  });

  Future<Map<DateTime, PrayerTimesModel>> getPrayerTimesForRange({
    required DateTime startDate,
    required DateTime endDate,
    CalculationParameters? calculationParameters,
    Madhab? madhab,
  });

  Future<void> requestLocationPermission();

  Future<CalculationParameters> getCalculationParameters();

  Future<void> setCalculationParameters(CalculationParameters parameters);

  Future<Madhab> getMadhab();

  Future<void> setMadhab(Madhab madhab);

  Future<String> getCurrentLocationName();

  Future<void> forceLocationUpdate();

  Future<bool> isLocationServiceEnabled();

  Future<bool> isUsingFallbackLocation();

  Future<bool> isFirstTimeUser();
}
