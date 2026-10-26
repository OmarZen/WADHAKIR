import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wadhakir/core/geo/heading_math.dart';

/// The Android-only native half of the qibla: `QiblaBridge.kt`.
///
/// Two things Dart cannot get from any plugin the app has:
/// * the magnetic declination at a place (Android's `GeomagneticField`, the
///   OS-maintained World Magnetic Model), without which every Android
///   heading is off by the local declination — about 5° in Cairo and over 10°
///   in parts of North America;
/// * the MAGNETOMETER's own accuracy, the only honest signal for "please
///   calibrate"; flutter_compass's accuracy mixes in the accelerometer;
/// * where the CAMERA points, for AR. flutter_compass reports the phone's top
///   edge once the phone tilts past 45°, which turns with a sideways tilt
///   while the camera does not.
abstract interface class QiblaPlatformBridge {
  /// Degrees, east positive.
  Future<double> declination({
    required double latitude,
    required double longitude,
    double altitudeM = 0,
  });

  Future<bool> hasMagnetometer();

  Stream<CompassAccuracyLevel> magnetometerAccuracy();

  /// Degrees from MAGNETIC north (0..360) of the back camera's axis. Errors
  /// when the phone has no rotation-vector sensor; callers fall back to the
  /// compass heading.
  Stream<double> cameraHeading();
}

/// The real bridge over the `com.bloom.wadhakir/qibla` channels.
///
/// Every failure here is soft: a missing registration
/// (`MissingPluginException`) or a native error degrades to "no
/// declination", "assume a magnetometer" and "accuracy unknown", and is
/// logged. The compass then works as it did before this bridge existed,
/// which is a better outcome than an error screen.
class MethodChannelQiblaBridge implements QiblaPlatformBridge {
  static const String methodChannelName = 'com.bloom.wadhakir/qibla';
  static const String accuracyChannelName =
      'com.bloom.wadhakir/qibla_mag_accuracy';
  static const String cameraHeadingChannelName =
      'com.bloom.wadhakir/qibla_camera_heading';

  /// Injectable so a test can stand in for the native side.
  final MethodChannel methods;
  final EventChannel accuracy;
  final EventChannel camera;

  const MethodChannelQiblaBridge({
    this.methods = const MethodChannel(methodChannelName),
    this.accuracy = const EventChannel(accuracyChannelName),
    this.camera = const EventChannel(cameraHeadingChannelName),
  });

  @override
  Future<double> declination({
    required double latitude,
    required double longitude,
    double altitudeM = 0,
  }) async {
    try {
      final value = await methods.invokeMethod<num>('declination', {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitudeM,
      });
      final degrees = value?.toDouble();
      if (degrees == null || !degrees.isFinite) return 0;
      return degrees;
    } catch (e) {
      debugPrint('QiblaBridge.declination failed, using 0: $e');
      return 0;
    }
  }

  @override
  Future<bool> hasMagnetometer() async {
    try {
      return await methods.invokeMethod<bool>('hasMagnetometer') ?? true;
    } catch (e) {
      debugPrint('QiblaBridge.hasMagnetometer failed, assuming yes: $e');
      return true;
    }
  }

  /// The native side sends the flutter_compass scale: 15 / 30 / 45 for
  /// high / medium / low, and −1 for "no estimate".
  @override
  Stream<CompassAccuracyLevel> magnetometerAccuracy() => accuracy
      .receiveBroadcastStream()
      .map((event) => CompassAccuracyLevel.fromDegrees(event as num?))
      .handleError((Object e) {
        debugPrint('QiblaBridge accuracy stream failed: $e');
      });

  /// Errors pass through on purpose: the repository falls back to the
  /// compass on one, which a swallowed error would never trigger.
  @override
  Stream<double> cameraHeading() =>
      camera.receiveBroadcastStream().map((event) => (event as num).toDouble());
}
