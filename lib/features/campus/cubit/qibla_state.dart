import 'package:equatable/equatable.dart';
import 'package:wadhakir/core/astronomy/celestial_position.dart';
import 'package:wadhakir/core/geo/heading_math.dart';
import 'package:wadhakir/core/geo/qibla_geodesy.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/data/models/qibla_model.dart';
import 'package:wadhakir/features/campus/ar/ar_steady_gate.dart';

// The types a qibla widget reads off the state, so one import of the cubit
// is enough.
export 'package:wadhakir/core/astronomy/celestial_position.dart'
    show HorizontalPosition;
export 'package:wadhakir/core/geo/heading_math.dart' show CompassAccuracyLevel;
export 'package:wadhakir/data/models/qibla_model.dart'
    show QiblaFix, QiblaFixSource, QiblaFailure;
export 'package:wadhakir/features/campus/ar/ar_steady_gate.dart'
    show ArSteadyHint;

/// The five ways of finding the qibla, in selector order.
enum QiblaTab { compass, map, ar, shadow, celestial }

enum QiblaLocationStatus {
  /// Before `start()`.
  unknown,

  /// Not granted yet and the OS will still ask: show «سماح / ليس الآن».
  needsPrompt,

  /// Granted, nothing to show yet, a reading is on its way. Never emitted
  /// while a fix exists, so a resume or a refresh cannot flash a loader over
  /// a working compass.
  locating,

  /// A fix is on screen (see [QiblaState.fix] for how good it is).
  ready,

  /// Not granted and no fix. [QiblaState.locationPermanentlyDenied] says
  /// whether only the settings page can fix it.
  locked,

  /// The phone's location service is off and there is no fix.
  serviceOff,

  /// Granted, but no reading came and nothing provisional exists; see
  /// [QiblaState.failure].
  failed,
}

enum QiblaHeadingStatus {
  /// The compass has never been listened to (not on a compass tab yet).
  idle,

  /// Listening, no reading yet.
  waiting,

  /// Readings are arriving; [QiblaState.heading] is current.
  live,

  /// No compass: desktop, a phone without a magnetometer, or a compass stream
  /// that failed before its first reading.
  unavailable,
}

/// The AR tab's three steps.
enum QiblaArPhase {
  /// «وجّه الكاميرا نحو الأرض وثبّت الهاتف» with a progress bar.
  steadying,

  /// The rug outline and a turn arrow.
  guiding,

  /// The rug filled, the result panel up.
  aligned,
}

/// Which body the Sun/Moon tab aims with.
enum CelestialBody { sun, moon }

/// What the Shadow tab can do right now.
enum QiblaShadowStatus {
  /// No fix yet, so no sun position.
  unavailable,

  /// The sun is between [QiblaState.shadowMinAltitude] and
  /// [QiblaState.shadowMaxAltitude]: a stick casts a usable shadow.
  usable,

  /// Night, or the sun so low that shadows are long and diffuse:
  /// «تعمل نهارًا فقط».
  sunTooLow,

  /// The sun is near the zenith and the shadow too short to read:
  /// «الظل قصير جدًا».
  sunTooHigh,
}

/// What this platform can do, decided once. Injectable so tests can be a
/// phone or a desktop on any host.
class QiblaCapabilities {
  /// A compass plugin exists here (Android/iOS).
  final bool compass;

  /// A camera for the AR tab.
  final bool camera;

  /// An accelerometer stream for the AR tab.
  final bool tilt;

  /// iOS behaviour: flutter_compass sends NO headings at all while the compass
  /// is uncalibrated, so silence after subscribing means "calibrate", not
  /// "missing".
  final bool silentWhenUncalibrated;

  const QiblaCapabilities({
    required this.compass,
    required this.camera,
    required this.tilt,
    this.silentWhenUncalibrated = false,
  });

  /// An Android phone.
  static const QiblaCapabilities android = QiblaCapabilities(
    compass: true,
    camera: true,
    tilt: true,
  );

  /// Windows, macOS or Linux.
  static const QiblaCapabilities desktop = QiblaCapabilities(
    compass: false,
    camera: false,
    tilt: false,
  );

  factory QiblaCapabilities.current() {
    final mobile = PlatformUtils.isMobile;
    return QiblaCapabilities(
      compass: mobile,
      camera: mobile,
      tilt: mobile,
      silentWhenUncalibrated: PlatformUtils.isIOS,
    );
  }

  /// The tab the screen opens on. Never a saved one: a Shadow tab reopened at
  /// night is useless, and AR must never reopen straight into the camera.
  QiblaTab get defaultTab => compass ? QiblaTab.compass : QiblaTab.map;

  /// The tabs to offer.
  ///
  /// Desktop gets Map, Shadow and Sun/Moon. A phone without a magnetometer
  /// keeps the Compass tab (it explains itself and points to Map and Sun) but
  /// loses AR, which is nothing without a heading.
  List<QiblaTab> tabsFor({required bool hasMagnetometer}) {
    if (!compass) {
      return const [QiblaTab.map, QiblaTab.shadow, QiblaTab.celestial];
    }
    return [
      QiblaTab.compass,
      QiblaTab.map,
      if (hasMagnetometer && camera) QiblaTab.ar,
      QiblaTab.shadow,
      QiblaTab.celestial,
    ];
  }
}

const Object _unset = Object();

/// Everything the qibla screen shows. Immutable; see [QiblaCubit] for how it
/// changes.
class QiblaState extends Equatable {
  /// The Shadow tab works with the sun between these altitudes. Below 5°
  /// refraction and diffuse light make the shadow unreliable; above 80° it is
  /// too short to have a direction.
  static const double shadowMinAltitude = 5;
  static const double shadowMaxAltitude = 80;

  /// Below this illuminated fraction the crescent may not be visible:
  /// «الهلال رفيع وقد لا يُرى الآن».
  static const double thinCrescentIllumination = 0.03;

  /// Within this distance of the Kaaba the bearing is meaningless:
  /// «أنت عند الكعبة المشرفة».
  static const double atKaabaKm = 0.05;

  // --- Tabs -----------------------------------------------------------------
  final List<QiblaTab> availableTabs;
  final QiblaTab tab;

  // --- Location -------------------------------------------------------------
  final QiblaLocationStatus locationStatus;

  /// The position on screen, if any. Its [QiblaFix.source] says how fresh.
  final QiblaFix? fix;

  /// A fresh reading is being taken while [fix] (provisional) is shown.
  final bool refiningFix;

  /// The fresh reading did not come; [fix] is the provisional one:
  /// «آخر موقع معروف».
  final bool lastKnown;

  /// The user declined the prompt and [fix] is the prayer-times feature's
  /// saved location: «موقع تقريبي».
  final bool approximate;

  /// With [QiblaLocationStatus.locked]: the OS will not prompt again, so the
  /// card offers «فتح الإعدادات» rather than «سماح».
  final bool locationPermanentlyDenied;

  /// A short place name, or null for "show formatted coordinates".
  final String? placeName;

  /// Degrees from TRUE north, `[0, 360)`.
  final double? qiblaBearing;
  final double? distanceKm;

  /// Why [QiblaLocationStatus.failed] (or the last refresh) failed.
  final QiblaFailure? failure;

  // --- Compass --------------------------------------------------------------
  final QiblaHeadingStatus headingStatus;

  /// Smoothed heading from TRUE north (declination applied), `[0, 360)`.
  final double? heading;

  /// The declination added to Android's magnetic heading, degrees east.
  final double declination;

  final CompassAccuracyLevel accuracy;

  /// Facing the qibla, with hysteresis (in at ≤4°, out past 7°).
  final bool aligned;

  /// «تخطي المعايرة» was tapped this session.
  final bool calibrationDismissed;

  // --- AR -------------------------------------------------------------------
  /// The camera is running and the AR tab is listening to its sensors.
  final bool arActive;

  /// Camera depression below the horizon, degrees (low-passed).
  final double? pitch;

  /// Roll about the camera axis, degrees, positive clockwise.
  final double? roll;
  final QiblaArPhase arPhase;

  /// The steady step's progress, 0..1.
  final double arProgress;
  final ArSteadyHint arHint;

  // --- Sun and moon -----------------------------------------------------------
  final CelestialBody body;

  /// The user picked [body]; until then it follows the sky (sun when it is
  /// up, else the moon).
  final bool bodyChosenByUser;
  final HorizontalPosition? sun;
  final HorizontalPosition? moon;

  /// Which night of the hijri month it is, for «ليلة {night} من الشهر». The
  /// Islamic day begins at sunset, so after sunset this is tomorrow's date.
  final int? moonNight;

  /// Illuminated fraction of the moon, 0..1.
  final double? moonIllumination;
  final DateTime? celestialUpdatedAt;

  const QiblaState({
    required this.availableTabs,
    required this.tab,
    this.locationStatus = QiblaLocationStatus.unknown,
    this.fix,
    this.refiningFix = false,
    this.lastKnown = false,
    this.approximate = false,
    this.locationPermanentlyDenied = false,
    this.placeName,
    this.qiblaBearing,
    this.distanceKm,
    this.failure,
    this.headingStatus = QiblaHeadingStatus.idle,
    this.heading,
    this.declination = 0,
    this.accuracy = CompassAccuracyLevel.unknown,
    this.aligned = false,
    this.calibrationDismissed = false,
    this.arActive = false,
    this.pitch,
    this.roll,
    this.arPhase = QiblaArPhase.steadying,
    this.arProgress = 0,
    this.arHint = ArSteadyHint.ok,
    this.body = CelestialBody.sun,
    this.bodyChosenByUser = false,
    this.sun,
    this.moon,
    this.moonNight,
    this.moonIllumination,
    this.celestialUpdatedAt,
  });

  factory QiblaState.initial(QiblaCapabilities capabilities) => QiblaState(
    availableTabs: capabilities.tabsFor(hasMagnetometer: true),
    tab: capabilities.defaultTab,
    headingStatus: capabilities.compass
        ? QiblaHeadingStatus.idle
        : QiblaHeadingStatus.unavailable,
  );

  // --- Derived ----------------------------------------------------------------

  bool get hasFix => fix != null;

  /// Within [atKaabaKm] of the Kaaba.
  bool get atKaaba => distanceKm != null && distanceKm! < atKaabaKm;

  /// How far to turn to face the qibla, `(-180, 180]`, positive = turn RIGHT
  /// (clockwise). Also the AR rug's yaw.
  double? get qiblaOffset => (qiblaBearing == null || heading == null)
      ? null
      : QiblaGeodesy.signedDelta(qiblaBearing!, heading!);

  /// Show the calibration card: the magnetometer itself says it is poorly
  /// calibrated, and the user has not skipped it. Never on an unknown
  /// accuracy.
  bool get showCalibration =>
      accuracy.needsCalibration &&
      !calibrationDismissed &&
      headingStatus != QiblaHeadingStatus.unavailable;

  /// Where a vertical stick's shadow points, from true north.
  double? get shadowAzimuth =>
      sun == null ? null : CelestialPosition.shadowAzimuth(sun!);

  QiblaShadowStatus get shadowStatus {
    final s = sun;
    if (s == null) return QiblaShadowStatus.unavailable;
    if (s.altitude < shadowMinAltitude) return QiblaShadowStatus.sunTooLow;
    if (s.altitude > shadowMaxAltitude) return QiblaShadowStatus.sunTooHigh;
    return QiblaShadowStatus.usable;
  }

  /// The qibla relative to the shadow, `(-180, 180]`, positive clockwise.
  double? get qiblaFromShadow => (qiblaBearing == null || shadowAzimuth == null)
      ? null
      : QiblaGeodesy.signedDelta(qiblaBearing!, shadowAzimuth!);

  /// The body the Sun/Moon tab is using.
  HorizontalPosition? get selectedBodyPosition =>
      body == CelestialBody.sun ? sun : moon;

  /// The qibla relative to the selected body, `(-180, 180]`, positive
  /// clockwise.
  double? get qiblaFromBody {
    final b = selectedBodyPosition;
    if (qiblaBearing == null || b == null) return null;
    return QiblaGeodesy.signedDelta(qiblaBearing!, b.azimuth);
  }

  /// A crescent too thin to see.
  bool get moonFaint =>
      moonIllumination != null && moonIllumination! < thinCrescentIllumination;

  QiblaState copyWith({
    List<QiblaTab>? availableTabs,
    QiblaTab? tab,
    QiblaLocationStatus? locationStatus,
    Object? fix = _unset,
    bool? refiningFix,
    bool? lastKnown,
    bool? approximate,
    bool? locationPermanentlyDenied,
    Object? placeName = _unset,
    Object? qiblaBearing = _unset,
    Object? distanceKm = _unset,
    Object? failure = _unset,
    QiblaHeadingStatus? headingStatus,
    Object? heading = _unset,
    double? declination,
    CompassAccuracyLevel? accuracy,
    bool? aligned,
    bool? calibrationDismissed,
    bool? arActive,
    Object? pitch = _unset,
    Object? roll = _unset,
    QiblaArPhase? arPhase,
    double? arProgress,
    ArSteadyHint? arHint,
    CelestialBody? body,
    bool? bodyChosenByUser,
    Object? sun = _unset,
    Object? moon = _unset,
    Object? moonNight = _unset,
    Object? moonIllumination = _unset,
    Object? celestialUpdatedAt = _unset,
  }) {
    return QiblaState(
      availableTabs: availableTabs ?? this.availableTabs,
      tab: tab ?? this.tab,
      locationStatus: locationStatus ?? this.locationStatus,
      fix: identical(fix, _unset) ? this.fix : fix as QiblaFix?,
      refiningFix: refiningFix ?? this.refiningFix,
      lastKnown: lastKnown ?? this.lastKnown,
      approximate: approximate ?? this.approximate,
      locationPermanentlyDenied:
          locationPermanentlyDenied ?? this.locationPermanentlyDenied,
      placeName: identical(placeName, _unset)
          ? this.placeName
          : placeName as String?,
      qiblaBearing: identical(qiblaBearing, _unset)
          ? this.qiblaBearing
          : qiblaBearing as double?,
      distanceKm: identical(distanceKm, _unset)
          ? this.distanceKm
          : distanceKm as double?,
      failure: identical(failure, _unset)
          ? this.failure
          : failure as QiblaFailure?,
      headingStatus: headingStatus ?? this.headingStatus,
      heading: identical(heading, _unset) ? this.heading : heading as double?,
      declination: declination ?? this.declination,
      accuracy: accuracy ?? this.accuracy,
      aligned: aligned ?? this.aligned,
      calibrationDismissed: calibrationDismissed ?? this.calibrationDismissed,
      arActive: arActive ?? this.arActive,
      pitch: identical(pitch, _unset) ? this.pitch : pitch as double?,
      roll: identical(roll, _unset) ? this.roll : roll as double?,
      arPhase: arPhase ?? this.arPhase,
      arProgress: arProgress ?? this.arProgress,
      arHint: arHint ?? this.arHint,
      body: body ?? this.body,
      bodyChosenByUser: bodyChosenByUser ?? this.bodyChosenByUser,
      sun: identical(sun, _unset) ? this.sun : sun as HorizontalPosition?,
      moon: identical(moon, _unset) ? this.moon : moon as HorizontalPosition?,
      moonNight: identical(moonNight, _unset)
          ? this.moonNight
          : moonNight as int?,
      moonIllumination: identical(moonIllumination, _unset)
          ? this.moonIllumination
          : moonIllumination as double?,
      celestialUpdatedAt: identical(celestialUpdatedAt, _unset)
          ? this.celestialUpdatedAt
          : celestialUpdatedAt as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
    availableTabs,
    tab,
    locationStatus,
    fix,
    refiningFix,
    lastKnown,
    approximate,
    locationPermanentlyDenied,
    placeName,
    qiblaBearing,
    distanceKm,
    failure,
    headingStatus,
    heading,
    declination,
    accuracy,
    aligned,
    calibrationDismissed,
    arActive,
    pitch,
    roll,
    arPhase,
    arProgress,
    arHint,
    body,
    bodyChosenByUser,
    sun,
    moon,
    moonNight,
    moonIllumination,
    celestialUpdatedAt,
  ];
}
