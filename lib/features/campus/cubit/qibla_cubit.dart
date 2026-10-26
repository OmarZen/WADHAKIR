import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_core/core.dart' show HijriDateTime;
import 'package:wadhakir/core/astronomy/celestial_position.dart';
import 'package:wadhakir/core/geo/heading_math.dart';
import 'package:wadhakir/core/geo/qibla_geodesy.dart';
import 'package:wadhakir/data/models/qibla_model.dart';
import 'package:wadhakir/domain/repositories/qibla_repository.dart';
import 'package:wadhakir/features/campus/ar/ar_steady_gate.dart';
import 'package:wadhakir/features/campus/cubit/qibla_state.dart';
import 'package:wadhakir/features/moon_phases/data/moon_phase.dart';

export 'package:wadhakir/features/campus/cubit/qibla_state.dart';

/// The one brain behind all five qibla tabs.
///
/// ## Location: one prompt, no flashes
/// The old screen asked for location three times over (repository
/// constructor, screen, cubit) and re-ran the whole flow on every resume,
/// flashing a loader over a working compass. Here:
/// * [start] and every resume only CHECK access; [allowLocation] is the only
///   path to the OS prompt, and a request already in flight blocks any other
///   (the prompt itself pauses and resumes the app).
/// * When access is granted a provisional fix (the OS's last known position,
///   else the prayer-times feature's saved one) goes on screen at once, and a
///   fresh reading refines it. If the fresh reading times out the provisional
///   one stays, labelled «آخر موقع معروف».
/// * `locating` is never emitted while a fix exists.
/// * A resume re-checks only from `locked`, `needsPrompt`, `serviceOff` or an
///   approximate fix — the states a trip to Settings can change.
///
/// ## Sensors follow the tab
/// heading on Compass, and on AR once the camera is up ([setArActive]); tilt
/// on AR only; the 15 s sun/moon tick on Shadow and Sun/Moon only.
/// [onAppPaused] drops everything and [onAppResumed] picks the tab's set back
/// up, keeping the last values on screen meanwhile.
///
/// ## Heading pipeline
/// skip null → fold into 0..360 (Android sends −180..180; dropping the
/// negatives would lose the whole western half of the compass) → add the
/// declination (Android is magnetic) → unit-vector smoothing → emit only on a
/// change of at least [minHeadingStep] → alignment hysteresis, with one
/// haptic per entry and a cooldown.
class QiblaCubit extends Cubit<QiblaState> {
  /// How long a fresh reading may take before the provisional fix stands.
  static const Duration locationTimeLimit = Duration(seconds: 12);

  /// How often the sun and moon are recomputed on their tabs. The sun moves a
  /// quarter of a degree a minute; nobody can aim more finely than that.
  static const Duration celestialInterval = Duration(seconds: 15);

  /// iOS sends no headings at all while uncalibrated; after this long with
  /// none, the cubit asks for calibration.
  static const Duration headingSilenceTimeout = Duration(seconds: 3);

  /// Smaller heading changes are not emitted: they cannot be seen on the dial
  /// and would rebuild the screen at sensor rate.
  static const double minHeadingStep = 0.5;

  /// Low-pass weight for each accelerometer sample (game rate, ~50 Hz).
  static const double tiltAlpha = 0.2;

  /// Re-run the place-name lookup only after moving this far.
  static const double placeNameRefreshKm = 1;

  /// Re-ask for the declination only after moving this far; it changes by a
  /// fraction of a degree over hundreds of kilometres.
  static const double declinationRefreshKm = 50;

  final QiblaRepository _repository;
  final QiblaCapabilities _capabilities;
  final DateTime Function() _clock;
  final VoidCallback _onAlignedHaptic;
  final Duration _hapticCooldown;
  final int Function(DateTime) _hijriDayOf;
  final double Function(DateTime) _moonIlluminationOf;

  final HeadingSmoother _smoother = HeadingSmoother();
  final AlignmentTracker _tracker = AlignmentTracker();
  final ArSteadyGate _steadyGate = ArSteadyGate();

  StreamSubscription<HeadingSample>? _headingSub;

  /// Whether [_headingSub] follows the camera (AR) or the compass.
  bool _headingForCamera = false;
  StreamSubscription<CompassAccuracyLevel>? _accuracySub;
  StreamSubscription<TiltSample>? _tiltSub;
  Timer? _celestialTimer;
  Timer? _headingSilenceTimer;

  bool _started = false;
  bool _paused = false;

  /// Unknown (false) until [start] has asked the repository, so nothing
  /// listens to a compass that may not exist.
  bool _hasCompass = false;
  bool _locationInFlight = false;

  /// «ليس الآن» was tapped: a resume that still finds access merely `denied`
  /// shows the locked card, not the prompt again.
  bool _declined = false;

  bool _sawHeadingSinceSubscribe = false;
  double? _lastEmittedHeading;
  DateTime? _lastHapticAt;
  TiltSample? _filteredTilt;
  QiblaFix? _declinationFix;
  QiblaFix? _placeNameFix;
  int _placeNameRequest = 0;

  /// [onAlignedHaptic] defaults to a medium impact; [hijriDayOf] and
  /// [moonIlluminationOf] default to the app's own Hijri calendar
  /// (Syncfusion's) and [MoonPhaseCalculator].
  QiblaCubit({
    required QiblaRepository repository,
    QiblaCapabilities? capabilities,
    DateTime Function()? clock,
    VoidCallback? onAlignedHaptic,
    Duration hapticCooldown = const Duration(milliseconds: 1500),
    int Function(DateTime)? hijriDayOf,
    double Function(DateTime)? moonIlluminationOf,
  }) : this._(
         repository,
         capabilities ?? QiblaCapabilities.current(),
         clock ?? DateTime.now,
         onAlignedHaptic ?? _defaultHaptic,
         hapticCooldown,
         hijriDayOf ?? _defaultHijriDay,
         moonIlluminationOf ?? _defaultMoonIllumination,
       );

  QiblaCubit._(
    this._repository,
    this._capabilities,
    this._clock,
    this._onAlignedHaptic,
    this._hapticCooldown,
    this._hijriDayOf,
    this._moonIlluminationOf,
  ) : super(QiblaState.initial(_capabilities));

  static void _defaultHaptic() => HapticFeedback.mediumImpact();

  static int _defaultHijriDay(DateTime date) =>
      HijriDateTime.fromDateTime(date).day;

  static double _defaultMoonIllumination(DateTime date) =>
      MoonPhaseCalculator.forDate(date).illumination;

  // --- Lifecycle ------------------------------------------------------------

  /// Settles the tabs, starts the active tab's sensors and checks location.
  /// Never prompts. Safe to call more than once.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    var hasMagnetometer = false;
    if (_capabilities.compass) {
      hasMagnetometer = await _repository.hasMagnetometer();
      if (isClosed) return;
    }
    _hasCompass = hasMagnetometer;
    final tabs = _capabilities.tabsFor(hasMagnetometer: hasMagnetometer);
    _emit(
      state.copyWith(
        availableTabs: tabs,
        tab: tabs.contains(state.tab) ? state.tab : _capabilities.defaultTab,
        headingStatus: hasMagnetometer
            ? state.headingStatus
            : QiblaHeadingStatus.unavailable,
      ),
    );
    _syncSubscriptions();
    await _refreshLocation();
  }

  /// The app went to the background (or a system dialog covered it): every
  /// sensor and timer stops. The AR steady step starts over on return, since
  /// the camera restarts too.
  void onAppPaused() {
    _paused = true;
    _resetArTracking();
    if (state.arActive) {
      _emit(
        state.copyWith(
          arPhase: QiblaArPhase.steadying,
          arProgress: 0,
          arHint: ArSteadyHint.ok,
        ),
      );
    }
    _syncSubscriptions();
  }

  /// Back in front: the tab's sensors resume, and location is re-checked if
  /// (and only if) a trip to Settings could have changed something.
  void onAppResumed() {
    _paused = false;
    _syncSubscriptions();
    final status = state.locationStatus;
    final settingsCouldHelp =
        status == QiblaLocationStatus.locked ||
        status == QiblaLocationStatus.needsPrompt ||
        status == QiblaLocationStatus.serviceOff ||
        state.approximate;
    if (_started && settingsCouldHelp && !_locationInFlight) {
      unawaited(_refreshLocation());
    }
  }

  // --- Tabs -----------------------------------------------------------------

  void selectTab(QiblaTab tab) {
    if (tab == state.tab || !state.availableTabs.contains(tab)) return;
    var next = state.copyWith(tab: tab);
    if (tab != QiblaTab.ar && state.arActive) {
      // The AR view is being unmounted and its camera released. It must not
      // touch the cubit from dispose (the safety test pumps it with no cubit
      // at all), so the cubit stands AR down itself.
      _resetArTracking();
      next = next.copyWith(
        arActive: false,
        arPhase: QiblaArPhase.steadying,
        arProgress: 0,
        arHint: ArSteadyHint.ok,
      );
    }
    _emit(next);
    _syncSubscriptions();
  }

  /// Sun or moon for the Sun/Moon tab. Once chosen, it no longer follows the
  /// sky.
  void selectBody(CelestialBody body) {
    _emit(state.copyWith(body: body, bodyChosenByUser: true));
  }

  void dismissCalibration() {
    _emit(state.copyWith(calibrationDismissed: true));
  }

  // --- Location ---------------------------------------------------------------

  /// «سماح»: the ONLY path to the OS location prompt.
  Future<void> allowLocation() async {
    if (_locationInFlight) return;
    _locationInFlight = true;
    _declined = false;
    try {
      final access = await _repository.requestLocationAccess();
      if (isClosed) return;
      await _handleAccess(access);
    } finally {
      _locationInFlight = false;
    }
  }

  /// «ليس الآن»: no prompt. Shows the qibla from the prayer-times feature's
  /// saved location when there is one, else the locked card.
  Future<void> declineLocation() async {
    _declined = true;
    if (state.fix != null) return;
    final cached = await _repository.cachedPrayerFix();
    if (isClosed || state.fix != null) return;
    if (cached != null) {
      _applyFix(cached, approximate: true);
    } else {
      _emit(
        state.copyWith(
          locationStatus: QiblaLocationStatus.locked,
          locationPermanentlyDenied: false,
        ),
      );
    }
  }

  /// «إعادة المحاولة» after a failure. Checks; never prompts.
  Future<void> retryLocation() => _refreshLocation();

  /// «فتح الإعدادات». The re-check happens on the way back, in
  /// [onAppResumed].
  Future<void> openAppSettings() => _repository.openAppSettings();

  /// «إعدادات الموقع». As [openAppSettings].
  Future<void> openLocationSettings() => _repository.openLocationSettings();

  Future<void> _refreshLocation() async {
    if (_locationInFlight) return;
    _locationInFlight = true;
    try {
      final access = await _repository.checkLocationAccess();
      if (isClosed) return;
      await _handleAccess(access);
    } finally {
      _locationInFlight = false;
    }
  }

  Future<void> _handleAccess(LocationAccess access) async {
    if (access == LocationAccess.granted) {
      await _acquireFix();
      return;
    }
    // Whatever is on screen stays: an approximate or earlier fix still gives
    // a correct bearing, and swapping it for a card would be a regression.
    if (state.fix != null) {
      _emit(state.copyWith(locationStatus: QiblaLocationStatus.ready));
      return;
    }
    switch (access) {
      case LocationAccess.serviceOff:
        _emit(state.copyWith(locationStatus: QiblaLocationStatus.serviceOff));
      case LocationAccess.deniedForever:
        _emit(
          state.copyWith(
            locationStatus: QiblaLocationStatus.locked,
            locationPermanentlyDenied: true,
          ),
        );
      case LocationAccess.denied:
        _emit(
          state.copyWith(
            locationStatus: _declined
                ? QiblaLocationStatus.locked
                : QiblaLocationStatus.needsPrompt,
            locationPermanentlyDenied: false,
          ),
        );
      case LocationAccess.granted:
        break;
    }
  }

  Future<void> _acquireFix() async {
    if (state.fix == null) {
      final provisional = await _repository.provisionalFix();
      if (isClosed) return;
      if (provisional != null && state.fix == null) {
        _applyFix(provisional, refining: true);
      }
    }
    _emit(
      state.fix == null
          ? state.copyWith(
              locationStatus: QiblaLocationStatus.locating,
              failure: null,
            )
          : state.copyWith(
              locationStatus: QiblaLocationStatus.ready,
              refiningFix: true,
              approximate: false,
              failure: null,
            ),
    );

    try {
      final fresh = await _repository.currentFix(timeLimit: locationTimeLimit);
      if (isClosed) return;
      _applyFix(fresh);
    } on TimeoutException {
      if (isClosed) return;
      _fallBack(QiblaFailure.timeout);
    } on LocationAccessException catch (e) {
      if (isClosed) return;
      if (state.fix != null) {
        _fallBack(QiblaFailure.locationError);
      } else {
        _emit(state.copyWith(refiningFix: false));
        await _handleAccess(e.access);
      }
    } catch (e) {
      debugPrint('Qibla location failed: $e');
      if (isClosed) return;
      _fallBack(QiblaFailure.locationError);
    }
  }

  /// The fresh reading did not come: keep the fix on screen if there is one,
  /// else fail. Only a provisional fix earns «آخر موقع معروف»; a GPS fix from
  /// a moment ago that merely failed to refresh is still a GPS fix.
  void _fallBack(QiblaFailure failure) {
    final shown = state.fix;
    if (shown != null) {
      _emit(
        state.copyWith(
          locationStatus: QiblaLocationStatus.ready,
          refiningFix: false,
          lastKnown: shown.isProvisional,
          failure: failure,
        ),
      );
    } else {
      _emit(
        state.copyWith(
          locationStatus: QiblaLocationStatus.failed,
          refiningFix: false,
          failure: failure,
        ),
      );
    }
  }

  void _applyFix(
    QiblaFix fix, {
    bool refining = false,
    bool approximate = false,
  }) {
    final bearing = QiblaGeodesy.qiblaBearing(fix.point);
    final distance = QiblaGeodesy.distanceToKaabaKm(fix.point);
    var next = state.copyWith(
      locationStatus: QiblaLocationStatus.ready,
      fix: fix,
      qiblaBearing: bearing,
      distanceKm: distance,
      refiningFix: refining,
      lastKnown: false,
      approximate: approximate,
      locationPermanentlyDenied: false,
      failure: null,
    );
    final heading = state.heading;
    if (heading != null) {
      next = next.copyWith(aligned: _evaluateAlignment(heading, next));
    }
    _emit(next);

    if (_movedSince(_declinationFix, fix, declinationRefreshKm)) {
      _declinationFix = fix;
      unawaited(_loadDeclination(fix));
    }
    if (_movedSince(_placeNameFix, fix, placeNameRefreshKm)) {
      _placeNameFix = fix;
      unawaited(_loadPlaceName(fix));
    }
    if (_celestialTimer != null) _tickCelestial();
  }

  static bool _movedSince(QiblaFix? previous, QiblaFix next, double km) =>
      previous == null ||
      QiblaGeodesy.distanceKm(previous.point, next.point) > km;

  Future<void> _loadDeclination(QiblaFix fix) async {
    double value;
    try {
      value = await _repository.declination(fix);
    } catch (e) {
      debugPrint('Qibla declination failed, using 0: $e');
      value = 0;
    }
    if (isClosed || !value.isFinite) return;
    _emit(state.copyWith(declination: value));
  }

  Future<void> _loadPlaceName(QiblaFix fix) async {
    final request = ++_placeNameRequest;
    String? name;
    try {
      name = await _repository.placeName(fix);
    } catch (e) {
      debugPrint('Qibla place name failed: $e');
    }
    // A newer fix has started its own lookup; this answer is for a place the
    // user may have left.
    if (isClosed || request != _placeNameRequest) return;
    _emit(state.copyWith(placeName: name));
  }

  // --- Compass ----------------------------------------------------------------

  void _onHeading(HeadingSample sample) {
    final raw = sample.heading;
    if (raw == null || !raw.isFinite) return;
    _sawHeadingSinceSubscribe = true;
    _headingSilenceTimer?.cancel();
    _headingSilenceTimer = null;

    // Fold first: Android's −170 is 190, not a reading to throw away.
    final magnetic = QiblaGeodesy.normalize(raw);
    final trueHeading = QiblaGeodesy.normalize(magnetic + state.declination);
    final smoothed = _smoother.add(trueHeading);

    final accuracy = sample.accuracyDegrees == null
        ? state.accuracy
        : CompassAccuracyLevel.fromDegrees(sample.accuracyDegrees);
    final aligned = _evaluateAlignment(smoothed, state);

    final last = _lastEmittedHeading;
    final moved =
        last == null ||
        QiblaGeodesy.signedDelta(smoothed, last).abs() >= minHeadingStep;
    if (!moved &&
        aligned == state.aligned &&
        accuracy == state.accuracy &&
        state.headingStatus == QiblaHeadingStatus.live) {
      return;
    }
    _lastEmittedHeading = smoothed;
    _emit(
      state.copyWith(
        heading: smoothed,
        headingStatus: QiblaHeadingStatus.live,
        accuracy: accuracy,
        aligned: aligned,
        arPhase: state.arActive ? _arPhaseFor(aligned) : null,
      ),
    );
  }

  /// Runs the hysteresis for [heading] against [against]'s bearing and fires
  /// the haptic on entry. Returns whether aligned.
  bool _evaluateAlignment(double heading, QiblaState against) {
    final bearing = against.qiblaBearing;
    if (bearing == null || against.atKaaba) {
      _tracker.reset();
      return false;
    }
    final entered = _tracker.update(QiblaGeodesy.signedDelta(bearing, heading));
    if (entered) _alignedHaptic();
    return _tracker.aligned;
  }

  void _alignedHaptic() {
    final now = _clock();
    final last = _lastHapticAt;
    if (last != null && now.difference(last) < _hapticCooldown) return;
    _lastHapticAt = now;
    _onAlignedHaptic();
  }

  void _onAccuracy(CompassAccuracyLevel level) {
    if (level == state.accuracy) return;
    _emit(state.copyWith(accuracy: level));
  }

  void _onHeadingError(Object error) {
    debugPrint('Qibla compass stream error: $error');
    if (state.heading == null) {
      _emit(state.copyWith(headingStatus: QiblaHeadingStatus.unavailable));
    }
  }

  void _onHeadingSilence() {
    _headingSilenceTimer = null;
    if (_sawHeadingSinceSubscribe || !_capabilities.silentWhenUncalibrated) {
      return;
    }
    _onAccuracy(CompassAccuracyLevel.low);
  }

  // --- AR ---------------------------------------------------------------------

  /// The AR view's camera is up (true) or gone (false). Heading and tilt run
  /// on the AR tab only while this is true, so the notice and the camera
  /// permission screen cost no sensors.
  void setArActive(bool active) {
    if (state.arActive == active) return;
    // A camera that finishes starting during the cross-fade away from the AR
    // tab reports in after the user has left it. Taken at its word, AR would
    // stay "active" on the compass tab, and the next AR visit would run the
    // sensors behind the safety notice.
    if (active && state.tab != QiblaTab.ar) return;
    _resetArTracking();
    _emit(
      state.copyWith(
        arActive: active,
        arPhase: QiblaArPhase.steadying,
        arProgress: 0,
        arHint: ArSteadyHint.ok,
      ),
    );
    _syncSubscriptions();
  }

  /// «إعادة الضبط»: back to the steady step.
  void resetAr() {
    _resetArTracking();
    _emit(
      state.copyWith(
        arPhase: QiblaArPhase.steadying,
        arProgress: 0,
        arHint: ArSteadyHint.ok,
      ),
    );
  }

  void _resetArTracking() {
    _steadyGate.reset();
    _filteredTilt = null;
  }

  QiblaArPhase _arPhaseFor(bool aligned) {
    if (!_steadyGate.isSteady) return QiblaArPhase.steadying;
    return aligned ? QiblaArPhase.aligned : QiblaArPhase.guiding;
  }

  void _onTilt(TiltSample raw) {
    final filtered = _filteredTilt?.lowPass(raw, tiltAlpha) ?? raw;
    _filteredTilt = filtered;
    final pitch = filtered.pitchDegrees;
    final roll = filtered.rollDegrees;
    final progress = _steadyGate.add(pitchDegrees: pitch, at: _clock());
    final phase = _arPhaseFor(state.aligned);
    final hint = _steadyGate.hint;

    final lastPitch = state.pitch;
    final lastRoll = state.roll;
    final poseMoved =
        lastPitch == null ||
        lastRoll == null ||
        (pitch - lastPitch).abs() >= 0.1 ||
        (roll - lastRoll).abs() >= 0.1;
    if (!poseMoved &&
        (progress - state.arProgress).abs() < 0.01 &&
        phase == state.arPhase &&
        hint == state.arHint) {
      return;
    }
    _emit(
      state.copyWith(
        pitch: pitch,
        roll: roll,
        arProgress: progress,
        arPhase: phase,
        arHint: hint,
      ),
    );
  }

  // --- Sun and moon -----------------------------------------------------------

  void _tickCelestial() {
    final fix = state.fix;
    if (fix == null || isClosed) return;
    final now = _clock();
    final sun = CelestialPosition.sun(
      now,
      latitude: fix.latitude,
      longitude: fix.longitude,
    );
    final moon = CelestialPosition.moon(
      now,
      latitude: fix.latitude,
      longitude: fix.longitude,
      heightMeters: fix.altitudeM ?? 0,
    );
    final body = state.bodyChosenByUser
        ? state.body
        : (sun.isAboveHorizon ? CelestialBody.sun : CelestialBody.moon);
    // The Islamic day starts at sunset: on an evening the night belongs to
    // tomorrow's date. The device clock decides "evening" because the Hijri
    // conversion is by the device's calendar date too.
    final evening = !sun.isAboveHorizon && now.hour >= 12;
    int? night;
    double? illumination;
    try {
      night = _hijriDayOf(evening ? now.add(const Duration(days: 1)) : now);
      illumination = _moonIlluminationOf(now);
    } catch (e) {
      debugPrint('Qibla moon details failed: $e');
    }
    _emit(
      state.copyWith(
        sun: sun,
        moon: moon,
        body: body,
        moonNight: night,
        moonIllumination: illumination,
        celestialUpdatedAt: now,
      ),
    );
  }

  // --- Subscriptions ------------------------------------------------------------

  void _syncSubscriptions() {
    if (isClosed) return;
    final active = _started && !_paused;
    final tab = state.tab;
    final arLive = tab == QiblaTab.ar && state.arActive;

    final wantHeading =
        active && _hasCompass && (tab == QiblaTab.compass || arLive);
    final wantTilt = active && _capabilities.tilt && arLive;
    final wantCelestial =
        active && (tab == QiblaTab.shadow || tab == QiblaTab.celestial);

    if (wantHeading && (_headingSub == null || _headingForCamera != arLive)) {
      // Entering or leaving AR swaps the compass heading for the camera's.
      _cancelHeading();
      _subscribeHeading(camera: arLive);
    } else if (!wantHeading && _headingSub != null) {
      _cancelHeading();
    }

    if (wantTilt && _tiltSub == null) {
      _filteredTilt = null;
      _tiltSub = _repository.tiltStream().listen(
        _onTilt,
        onError: (Object e) => debugPrint('Qibla tilt stream error: $e'),
      );
    } else if (!wantTilt && _tiltSub != null) {
      unawaited(_tiltSub!.cancel());
      _tiltSub = null;
    }

    if (wantCelestial && _celestialTimer == null) {
      _tickCelestial();
      _celestialTimer = Timer.periodic(
        celestialInterval,
        (_) => _tickCelestial(),
      );
    } else if (!wantCelestial && _celestialTimer != null) {
      _celestialTimer!.cancel();
      _celestialTimer = null;
    }
  }

  void _subscribeHeading({required bool camera}) {
    // A fresh start for the filter: the phone may have turned a long way while
    // nobody was listening, and the first new sample is the truth.
    _smoother.reset();
    _lastEmittedHeading = null;
    _sawHeadingSinceSubscribe = false;
    _headingForCamera = camera;
    _headingSub = _repository
        .headingStream(camera: camera)
        .listen(_onHeading, onError: _onHeadingError);
    _accuracySub = _repository.magnetometerAccuracy().listen(
      _onAccuracy,
      onError: (Object e) => debugPrint('Qibla accuracy stream error: $e'),
    );
    _headingSilenceTimer?.cancel();
    _headingSilenceTimer = Timer(headingSilenceTimeout, _onHeadingSilence);
    if (state.heading == null &&
        state.headingStatus != QiblaHeadingStatus.unavailable) {
      _emit(state.copyWith(headingStatus: QiblaHeadingStatus.waiting));
    }
  }

  void _cancelHeading() {
    unawaited(_headingSub?.cancel());
    unawaited(_accuracySub?.cancel());
    _headingSub = null;
    _accuracySub = null;
    _headingSilenceTimer?.cancel();
    _headingSilenceTimer = null;
  }

  void _emit(QiblaState next) {
    if (!isClosed) emit(next);
  }

  @override
  Future<void> close() {
    _cancelHeading();
    _tiltSub?.cancel();
    _tiltSub = null;
    _celestialTimer?.cancel();
    _celestialTimer = null;
    return super.close();
  }
}
