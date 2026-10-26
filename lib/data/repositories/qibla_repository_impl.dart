import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/geo/heading_math.dart';
import 'package:wadhakir/core/geo/qibla_geodesy.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/data/models/qibla_model.dart';
import 'package:wadhakir/domain/repositories/qibla_repository.dart';
import 'package:wadhakir/features/campus/services/qibla_platform_bridge.dart';

/// The platform-backed [QiblaRepository].
///
/// See the interface for the rules (inert constructor, one prompting method,
/// read-only `prayer_times_*`). Platform split:
/// * **Android**: flutter_compass heading (magnetic) + declination and
///   magnetometer accuracy from [QiblaPlatformBridge].
/// * **iOS**: flutter_compass heading (already true north) with its own,
///   meaningful accuracy; no bridge.
/// * **Desktop**: location and geometry only. No compass, no tilt; the
///   screen offers Map, Shadow and Sun/Moon there.
class QiblaRepositoryImpl implements QiblaRepository {
  /// The prayer-times feature's keys. Read here, written only by
  /// `PrayerTimesRepositoryImpl`.
  static const String lastLatitudeKey = 'prayer_times_last_latitude';
  static const String lastLongitudeKey = 'prayer_times_last_longitude';
  static const String lastLocationNameKey = 'prayer_times_last_location_name';

  /// How close the saved prayer-times location must be for its city name to
  /// label this fix. Wider than a city, narrower than a region: a saved
  /// "Cairo" is fine for Giza, wrong for Alexandria.
  static const double cachedNameRadiusKm = 30;

  static const Duration geocodeTimeLimit = Duration(seconds: 5);

  /// The Android native half (declination, magnetometer). Injectable for
  /// tests; unused off Android.
  final QiblaPlatformBridge bridge;
  final Future<SharedPreferences> Function() _prefs;

  /// Created on first use: constructing one spins up a platform instance, and
  /// the constructor promises to do nothing.
  Geocoding? _geocoding;

  QiblaRepositoryImpl({
    this.bridge = const MethodChannelQiblaBridge(),
    Future<SharedPreferences> Function()? prefs,
  }) : _prefs = prefs ?? SharedPreferences.getInstance;

  // --- Location --------------------------------------------------------------

  @override
  Future<LocationAccess> checkLocationAccess() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.serviceOff;
      }
      return _mapPermission(await Geolocator.checkPermission());
    } catch (e) {
      debugPrint('Qibla checkLocationAccess failed: $e');
      return LocationAccess.denied;
    }
  }

  @override
  Future<LocationAccess> requestLocationAccess() async {
    try {
      // No prompt with the service off: granting would still give no fix,
      // and the user would be asked again once they switch it on.
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.serviceOff;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }
      return _mapPermission(permission);
    } catch (e) {
      debugPrint('Qibla requestLocationAccess failed: $e');
      return LocationAccess.denied;
    }
  }

  static LocationAccess _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAccess.granted;
      case LocationPermission.deniedForever:
        return LocationAccess.deniedForever;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationAccess.denied;
    }
  }

  @override
  Future<QiblaFix?> provisionalFix() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return _fromPosition(last, QiblaFixSource.lastKnown);
    } catch (e) {
      // Unsupported on some platforms; the cached prayer location covers it.
      debugPrint('Qibla getLastKnownPosition failed: $e');
    }
    return cachedPrayerFix();
  }

  @override
  Future<QiblaFix?> cachedPrayerFix() async {
    try {
      final prefs = await _prefs();
      final lat = prefs.getDouble(lastLatitudeKey);
      final lng = prefs.getDouble(lastLongitudeKey);
      if (!_validCoordinates(lat, lng)) return null;
      return QiblaFix(
        latitude: lat!,
        longitude: lng!,
        source: QiblaFixSource.cached,
      );
    } catch (e) {
      debugPrint('Qibla cachedPrayerFix failed: $e');
      return null;
    }
  }

  @override
  Future<QiblaFix> currentFix({
    Duration timeLimit = const Duration(seconds: 12),
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        // Medium is a few hundred metres at worst, which moves the qibla
        // bearing by nothing a compass can show, and it arrives without
        // waiting for a GPS lock indoors.
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: timeLimit,
        ),
        // Belt and braces: not every platform implementation honours
        // timeLimit, and an unbounded wait is the one thing this flow
        // cannot have.
      ).timeout(timeLimit + const Duration(seconds: 3));
      return _fromPosition(position, QiblaFixSource.gps);
    } on LocationServiceDisabledException {
      throw const LocationAccessException(LocationAccess.serviceOff);
    } on PermissionDeniedException {
      throw const LocationAccessException(LocationAccess.denied);
    }
  }

  QiblaFix _fromPosition(Position p, QiblaFixSource source) => QiblaFix(
    latitude: p.latitude,
    longitude: p.longitude,
    accuracyM: p.accuracy > 0 ? p.accuracy : null,
    // 0 is how most platforms say "no altitude".
    altitudeM: p.altitude != 0 ? p.altitude : null,
    timestamp: p.timestamp,
    source: source,
  );

  @override
  Future<String?> placeName(QiblaFix fix) async {
    try {
      final prefs = await _prefs();
      final cached = cachedNameNear(
        fix: fix,
        cachedLatitude: prefs.getDouble(lastLatitudeKey),
        cachedLongitude: prefs.getDouble(lastLongitudeKey),
        cachedName: prefs.getString(lastLocationNameKey),
      );
      if (cached != null) return cached;
    } catch (e) {
      debugPrint('Qibla cached place name failed: $e');
    }

    // Reverse geocoding is Android/iOS only in the geocoding plugin.
    if (!PlatformUtils.isMobile) return null;
    try {
      final placemarks = await (_geocoding ??= Geocoding())
          .placemarkFromCoordinates(fix.latitude, fix.longitude)
          .timeout(geocodeTimeLimit);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      // Same preference order as the prayer-times header, so the two screens
      // name the same place the same way.
      for (final candidate in [
        p.locality,
        p.subAdministrativeArea,
        p.administrativeArea,
      ]) {
        final name = candidate?.trim();
        if (name != null && name.isNotEmpty) return name;
      }
      return null;
    } catch (e) {
      debugPrint('Qibla reverse geocoding failed: $e');
      return null;
    }
  }

  /// The saved prayer-times city name, when the saved coordinates are within
  /// [cachedNameRadiusKm] of [fix]; else null. Pure, for tests.
  @visibleForTesting
  static String? cachedNameNear({
    required QiblaFix fix,
    required double? cachedLatitude,
    required double? cachedLongitude,
    required String? cachedName,
  }) {
    final name = cachedName?.trim();
    if (name == null || name.isEmpty) return null;
    if (!_validCoordinates(cachedLatitude, cachedLongitude)) return null;
    final km = QiblaGeodesy.distanceKm(
      fix.point,
      GeoPoint(cachedLatitude!, cachedLongitude!),
    );
    return km <= cachedNameRadiusKm ? name : null;
  }

  static bool _validCoordinates(double? lat, double? lng) =>
      lat != null &&
      lng != null &&
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() <= 90 &&
      lng.abs() <= 180;

  @override
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('Qibla openAppSettings failed: $e');
      return false;
    }
  }

  @override
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('Qibla openLocationSettings failed: $e');
      return false;
    }
  }

  // --- Sensors ---------------------------------------------------------------

  @override
  Future<bool> hasMagnetometer() async {
    if (PlatformUtils.isAndroid) return bridge.hasMagnetometer();
    // Every iPhone has one; an iPad without one simply sends no headings,
    // which the cubit treats as "calibrate", not "missing".
    if (PlatformUtils.isIOS) return true;
    return false;
  }

  @override
  Stream<HeadingSample> headingStream({bool camera = false}) {
    if (!PlatformUtils.isMobile) return const Stream.empty();
    if (camera && PlatformUtils.isAndroid) return _cameraHeadingOrCompass();
    return _compassHeading();
  }

  /// The camera's own heading, or the compass's if this phone cannot give
  /// one (no rotation-vector sensor, or the bridge is missing).
  Stream<HeadingSample> _cameraHeadingOrCompass() async* {
    try {
      await for (final degrees in bridge.cameraHeading()) {
        yield HeadingSample(heading: degrees);
      }
    } catch (e) {
      debugPrint('Qibla camera heading unavailable, using the compass: $e');
      yield* _compassHeading();
    }
  }

  Stream<HeadingSample> _compassHeading() {
    final events = FlutterCompass.events;
    if (events == null) return const Stream.empty();
    final trustAccuracy = PlatformUtils.isIOS;
    // headingForCameraMode is deliberately not read: it is always 0 on
    // Android, and magnetic (not true) on iOS, so switching to it at 45°
    // would jump the needle by the local declination.
    return events.map(
      (e) => HeadingSample(
        heading: e.heading,
        accuracyDegrees: trustAccuracy ? e.accuracy : null,
      ),
    );
  }

  @override
  Stream<CompassAccuracyLevel> magnetometerAccuracy() {
    if (!PlatformUtils.isAndroid) return const Stream.empty();
    return bridge.magnetometerAccuracy();
  }

  @override
  Future<double> declination(QiblaFix fix) async {
    // iOS hands flutter_compass CLHeading.trueHeading: already corrected.
    if (!PlatformUtils.isAndroid) return 0;
    return bridge.declination(
      latitude: fix.latitude,
      longitude: fix.longitude,
      altitudeM: fix.altitudeM ?? 0,
    );
  }

  @override
  Stream<TiltSample> tiltStream() {
    // sensors_plus has no desktop implementation.
    if (!PlatformUtils.isMobile) return const Stream.empty();
    return accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).map((e) => TiltSample(e.x, e.y, e.z));
  }
}
