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

  Future<bool> hasLocationPermission();

  Future<CalculationParameters> getCalculationParameters();

  Future<void> setCalculationParameters(CalculationParameters parameters);

  Future<Madhab> getMadhab();

  Future<void> setMadhab(Madhab madhab);

  Future<String> getCurrentLocationName();

  Future<void> forceLocationUpdate();

  /// Fetches a fresh device position in the background and persists it.
  /// Returns true only when the new location differs materially (> ~500m)
  /// from the one currently in use, so callers can silently recompute prayer
  /// times only when it actually matters. Never throws.
  Future<bool> refreshLocation();

  Future<bool> isLocationServiceEnabled();

  Future<bool> isUsingFallbackLocation();

  Future<bool> isFirstTimeUser();
}
