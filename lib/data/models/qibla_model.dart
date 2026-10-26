import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:wadhakir/core/geo/qibla_geodesy.dart';

/// Where a [QiblaFix] came from, which decides how the screen labels it.
enum QiblaFixSource {
  /// A fresh `getCurrentPosition` reading.
  gps,

  /// The OS's last known position: instant, possibly old.
  lastKnown,

  /// The prayer-times feature's saved coordinates (`prayer_times_last_*`),
  /// read only. Used before a fresh fix arrives, and as the approximate
  /// position when the user says «ليس الآن» to the location prompt.
  cached,
}

/// A position the qibla is computed from.
class QiblaFix extends Equatable {
  final double latitude;
  final double longitude;

  /// Horizontal accuracy radius, metres, when the platform gave one.
  final double? accuracyM;

  /// Metres above the WGS-84 ellipsoid, when known. Only the declination model
  /// reads it, and it barely cares.
  final double? altitudeM;

  final QiblaFixSource source;

  /// When the reading was taken, when known.
  final DateTime? timestamp;

  const QiblaFix({
    required this.latitude,
    required this.longitude,
    required this.source,
    this.accuracyM,
    this.altitudeM,
    this.timestamp,
  });

  GeoPoint get point => GeoPoint(latitude, longitude);

  /// Shown before (or instead of) a fresh reading.
  bool get isProvisional => source != QiblaFixSource.gps;

  QiblaFix withSource(QiblaFixSource source) => QiblaFix(
    latitude: latitude,
    longitude: longitude,
    source: source,
    accuracyM: accuracyM,
    altitudeM: altitudeM,
    timestamp: timestamp,
  );

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    accuracyM,
    altitudeM,
    source,
    timestamp,
  ];
}

/// The location permission and service, as one answer.
enum LocationAccess {
  granted,

  /// Not granted, and the OS will still show its prompt.
  denied,

  /// Not granted, and the OS will not prompt again: only the app's settings
  /// page can change it.
  deniedForever,

  /// Location services are switched off for the whole phone.
  serviceOff,
}

/// Thrown by `QiblaRepository.currentFix` when the reading cannot be taken
/// for a permission or service reason, so the cubit never has to know
/// geolocator's exception types.
class LocationAccessException implements Exception {
  final LocationAccess access;

  const LocationAccessException(this.access);

  @override
  String toString() => 'LocationAccessException($access)';
}

/// Why the location could not be found. Typed so the UI picks its copy from an
/// enum, never by matching message text (the old screen matched English
/// exception strings and showed them to users).
///
/// Compass problems are not failures in this sense: they live on the state's
/// heading status (`unavailable`), so a location retry can never wipe them
/// and a compass problem can never hide a location one.
enum QiblaFailure {
  /// No fix within the time limit and nothing provisional to fall back on.
  timeout,

  /// The location could not be read for any other reason.
  locationError,
}

/// One raw reading from flutter_compass.
class HeadingSample extends Equatable {
  /// Degrees from MAGNETIC north on Android (−180..180, not yet normalised),
  /// true north on iOS. Null when the platform had no reading.
  final double? heading;

  /// A ± error estimate in degrees, only when the platform's estimate is
  /// meaningful (iOS). Null on Android, where the accuracy comes from the
  /// magnetometer stream instead; see `CompassAccuracyLevel.fromDegrees`.
  final double? accuracyDegrees;

  const HeadingSample({this.heading, this.accuracyDegrees});

  @override
  List<Object?> get props => [heading, accuracyDegrees];
}

/// One accelerometer reading (gravity included), m/s², in the device frame:
/// x to the right of the screen, y to its top, z out of the screen.
///
/// sensors_plus reports iOS in the same convention as Android (it flips the
/// CoreMotion signs), so one formula serves both.
class TiltSample extends Equatable {
  final double x;
  final double y;
  final double z;

  const TiltSample(this.x, this.y, this.z);

  /// How far below the horizon the rear camera points, degrees: 0 with the
  /// phone upright, 90 lying flat face up.
  ///
  /// `atan2(z, hypot(x, y))` rather than `atan2(z, y)`, so a phone held with
  /// some roll still reads its true camera depression.
  double get pitchDegrees =>
      math.atan2(z, math.sqrt(x * x + y * y)) * 180 / math.pi;

  /// Rotation about the camera axis, degrees, positive when the phone is
  /// turned clockwise as its user sees it.
  double get rollDegrees => math.atan2(-x, y) * 180 / math.pi;

  /// One step of a vector low-pass toward [next] with weight [alpha].
  TiltSample lowPass(TiltSample next, double alpha) => TiltSample(
    x + (next.x - x) * alpha,
    y + (next.y - y) * alpha,
    z + (next.z - z) * alpha,
  );

  @override
  List<Object?> get props => [x, y, z];
}
