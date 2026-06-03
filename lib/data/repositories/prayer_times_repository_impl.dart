import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/core/utils/calculation_method_mapper.dart';
import 'package:wadhakir/domain/repositories/prayer_times_repository.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  static const String _calculationMethodKey = 'prayer_times_calculation_method';
  static const String _madhabKey = 'prayer_times_madhab';
  static const String _lastLatitudeKey = 'prayer_times_last_latitude';
  static const String _lastLongitudeKey = 'prayer_times_last_longitude';
  static const String _lastLocationNameKey = 'prayer_times_last_location_name';
  static const String _calcMethodAutoDetectedKey =
      'prayer_times_calc_method_auto_detected';

  Coordinates? _coordinates;

  @override
  Future<PrayerTimesModel> getPrayerTimes({
    required DateTime date,
    CalculationParameters? calculationParameters,
    Madhab? madhab,
  }) async {
    // Ensure we have coordinates
    final coordinates = await _getCoordinates();

    // Get calculation parameters and madhab (either from parameters or saved preferences)
    final params = calculationParameters ?? await getCalculationParameters();
    final madhabValue = madhab ?? await getMadhab();

    // Set madhab on parameters
    params.madhab = madhabValue;

    // adhan_dart expects a UTC date representing the intended calendar day at the
    // user's location. Passing a local DateTime causes the library's internal
    // toUtc() to shift the date by the local offset, producing prayer times for
    // the wrong solar day (the ~1h drift reported by users east of UTC).
    final dateUtc = DateTime.utc(date.year, date.month, date.day);

    // Calculate prayer times using adhan_dart
    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: dateUtc,
      calculationParameters: params,
      precision: true, // Use second-level precision
    );

    return PrayerTimesModel.fromPrayerTimes(
      prayerTimes,
      calculationParameters: params,
      coordinates: coordinates,
      date: date,
    );
  }

  @override
  Future<Map<DateTime, PrayerTimesModel>> getPrayerTimesForRange({
    required DateTime startDate,
    required DateTime endDate,
    CalculationParameters? calculationParameters,
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
        calculationParameters: calculationParameters,
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
  Future<bool> hasLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  @override
  Future<CalculationParameters> getCalculationParameters() async {
    final prefs = await SharedPreferences.getInstance();
    final methodName = prefs.getString(_calculationMethodKey);

    // Default to the Egyptian General Authority of Survey method
    // ("الهيئة المصرية العامة للمساحة") for first-time installs. This is the
    // most widely-trusted method across the Middle East and matches the
    // primary audience for the app. Users in other regions can still pick
    // a different method from settings; once they do, `methodName` will
    // be non-null on the next launch and this branch is skipped.
    if (methodName == null) {
      return CalculationMethodMapper.getParameters('egyptian');
    }

    return CalculationMethodMapper.getParameters(methodName);
  }

  @override
  Future<void> setCalculationParameters(
    CalculationParameters parameters,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final methodName = CalculationMethodMapper.getMethodName(parameters);
    await prefs.setString(_calculationMethodKey, methodName);
  }

  @override
  Future<Madhab> getMadhab() async {
    final prefs = await SharedPreferences.getInstance();
    final madhabString = prefs.getString(_madhabKey);

    // Default to Shafi if not set
    if (madhabString == null || madhabString == 'shafi') {
      return Madhab.shafi;
    }

    return Madhab.hanafi;
  }

  @override
  Future<void> setMadhab(Madhab madhab) async {
    final prefs = await SharedPreferences.getInstance();
    final madhabString = madhab == Madhab.hanafi ? 'hanafi' : 'shafi';
    await prefs.setString(_madhabKey, madhabString);
  }

  Future<Coordinates> _getCoordinates() async {
    if (_coordinates != null) {
      return _coordinates!;
    }

    // Saved-location-first: if a location was persisted on a previous run, use
    // it immediately so prayer times compute instantly on cold start without
    // blocking on a GPS fix (which can take 1-5s and caused the loading spinner
    // on every app open). A fresh device position is fetched separately and in
    // the background via [refreshLocation]; it only triggers a silent recompute
    // when the location materially changed.
    final savedCoordinates = await _loadLastSavedLocation();
    if (savedCoordinates != null) {
      debugPrint('Using last saved location (instant cold-start path)');
      _coordinates = savedCoordinates;
      return _coordinates!;
    }

    // First-ever run (no saved location yet): acquire a position now. This is
    // the ONLY path that may briefly block the UI.
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint(
          'Location services disabled and no saved location. Using Mecca default.',
        );
        _coordinates = Coordinates(21.422487, 39.826206);
        return _coordinates!;
      }

      // Request permission if needed
      await requestLocationPermission();

      // Get the current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      _coordinates = Coordinates(position.latitude, position.longitude);

      // Save the new location for future use
      await _saveLastLocation(_coordinates!);

      return _coordinates!;
    } catch (e) {
      debugPrint('Error getting coordinates: $e');

      // No saved location was available (checked above), so fall back to Mecca.
      debugPrint('Using Mecca coordinates as fallback');
      _coordinates = Coordinates(21.422487, 39.826206);
      return _coordinates!;
    }
  }

  @override
  Future<bool> refreshLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      final previous = _coordinates;
      final fresh = Coordinates(position.latitude, position.longitude);
      _coordinates = fresh;
      await _saveLastLocation(fresh);

      // No previous reference (e.g. first acquisition) — treat as changed.
      if (previous == null) return true;

      final movedMeters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        fresh.latitude,
        fresh.longitude,
      );
      final changed = movedMeters > 500;
      debugPrint(
        'refreshLocation: moved ${movedMeters.toStringAsFixed(0)}m, changed=$changed',
      );
      return changed;
    } catch (e) {
      // Non-fatal: keep the existing location and skip the silent recompute.
      debugPrint('refreshLocation error (non-fatal): $e');
      return false;
    }
  }

  /// Save the last known location to SharedPreferences
  Future<void> _saveLastLocation(Coordinates coordinates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_lastLatitudeKey, coordinates.latitude);
      await prefs.setDouble(_lastLongitudeKey, coordinates.longitude);

      // Try to get and save the location name (city)
      // Skip geocoding on desktop platforms where it's not supported
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final placemarks = await placemarkFromCoordinates(
            coordinates.latitude,
            coordinates.longitude,
          );

          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            String? cityName;

            // Try different fields in order of preference
            if (placemark.locality?.isNotEmpty ?? false) {
              cityName = placemark.locality;
            } else if (placemark.subAdministrativeArea?.isNotEmpty ?? false) {
              cityName = placemark.subAdministrativeArea;
            } else if (placemark.administrativeArea?.isNotEmpty ?? false) {
              cityName = placemark.administrativeArea;
            }

            if (cityName != null && cityName.isNotEmpty) {
              await prefs.setString(_lastLocationNameKey, cityName);
              debugPrint('Saved location name: $cityName');
            } else {
              debugPrint('No valid location name found in placemark data');
              await prefs.remove(_lastLocationNameKey);
            }

            // First-run only: set a country-appropriate calculation method
            // so users don't get stuck on Muslim World League defaults that
            // are wrong for their region (e.g. Egypt should default to the
            // Egyptian General Authority method).
            await _autoDetectCalculationMethod(prefs, placemark.isoCountryCode);
          }
        } catch (e) {
          debugPrint('Error getting location name: $e');
          await prefs.remove(_lastLocationNameKey);
        }
      } else {
        debugPrint('Geocoding not supported on this platform (desktop/web)');
        await prefs.remove(_lastLocationNameKey);
      }

      debugPrint(
        'Saved location: ${coordinates.latitude}, ${coordinates.longitude}',
      );
    } catch (e) {
      debugPrint('Error saving location: $e');
    }
  }

  /// Set a country-appropriate calculation method the first time we resolve
  /// the user's country. Subsequent location changes do not overwrite the
  /// stored method — once the user has a method (auto-detected or manually
  /// chosen), respect it.
  Future<void> _autoDetectCalculationMethod(
    SharedPreferences prefs,
    String? isoCountryCode,
  ) async {
    if (isoCountryCode == null || isoCountryCode.isEmpty) return;
    if (prefs.getBool(_calcMethodAutoDetectedKey) == true) return;
    // If the user explicitly picked a method before we ever saw a country,
    // honour their choice and just mark autodetect as done.
    final hasExplicitMethod = prefs.containsKey(_calculationMethodKey);
    if (hasExplicitMethod) {
      await prefs.setBool(_calcMethodAutoDetectedKey, true);
      return;
    }
    final method = CalculationMethodMapper.defaultMethodForCountry(
      isoCountryCode,
    );
    await prefs.setString(_calculationMethodKey, method);
    await prefs.setBool(_calcMethodAutoDetectedKey, true);
    debugPrint(
      'Auto-detected calculation method "$method" for country $isoCountryCode',
    );
  }

  /// Load the last saved location from SharedPreferences
  Future<Coordinates?> _loadLastSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latitude = prefs.getDouble(_lastLatitudeKey);
      final longitude = prefs.getDouble(_lastLongitudeKey);

      if (latitude != null && longitude != null) {
        debugPrint('Loaded saved location: $latitude, $longitude');
        return Coordinates(latitude, longitude);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading saved location: $e');
      return null;
    }
  }

  @override
  Future<String> getCurrentLocationName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coordinates = _coordinates ?? await _loadLastSavedLocation();

      if (coordinates != null) {
        // Try to get saved location name first
        final savedLocationName = prefs.getString(_lastLocationNameKey);

        // Skip geocoding on desktop platforms where it's not supported
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          try {
            // Try to get fresh location name from geocoding
            final placemarks = await placemarkFromCoordinates(
              coordinates.latitude,
              coordinates.longitude,
            );

            if (placemarks.isNotEmpty) {
              final placemark = placemarks.first;
              String? cityName;

              // Try different fields in order of preference
              if (placemark.locality?.isNotEmpty ?? false) {
                cityName = placemark.locality;
              } else if (placemark.subAdministrativeArea?.isNotEmpty ?? false) {
                cityName = placemark.subAdministrativeArea;
              } else if (placemark.administrativeArea?.isNotEmpty ?? false) {
                cityName = placemark.administrativeArea;
              }

              if (cityName != null && cityName.isNotEmpty) {
                // Save the resolved name
                await prefs.setString(_lastLocationNameKey, cityName);
                return cityName;
              }
            }
          } catch (e) {
            debugPrint('Error getting location name from geocoding: $e');
            // On error, try to fall back to saved name
            if (savedLocationName != null && savedLocationName.isNotEmpty) {
              return savedLocationName;
            }
          }
        } else {
          // Desktop/Web platform - use saved name if available
          if (savedLocationName != null && savedLocationName.isNotEmpty) {
            return savedLocationName;
          }
        }

        // If geocoding fails/unavailable and no saved name, return formatted coordinates
        return '${coordinates.latitude.toStringAsFixed(2)}°, ${coordinates.longitude.toStringAsFixed(2)}°';
      }

      return 'موقع غير محدد';
    } catch (e) {
      debugPrint('Error in getCurrentLocationName: $e');
      return 'موقع غير محدد';
    }
  }

  @override
  Future<void> forceLocationUpdate() async {
    try {
      // Clear cached coordinates to force refresh
      _coordinates = null;

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please enable location services in your device settings.',
        );
      }

      // Request permission if needed
      await requestLocationPermission();

      // Get the current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      _coordinates = Coordinates(position.latitude, position.longitude);

      // Save the new location
      await _saveLastLocation(_coordinates!);

      debugPrint(
        'Location updated successfully: ${_coordinates!.latitude}, ${_coordinates!.longitude}',
      );
    } catch (e) {
      debugPrint('Error forcing location update: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service status: $e');
      return false;
    }
  }

  @override
  Future<bool> isUsingFallbackLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        // Check if we have saved location
        final savedCoordinates = await _loadLastSavedLocation();
        // We're using fallback if services are disabled and no saved location
        return savedCoordinates == null;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking fallback location status: $e');
      return false;
    }
  }

  @override
  Future<bool> isFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLocation =
          prefs.containsKey(_lastLatitudeKey) &&
          prefs.containsKey(_lastLongitudeKey);
      return !hasLocation;
    } catch (e) {
      debugPrint('Error checking first time user: $e');
      return false;
    }
  }
}
