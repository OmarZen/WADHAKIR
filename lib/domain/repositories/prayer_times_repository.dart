import 'package:adhan/adhan.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';

abstract class PrayerTimesRepository {
  Future<PrayerTimesModel> getPrayerTimes({
    required DateTime date,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
  });

  Future<Map<DateTime, PrayerTimesModel>> getPrayerTimesForRange({
    required DateTime startDate,
    required DateTime endDate,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
  });

  Future<void> requestLocationPermission();

  Future<CalculationMethod> getCalculationMethod();

  Future<void> setCalculationMethod(CalculationMethod method);

  Future<Madhab> getMadhab();

  Future<void> setMadhab(Madhab madhab);

  Future<String> getCurrentLocationName();

  Future<void> forceLocationUpdate();

  Future<bool> isLocationServiceEnabled();

  Future<bool> isUsingFallbackLocation();

  Future<bool> isFirstTimeUser();
}
