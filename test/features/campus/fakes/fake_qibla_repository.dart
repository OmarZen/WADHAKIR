import 'dart:async';

import 'package:wadhakir/core/geo/heading_math.dart';
import 'package:wadhakir/data/models/qibla_model.dart';
import 'package:wadhakir/domain/repositories/qibla_repository.dart';

/// Cairo, as the prayer-times feature would have saved it.
const QiblaFix cairoCached = QiblaFix(
  latitude: 30.0444,
  longitude: 31.2357,
  source: QiblaFixSource.cached,
);

/// Cairo, a fresh reading.
const QiblaFix cairoGps = QiblaFix(
  latitude: 30.0444,
  longitude: 31.2357,
  accuracyM: 25,
  source: QiblaFixSource.gps,
);

/// A scriptable [QiblaRepository] that counts every call.
///
/// Sensor streams are broadcast controllers, so a test can both push readings
/// and ask whether the cubit is listening right now ([headingListening] etc.).
/// Location calls answer from plain fields, or wait on a completer when the
/// test needs to hold a request open (an OS dialog on screen).
class FakeQiblaRepository implements QiblaRepository {
  /// What [checkLocationAccess] answers.
  LocationAccess access;

  /// What [requestLocationAccess] answers (and then also [access]).
  LocationAccess accessAfterPrompt;

  /// When set, [requestLocationAccess] waits for it instead.
  Completer<LocationAccess>? pendingPrompt;

  QiblaFix? provisional;
  QiblaFix? cached;

  /// What [currentFix] returns; [currentFixError] wins when set.
  QiblaFix fresh;
  Object? currentFixError;

  /// When set, [currentFix] waits for it instead.
  Completer<QiblaFix>? pendingFix;

  String? name;
  bool magnetometer;
  double declinationDegrees;

  int checkCalls = 0;
  int requestCalls = 0;
  int provisionalCalls = 0;
  int currentFixCalls = 0;
  int placeNameCalls = 0;
  int openAppSettingsCalls = 0;
  int openLocationSettingsCalls = 0;
  int hasMagnetometerCalls = 0;
  int headingListens = 0;
  int tiltListens = 0;
  Duration? lastTimeLimit;

  final StreamController<HeadingSample> heading =
      StreamController<HeadingSample>.broadcast();
  final StreamController<CompassAccuracyLevel> accuracy =
      StreamController<CompassAccuracyLevel>.broadcast();
  final StreamController<TiltSample> tilt =
      StreamController<TiltSample>.broadcast();

  FakeQiblaRepository({
    this.access = LocationAccess.granted,
    this.accessAfterPrompt = LocationAccess.granted,
    this.provisional,
    this.cached,
    this.fresh = cairoGps,
    this.name,
    this.magnetometer = true,
    this.declinationDegrees = 0,
  }) {
    heading.onListen = () => headingListens++;
    tilt.onListen = () => tiltListens++;
  }

  bool get headingListening => heading.hasListener;
  bool get accuracyListening => accuracy.hasListener;
  bool get tiltListening => tilt.hasListener;

  @override
  Future<LocationAccess> checkLocationAccess() async {
    checkCalls++;
    return access;
  }

  @override
  Future<LocationAccess> requestLocationAccess() async {
    requestCalls++;
    final result = pendingPrompt == null
        ? accessAfterPrompt
        : await pendingPrompt!.future;
    access = result;
    return result;
  }

  @override
  Future<QiblaFix?> provisionalFix() async {
    provisionalCalls++;
    return provisional ?? cached;
  }

  @override
  Future<QiblaFix?> cachedPrayerFix() async => cached;

  @override
  Future<QiblaFix> currentFix({
    Duration timeLimit = const Duration(seconds: 12),
  }) async {
    currentFixCalls++;
    lastTimeLimit = timeLimit;
    if (pendingFix != null) return pendingFix!.future;
    final error = currentFixError;
    if (error != null) throw error;
    return fresh;
  }

  @override
  Future<String?> placeName(QiblaFix fix) async {
    placeNameCalls++;
    return name;
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalls++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalls++;
    return true;
  }

  @override
  Future<bool> hasMagnetometer() async {
    hasMagnetometerCalls++;
    return magnetometer;
  }

  /// Which kind of heading each subscription asked for, in order.
  final List<bool> headingCameraRequests = [];

  @override
  Stream<HeadingSample> headingStream({bool camera = false}) {
    headingCameraRequests.add(camera);
    return heading.stream;
  }

  @override
  Stream<CompassAccuracyLevel> magnetometerAccuracy() => accuracy.stream;

  @override
  Future<double> declination(QiblaFix fix) async => declinationDegrees;

  @override
  Stream<TiltSample> tiltStream() => tilt.stream;

  Future<void> dispose() async {
    await heading.close();
    await accuracy.close();
    await tilt.close();
  }
}
