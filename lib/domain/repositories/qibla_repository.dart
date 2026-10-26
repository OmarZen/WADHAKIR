import 'package:wadhakir/core/geo/heading_math.dart';
import 'package:wadhakir/data/models/qibla_model.dart';

/// Everything the qibla screen needs from the platform: location, the
/// compass, tilt and the magnetic model.
///
/// ## Rules every implementation keeps
/// * **The constructor does nothing.** No permission checks, no sensors. The
///   old repository started location work in its constructor, which is half
///   of how the screen came to show the OS prompt three times.
/// * **Only [requestLocationAccess] may show the OS location prompt.**
///   Everything else answers from what is already granted.
/// * **Nothing writes `prayer_times_*`.** The qibla reads the prayer-times
///   feature's saved location and name; it never changes them.
/// * Streams are cold and single-purpose: the cubit listens only while a tab
///   needs them and cancels on pause.
abstract interface class QiblaRepository {
  /// Permission and service state. Never prompts.
  Future<LocationAccess> checkLocationAccess();

  /// Shows the OS prompt when the OS still allows one, and returns the
  /// result. The ONLY method that may prompt; it does not prompt when the
  /// service is off.
  Future<LocationAccess> requestLocationAccess();

  /// An instant position to draw while a fresh fix is on its way: the OS's
  /// last known position, else [cachedPrayerFix]. Never prompts. Callers only
  /// ask for it once access is granted.
  Future<QiblaFix?> provisionalFix();

  /// The prayer-times feature's saved coordinates, as a [QiblaFixSource.cached]
  /// fix, or null when it has none. Needs no permission.
  Future<QiblaFix?> cachedPrayerFix();

  /// A fresh reading at medium accuracy.
  ///
  /// Throws `TimeoutException` when [timeLimit] passes without one, and
  /// [LocationAccessException] when permission or the service is missing.
  Future<QiblaFix> currentFix({
    Duration timeLimit = const Duration(seconds: 12),
  });

  /// A short place name for the header, or null for "show coordinates".
  ///
  /// The prayer-times feature's saved name when its saved coordinates are
  /// within 30 km of [fix]; otherwise reverse geocoding on mobile with a 5 s
  /// limit; otherwise null.
  Future<String?> placeName(QiblaFix fix);

  /// Opens this app's page in the system settings.
  Future<bool> openAppSettings();

  /// Opens the system location settings.
  Future<bool> openLocationSettings();

  /// False only when the phone positively has no magnetometer, or the
  /// platform has no compass at all (desktop). An error answering the
  /// question counts as true: hiding a working compass is the worse mistake.
  Future<bool> hasMagnetometer();

  /// Raw compass readings; see [HeadingSample] for what is and is not
  /// normalised. Empty where there is no compass.
  ///
  /// With [camera], where the back camera points rather than the phone's top
  /// edge (the AR tab), on Android; the compass heading where that is not
  /// available.
  Stream<HeadingSample> headingStream({bool camera = false});

  /// The magnetometer's own calibration level (Android). Empty elsewhere: iOS
  /// carries its accuracy on [HeadingSample.accuracyDegrees].
  Stream<CompassAccuracyLevel> magnetometerAccuracy();

  /// Magnetic declination at [fix] in degrees, east positive: add it to a
  /// magnetic heading to get a true one. 0 where the platform heading is
  /// already true (iOS) or the model is unavailable.
  Future<double> declination(QiblaFix fix);

  /// Accelerometer readings at game rate for the AR tab. Empty where there is
  /// no accelerometer plugin (desktop).
  Stream<TiltSample> tiltStream();
}
