import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/domain/repositories/prayer_times_repository.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  static const String _calculationMethodKey = 'prayer_times_calculation_method';
  static const String _madhabKey = 'prayer_times_madhab';

  Coordinates? _coordinates;

  @override
  Future<PrayerTimesModel> getPrayerTimes({
    required DateTime date,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
  }) async {
    // Ensure we have coordinates
    final coordinates = await _getCoordinates();

    // Get calculation method and madhab (either from parameters or saved preferences)
    final method = calculationMethod ?? await getCalculationMethod();
    final madhabValue = madhab ?? await getMadhab();

    // Set up parameters for prayer calculation
    final params = method.getParameters();
    params.madhab = madhabValue;

    // Calculate prayer times
    final dateComponents = DateComponents.from(date);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    return PrayerTimesModel.fromPrayerTimes(
      prayerTimes,
      calculationMethod: method,
      coordinates: coordinates,
      date: date,
    );
  }

  @override
  Future<Map<DateTime, PrayerTimesModel>> getPrayerTimesForRange({
    required DateTime startDate,
    required DateTime endDate,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
  }) async {
    // Calculate the number of days in the range
    final daysCount = endDate.difference(startDate).inDays + 1;

    // Get prayer times for each day
    final Map<DateTime, PrayerTimesModel> result = {};
    for (int i = 0; i < daysCount; i++) {
      final date = startDate.add(Duration(days: i));
      final prayerTimesForDay = await getPrayerTimes(
        date: date,
        calculationMethod: calculationMethod,
        madhab: madhab,
      );

      // Store with date at midnight as key for easier lookup
      final dateKey = DateTime(date.year, date.month, date.day);
      result[dateKey] = prayerTimesForDay;
    }

    return result;
  }

  @override
  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }
  }

  @override
  Future<CalculationMethod> getCalculationMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final methodIndex = prefs.getInt(_calculationMethodKey);

    // Default to Muslim World League if not set
    if (methodIndex == null) {
      return CalculationMethod.muslim_world_league;
    }

    // Convert the index back to a CalculationMethod enum
    return CalculationMethod.values[methodIndex];
  }

  @override
  Future<void> setCalculationMethod(CalculationMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_calculationMethodKey, method.index);
  }

  @override
  Future<Madhab> getMadhab() async {
    final prefs = await SharedPreferences.getInstance();
    final madhabIndex = prefs.getInt(_madhabKey);

    // Default to Shafi if not set
    if (madhabIndex == null) {
      return Madhab.shafi;
    }

    // Convert the index back to a Madhab enum
    return Madhab.values[madhabIndex];
  }

  @override
  Future<void> setMadhab(Madhab madhab) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_madhabKey, madhab.index);
  }

  Future<Coordinates> _getCoordinates() async {
    if (_coordinates != null) {
      return _coordinates!;
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Request permission if needed
      await requestLocationPermission();

      // Get the current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _coordinates = Coordinates(position.latitude, position.longitude);
      return _coordinates!;
    } catch (e) {
      debugPrint('Error getting coordinates: $e');
      // Default to Mecca coordinates as fallback
      return Coordinates(21.422487, 39.826206);
    }
  }
}
