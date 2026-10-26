import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/geo/qibla_geodesy.dart';
import 'package:wadhakir/data/models/qibla_model.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';

import 'fakes/fake_qibla_repository.dart';

/// Cairo, 10:00 local on the December solstice: the sun is well up.
final DateTime morning = DateTime.utc(2026, 12, 21, 8);

/// Cairo, 22:00 local the same day: the sun is down.
final DateTime evening = DateTime.utc(2026, 12, 21, 20);

const double cairoQibla = 136.14;

class Harness {
  final FakeAsync async;
  final FakeQiblaRepository repo;
  final QiblaCubit cubit;
  final List<QiblaState> states = [];
  int haptics = 0;
  late final StreamSubscription<QiblaState> _sub;

  Harness(
    this.async,
    this.repo, {
    QiblaCapabilities capabilities = QiblaCapabilities.android,
    DateTime? t0,
  }) : cubit = _build(async, repo, capabilities, t0 ?? morning) {
    _sub = cubit.stream.listen(states.add);
  }

  static late Harness _current;

  static QiblaCubit _build(
    FakeAsync async,
    FakeQiblaRepository repo,
    QiblaCapabilities capabilities,
    DateTime t0,
  ) {
    return QiblaCubit(
      repository: repo,
      capabilities: capabilities,
      clock: () => t0.add(async.elapsed),
      onAlignedHaptic: () => _current.haptics++,
      hijriDayOf: (d) => d.day,
      moonIlluminationOf: (_) => 0.5,
    );
  }

  QiblaState get state => cubit.state;

  Iterable<QiblaLocationStatus> get statuses =>
      states.map((s) => s.locationStatus);

  void start() {
    cubit.start();
    flush();
  }

  void flush() => async.flushMicrotasks();

  /// Pushes [heading] until the smoother has settled on it.
  void settle(double heading, {int samples = 60}) {
    for (var i = 0; i < samples; i++) {
      repo.heading.add(HeadingSample(heading: heading));
      flush();
    }
  }

  /// Pushes a constant tilt every 20 ms for [duration].
  void holdTilt(TiltSample sample, Duration duration) {
    const step = Duration(milliseconds: 20);
    for (var t = Duration.zero; t <= duration; t += step) {
      repo.tilt.add(sample);
      flush();
      async.elapse(step);
    }
  }

  void dispose() {
    _sub.cancel();
    cubit.close();
    repo.dispose();
    flush();
  }
}

/// Runs [body] under fake time with a fresh harness.
void scenario(
  FakeQiblaRepository repo,
  void Function(Harness h) body, {
  QiblaCapabilities capabilities = QiblaCapabilities.android,
  DateTime? t0,
}) {
  fakeAsync((async) {
    final h = Harness(async, repo, capabilities: capabilities, t0: t0);
    Harness._current = h;
    body(h);
    h.dispose();
  });
}

/// About 45° camera depression, the emulator's `0:6.9:6.9`.
const TiltSample floorTilt = TiltSample(0, 6.9, 6.9);

void main() {
  group('location', () {
    test('granted: provisional fix at once, then the fresh one', () {
      final repo = FakeQiblaRepository(cached: cairoCached, name: 'القاهرة');
      scenario(repo, (h) {
        repo.pendingFix = Completer<QiblaFix>();
        h.start();
        expect(h.state.locationStatus, QiblaLocationStatus.ready);
        expect(h.state.fix, cairoCached);
        expect(h.state.refiningFix, isTrue);
        expect(h.state.qiblaBearing, closeTo(cairoQibla, 0.3));
        expect(h.state.distanceKm, closeTo(1287.2, 0.5));
        expect(h.state.placeName, 'القاهرة');

        repo.pendingFix!.complete(cairoGps);
        h.flush();
        expect(h.state.fix, cairoGps);
        expect(h.state.refiningFix, isFalse);
        expect(h.state.lastKnown, isFalse);
        expect(repo.lastTimeLimit, QiblaCubit.locationTimeLimit);
        expect(h.statuses, isNot(contains(QiblaLocationStatus.locating)));
        // Same place twice: one name lookup.
        expect(repo.placeNameCalls, 1);
      });
    });

    test('granted with nothing provisional shows locating, then ready', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        repo.pendingFix = Completer<QiblaFix>();
        h.start();
        expect(h.state.locationStatus, QiblaLocationStatus.locating);
        repo.pendingFix!.complete(cairoGps);
        h.flush();
        expect(h.state.locationStatus, QiblaLocationStatus.ready);
      });
    });

    test('start and resume never prompt', () {
      final repo = FakeQiblaRepository(access: LocationAccess.denied);
      scenario(repo, (h) {
        h.start();
        expect(h.state.locationStatus, QiblaLocationStatus.needsPrompt);
        h.cubit
          ..onAppPaused()
          ..onAppResumed();
        h.flush();
        expect(repo.requestCalls, 0);
        expect(repo.checkCalls, 2);
      });
    });

    test('one OS prompt, however many resumes and taps happen during it', () {
      // The OS dialog pauses and resumes the app; the old screen re-ran its
      // whole permission flow on each of those and stacked prompts.
      final repo = FakeQiblaRepository(access: LocationAccess.denied);
      scenario(repo, (h) {
        repo.pendingPrompt = Completer<LocationAccess>();
        h.start();
        h.cubit.allowLocation();
        h.flush();
        h.cubit
          ..onAppPaused()
          ..onAppResumed()
          ..onAppResumed()
          ..allowLocation();
        h.flush();
        expect(repo.requestCalls, 1);
        expect(repo.checkCalls, 1);

        repo.pendingPrompt!.complete(LocationAccess.granted);
        h.flush();
        expect(h.state.locationStatus, QiblaLocationStatus.ready);
        expect(repo.currentFixCalls, 1);

        h.cubit
          ..onAppPaused()
          ..onAppResumed();
        h.flush();
        expect(repo.checkCalls, 1, reason: 'a fix exists: nothing to re-check');
        expect(repo.currentFixCalls, 1);
      });
    });

    test('never emits locating while a fix exists', () {
      final repo = FakeQiblaRepository(cached: cairoCached);
      scenario(repo, (h) {
        h.start();
        expect(h.state.fix, cairoGps);
        repo.pendingFix = Completer<QiblaFix>();
        h.cubit.retryLocation();
        h.flush();
        expect(h.state.refiningFix, isTrue);
        expect(h.state.locationStatus, QiblaLocationStatus.ready);
        repo.pendingFix!.complete(cairoGps);
        h.flush();
        expect(h.statuses, isNot(contains(QiblaLocationStatus.locating)));
      });
    });

    test('a denial after the prompt keeps the prompt card', () {
      final repo = FakeQiblaRepository(
        access: LocationAccess.denied,
        accessAfterPrompt: LocationAccess.denied,
      );
      scenario(repo, (h) {
        h.start();
        h.cubit.allowLocation();
        h.flush();
        expect(h.state.locationStatus, QiblaLocationStatus.needsPrompt);
      });
    });

    test('deniedForever → settings → granted on the way back → ready', () {
      final repo = FakeQiblaRepository(access: LocationAccess.deniedForever);
      scenario(repo, (h) {
        h.start();
        expect(h.state.locationStatus, QiblaLocationStatus.locked);
        expect(h.state.locationPermanentlyDenied, isTrue);

        h.cubit.openAppSettings();
        h.flush();
        expect(repo.openAppSettingsCalls, 1);

        repo.access = LocationAccess.granted;
        h.cubit
          ..onAppPaused()
          ..onAppResumed();
        h.flush();
        expect(h.state.locationStatus, QiblaLocationStatus.ready);
        expect(h.state.fix, cairoGps);
        expect(h.state.locationPermanentlyDenied, isFalse);
        expect(repo.requestCalls, 0);
      });
    });

    test('service off → location settings → back → ready', () {
      final repo = FakeQiblaRepository(access: LocationAccess.serviceOff);
      scenario(repo, (h) {
        h.start();
        expect(h.state.locationStatus, QiblaLocationStatus.serviceOff);
        h.cubit.openLocationSettings();
        repo.access = LocationAccess.granted;
        h.cubit.onAppResumed();
        h.flush();
        expect(repo.openLocationSettingsCalls, 1);
        expect(h.state.locationStatus, QiblaLocationStatus.ready);
      });
    });

    test('a timeout keeps the provisional fix as "last known"', () {
      final repo = FakeQiblaRepository(cached: cairoCached)
        ..currentFixError = TimeoutException('no fix');
      scenario(repo, (h) {
        h.start();
        expect(h.state.locationStatus, QiblaLocationStatus.ready);
        expect(h.state.fix, cairoCached);
        expect(h.state.lastKnown, isTrue);
        expect(h.state.refiningFix, isFalse);
        expect(h.state.failure, QiblaFailure.timeout);
        expect(h.state.qiblaBearing, closeTo(cairoQibla, 0.3));
      });
    });

    test('a failed refresh of a GPS fix keeps it, without "last known"', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        expect(h.state.fix, cairoGps);
        repo.currentFixError = TimeoutException('no fix');
        h.cubit.retryLocation();
        h.flush();
        expect(h.state.fix, cairoGps);
        expect(h.state.locationStatus, QiblaLocationStatus.ready);
        expect(h.state.lastKnown, isFalse);
      });
    });

    test('a timeout with nothing provisional fails', () {
      final repo = FakeQiblaRepository()
        ..currentFixError = TimeoutException('no fix');
      scenario(repo, (h) {
        h.start();
        expect(h.state.locationStatus, QiblaLocationStatus.failed);
        expect(h.state.failure, QiblaFailure.timeout);

        repo.currentFixError = null;
        h.cubit.retryLocation();
        h.flush();
        expect(h.state.locationStatus, QiblaLocationStatus.ready);
        expect(h.state.failure, isNull);
      });
    });

    test('«ليس الآن» uses the saved prayer location, approximately', () {
      final repo = FakeQiblaRepository(
        access: LocationAccess.denied,
        cached: cairoCached,
      );
      scenario(repo, (h) {
        h.start();
        h.cubit.declineLocation();
        h.flush();
        expect(h.state.locationStatus, QiblaLocationStatus.ready);
        expect(h.state.approximate, isTrue);
        expect(h.state.fix, cairoCached);
        expect(repo.requestCalls, 0);

        // Still denied on return: the approximate fix stays.
        h.cubit.onAppResumed();
        h.flush();
        expect(h.state.approximate, isTrue);

        // Granted in Settings meanwhile: upgraded without a loader.
        repo.access = LocationAccess.granted;
        h.cubit.onAppResumed();
        h.flush();
        expect(h.state.approximate, isFalse);
        expect(h.state.fix, cairoGps);
        expect(h.statuses, isNot(contains(QiblaLocationStatus.locating)));
      });
    });

    test(
      '«ليس الآن» with nothing saved locks, and a resume keeps it locked',
      () {
        final repo = FakeQiblaRepository(access: LocationAccess.denied);
        scenario(repo, (h) {
          h.start();
          h.cubit.declineLocation();
          h.flush();
          expect(h.state.locationStatus, QiblaLocationStatus.locked);
          expect(h.state.locationPermanentlyDenied, isFalse);

          h.cubit.onAppResumed();
          h.flush();
          expect(h.state.locationStatus, QiblaLocationStatus.locked);
        });
      },
    );
  });

  group('sensors follow the tab', () {
    test('heading only on Compass; pause drops it, resume brings it back', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        expect(h.state.tab, QiblaTab.compass);
        expect(repo.headingListening, isTrue);
        expect(repo.accuracyListening, isTrue);
        expect(repo.tiltListening, isFalse);
        h.settle(100);

        h.cubit.selectTab(QiblaTab.map);
        expect(repo.headingListening, isFalse);
        expect(repo.accuracyListening, isFalse);

        h.cubit.selectTab(QiblaTab.compass);
        expect(repo.headingListening, isTrue);

        h.cubit.onAppPaused();
        expect(repo.headingListening, isFalse);
        expect(h.state.heading, closeTo(100, 0.5), reason: 'last value kept');
        expect(h.state.headingStatus, QiblaHeadingStatus.live);

        h.cubit.onAppResumed();
        expect(repo.headingListening, isTrue);
        expect(repo.headingListens, 3);
      });
    });

    test('AR follows the camera\'s heading, the compass tab the compass', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        expect(repo.headingCameraRequests, [false]);

        h.cubit
          ..selectTab(QiblaTab.ar)
          ..setArActive(true);
        // Past 45° of tilt the compass reports the phone's top edge, which a
        // sideways tilt turns while the camera does not.
        expect(repo.headingCameraRequests.last, isTrue);
        expect(repo.headingListening, isTrue);

        h.cubit.selectTab(QiblaTab.compass);
        expect(repo.headingCameraRequests.last, isFalse);
        expect(repo.headingListening, isTrue);
      });
    });

    test('a camera that reports in after the user left AR is ignored', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        h.cubit.selectTab(QiblaTab.compass);

        // The old AR view's camera finishing during the tab cross-fade.
        h.cubit.setArActive(true);

        expect(h.state.arActive, isFalse);
        expect(repo.tiltListening, isFalse);
      });
    });

    test('AR listens to heading and tilt only once its camera is up', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        h.cubit.selectTab(QiblaTab.ar);
        expect(repo.headingListening, isFalse);
        expect(repo.tiltListening, isFalse);

        h.cubit.setArActive(true);
        expect(repo.headingListening, isTrue);
        expect(repo.tiltListening, isTrue);

        h.cubit.onAppPaused();
        expect(repo.tiltListening, isFalse);
        h.cubit.onAppResumed();
        expect(repo.tiltListening, isTrue);

        // Leaving the tab stands AR down from the cubit's side; the AR view
        // never touches the cubit in dispose.
        h.cubit.selectTab(QiblaTab.compass);
        expect(repo.tiltListening, isFalse);
        expect(repo.headingListening, isTrue);
        expect(h.state.arActive, isFalse);
      });
    });

    test('the sun/moon tick runs every 15 s on its tabs only', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        expect(h.state.sun, isNull);

        h.cubit.selectTab(QiblaTab.shadow);
        expect(h.state.sun, isNotNull);
        expect(h.state.celestialUpdatedAt, morning);

        h.async.elapse(const Duration(seconds: 15));
        expect(
          h.state.celestialUpdatedAt,
          morning.add(const Duration(seconds: 15)),
        );

        h.cubit.selectTab(QiblaTab.map);
        h.async.elapse(const Duration(minutes: 1));
        expect(
          h.state.celestialUpdatedAt,
          morning.add(const Duration(seconds: 15)),
        );

        h.cubit.selectTab(QiblaTab.celestial);
        expect(
          h.state.celestialUpdatedAt,
          morning.add(const Duration(seconds: 75)),
        );

        h.cubit.onAppPaused();
        h.async.elapse(const Duration(minutes: 1));
        expect(
          h.state.celestialUpdatedAt,
          morning.add(const Duration(seconds: 75)),
        );
      });
    });
  });

  group('heading pipeline', () {
    test('Android\'s negative headings are folded, not dropped', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        h.settle(-170);
        expect(h.state.heading, closeTo(190, 0.01));
        expect(h.state.headingStatus, QiblaHeadingStatus.live);
      });
    });

    test('null headings are skipped', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        repo.heading.add(const HeadingSample());
        h.flush();
        expect(h.state.heading, isNull);
        expect(h.state.headingStatus, QiblaHeadingStatus.waiting);
      });
    });

    test('the declination turns a magnetic heading into a true one', () {
      final repo = FakeQiblaRepository(declinationDegrees: 4.5);
      scenario(repo, (h) {
        h.start();
        expect(h.state.declination, 4.5);
        h.settle(100);
        expect(h.state.heading, closeTo(104.5, 0.01));
        // After a long turn the shown heading may trail the filter by up to
        // the half-degree emit step.
        h.settle(-170);
        expect(h.state.heading, closeTo(194.5, QiblaCubit.minHeadingStep));
      });
    });

    test('changes under half a degree are not emitted', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        h.settle(100);
        final before = h.states.length;
        h.settle(100.2, samples: 20);
        expect(h.states.length, before);
      });
    });

    test('one haptic per entry into alignment, with a cooldown', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        h.settle(100);
        expect(h.state.aligned, isFalse);
        expect(h.haptics, 0);

        h.settle(cairoQibla);
        expect(h.state.aligned, isTrue);
        expect(h.haptics, 1);
        expect(
          h.state.qiblaOffset!.abs(),
          lessThanOrEqualTo(QiblaCubit.minHeadingStep),
        );

        h.settle(cairoQibla + 5); // inside the 7° leave band
        expect(h.state.aligned, isTrue);
        expect(h.haptics, 1);

        h.settle(170);
        expect(h.state.aligned, isFalse);
        h.settle(cairoQibla); // re-entry inside the 1.5 s cooldown
        expect(h.state.aligned, isTrue);
        expect(h.haptics, 1);

        h.async.elapse(const Duration(seconds: 2));
        h.settle(170);
        h.settle(cairoQibla);
        expect(h.haptics, 2);
      });
    });

    test('at the Kaaba nothing is ever "aligned"', () {
      final repo = FakeQiblaRepository(
        fresh: const QiblaFix(
          latitude: 21.422487,
          longitude: 39.826206,
          source: QiblaFixSource.gps,
        ),
      );
      scenario(repo, (h) {
        h.start();
        expect(h.state.atKaaba, isTrue);
        h.settle(0);
        expect(h.state.aligned, isFalse);
        expect(h.haptics, 0);
      });
    });

    test('the turn offset is positive when the qibla is to the right', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        h.settle(100);
        expect(h.state.qiblaOffset, closeTo(cairoQibla - 100, 0.3));
      });
    });
  });

  group('compass availability and calibration', () {
    test('no magnetometer: compass unavailable, AR hidden, no listening', () {
      final repo = FakeQiblaRepository(magnetometer: false);
      scenario(repo, (h) {
        h.start();
        expect(h.state.headingStatus, QiblaHeadingStatus.unavailable);
        expect(h.state.availableTabs, [
          QiblaTab.compass,
          QiblaTab.map,
          QiblaTab.shadow,
          QiblaTab.celestial,
        ]);
        expect(repo.headingListening, isFalse);
        expect(h.state.locationStatus, QiblaLocationStatus.ready);
      });
    });

    test(
      'desktop: Map, Shadow, Sun; opens on Map; never asks for a compass',
      () {
        final repo = FakeQiblaRepository();
        scenario(repo, capabilities: QiblaCapabilities.desktop, (h) {
          expect(h.state.tab, QiblaTab.map);
          h.start();
          expect(h.state.availableTabs, [
            QiblaTab.map,
            QiblaTab.shadow,
            QiblaTab.celestial,
          ]);
          expect(h.state.tab, QiblaTab.map);
          expect(h.state.headingStatus, QiblaHeadingStatus.unavailable);
          expect(repo.hasMagnetometerCalls, 0);
          h.cubit.selectTab(QiblaTab.ar);
          expect(h.state.tab, QiblaTab.map, reason: 'AR is not on offer');
          expect(h.state.locationStatus, QiblaLocationStatus.ready);
        });
      },
    );

    test('a low magnetometer reading shows calibration until skipped', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        expect(h.state.showCalibration, isFalse, reason: 'unknown is quiet');

        repo.accuracy.add(CompassAccuracyLevel.low);
        h.flush();
        expect(h.state.showCalibration, isTrue);

        h.cubit.dismissCalibration();
        expect(h.state.showCalibration, isFalse);

        repo.accuracy.add(CompassAccuracyLevel.high);
        h.flush();
        expect(h.state.accuracy, CompassAccuracyLevel.high);
      });
    });

    test('iOS accuracy rides on the heading samples', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        repo.heading.add(const HeadingSample(heading: 10, accuracyDegrees: 40));
        h.flush();
        expect(h.state.accuracy, CompassAccuracyLevel.low);
      });
    });

    test('silence on iOS means "calibrate"; on Android it means nothing', () {
      const ios = QiblaCapabilities(
        compass: true,
        camera: true,
        tilt: true,
        silentWhenUncalibrated: true,
      );
      scenario(FakeQiblaRepository(), capabilities: ios, (h) {
        h.start();
        h.async.elapse(QiblaCubit.headingSilenceTimeout);
        expect(h.state.accuracy, CompassAccuracyLevel.low);
        expect(h.state.showCalibration, isTrue);
      });
      scenario(FakeQiblaRepository(), (h) {
        h.start();
        h.async.elapse(QiblaCubit.headingSilenceTimeout);
        expect(h.state.accuracy, CompassAccuracyLevel.unknown);
      });
    });
  });

  group('AR', () {
    test('steadying → guiding → aligned, and «إعادة الضبط» starts over', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        h.cubit
          ..selectTab(QiblaTab.ar)
          ..setArActive(true);
        h.settle(100);
        expect(h.state.arPhase, QiblaArPhase.steadying);

        h.holdTilt(floorTilt, const Duration(milliseconds: 1700));
        expect(h.state.pitch, closeTo(45, 0.5));
        expect(h.state.arProgress, 1);
        expect(h.state.arPhase, QiblaArPhase.guiding);

        h.settle(cairoQibla);
        expect(h.state.arPhase, QiblaArPhase.aligned);

        h.cubit.resetAr();
        expect(h.state.arPhase, QiblaArPhase.steadying);
        expect(h.state.arProgress, 0);
      });
    });

    test('a phone pointed at the horizon is told to tilt down', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        h.cubit
          ..selectTab(QiblaTab.ar)
          ..setArActive(true);
        h.holdTilt(const TiltSample(0, 9.8, 0.5), const Duration(seconds: 2));
        expect(h.state.arPhase, QiblaArPhase.steadying);
        expect(h.state.arHint, ArSteadyHint.tiltDown);
      });
    });

    test('pausing restarts the steady step', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        h.cubit
          ..selectTab(QiblaTab.ar)
          ..setArActive(true);
        h.holdTilt(floorTilt, const Duration(milliseconds: 1700));
        expect(h.state.arPhase, QiblaArPhase.guiding);
        h.cubit.onAppPaused();
        expect(h.state.arPhase, QiblaArPhase.steadying);
        expect(h.state.arProgress, 0);
      });
    });
  });

  group('sun and moon', () {
    test('by day the Sun/Moon tab picks the sun', () {
      final repo = FakeQiblaRepository();
      scenario(repo, (h) {
        h.start();
        h.cubit.selectTab(QiblaTab.celestial);
        expect(h.state.sun!.isAboveHorizon, isTrue);
        expect(h.state.body, CelestialBody.sun);
        expect(h.state.shadowStatus, QiblaShadowStatus.usable);
        expect(
          h.state.shadowAzimuth,
          closeTo(QiblaGeodesy.normalize(h.state.sun!.azimuth + 180), 1e-9),
        );
        expect(h.state.qiblaFromBody, isNotNull);
      });
    });

    test('by night it picks the moon and counts tomorrow\'s Hijri night', () {
      final repo = FakeQiblaRepository();
      scenario(repo, t0: evening, (h) {
        h.start();
        h.cubit.selectTab(QiblaTab.celestial);
        expect(h.state.sun!.isAboveHorizon, isFalse);
        expect(h.state.body, CelestialBody.moon);
        expect(h.state.shadowStatus, QiblaShadowStatus.sunTooLow);
        // The fake calendar is the Gregorian day; after sunset the night
        // belongs to the next date.
        expect(h.state.moonNight, 22);
        expect(h.state.moonIllumination, 0.5);
        expect(h.state.moonFaint, isFalse);
      });
    });

    test('a manual choice sticks across ticks', () {
      final repo = FakeQiblaRepository();
      scenario(repo, t0: evening, (h) {
        h.start();
        h.cubit
          ..selectTab(QiblaTab.celestial)
          ..selectBody(CelestialBody.sun);
        h.async.elapse(const Duration(seconds: 30));
        expect(h.state.body, CelestialBody.sun);
        expect(h.state.bodyChosenByUser, isTrue);
      });
    });

    test('no fix, no sky', () {
      final repo = FakeQiblaRepository(access: LocationAccess.denied);
      scenario(repo, (h) {
        h.start();
        h.cubit.selectTab(QiblaTab.shadow);
        expect(h.state.sun, isNull);
        expect(h.state.shadowStatus, QiblaShadowStatus.unavailable);
      });
    });
  });

  test('close cancels every subscription and timer', () {
    final repo = FakeQiblaRepository();
    fakeAsync((async) {
      final cubit = QiblaCubit(
        repository: repo,
        capabilities: QiblaCapabilities.android,
        clock: () => morning.add(async.elapsed),
        onAlignedHaptic: () {},
      );
      cubit.start();
      async.flushMicrotasks();
      cubit.selectTab(QiblaTab.ar);
      cubit.setArActive(true);
      expect(repo.tiltListening, isTrue);
      cubit.close();
      async.flushMicrotasks();
      expect(repo.headingListening, isFalse);
      expect(repo.tiltListening, isFalse);
      expect(async.periodicTimerCount, 0);
      expect(async.nonPeriodicTimerCount, 0);
    });
  });
}
