import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/geo/heading_math.dart';
import 'package:wadhakir/core/geo/qibla_geodesy.dart';

void main() {
  group('HeadingSmoother', () {
    test('takes the first sample as-is, normalised', () {
      final s = HeadingSmoother();
      expect(s.value, isNull);
      expect(s.add(-170), closeTo(190, 1e-9));
    });

    test('smooths across north without swinging through south', () {
      final s = HeadingSmoother()..add(359);
      for (var i = 0; i < 30; i++) {
        final v = s.add(1);
        // Anywhere between 359 and 1 the short way; never near 180.
        expect(
          QiblaGeodesy.signedDelta(v, 0).abs(),
          lessThanOrEqualTo(1.0001),
          reason: 'step $i gave $v',
        );
      }
      expect(QiblaGeodesy.signedDelta(s.value!, 1).abs(), lessThan(0.1));
    });

    test('converges to a steady input', () {
      final s = HeadingSmoother()..add(10);
      for (var i = 0; i < 60; i++) {
        s.add(20);
      }
      expect(s.value, closeTo(20, 0.01));
    });

    test('moves gently on small changes and fast on big jumps', () {
      final small = HeadingSmoother()..add(0);
      final afterSmall = small.add(10);
      expect(afterSmall, closeTo(1.5, 0.2), reason: 'alpha 0.15');

      final big = HeadingSmoother()..add(0);
      final afterBig = big.add(90);
      expect(afterBig, greaterThan(40), reason: 'alpha 0.5 past 30°');
    });

    test('an exactly opposite jump lands on the new sample', () {
      final s = HeadingSmoother()..add(0);
      expect(s.add(180), closeTo(180, 1e-6));
    });

    test('reset forgets the history', () {
      final s = HeadingSmoother()
        ..add(10)
        ..reset();
      expect(s.value, isNull);
      expect(s.add(200), closeTo(200, 1e-9));
    });
  });

  group('AlignmentTracker', () {
    test('enters at 4° and reports the entry exactly once', () {
      final t = AlignmentTracker();
      expect(t.update(10), isFalse);
      expect(t.aligned, isFalse);
      expect(t.update(4), isTrue);
      expect(t.aligned, isTrue);
      expect(t.update(3), isFalse, reason: 'already in: no second entry');
      expect(t.update(-2), isFalse);
    });

    test('stays aligned up to 7° and leaves just past it', () {
      final t = AlignmentTracker()..update(0);
      expect(t.update(6.9), isFalse);
      expect(t.aligned, isTrue);
      expect(t.update(-7), isFalse);
      expect(t.aligned, isTrue);
      expect(t.update(7.1), isFalse);
      expect(t.aligned, isFalse);
    });

    test('trembling around 5° does not flicker', () {
      final t = AlignmentTracker();
      var entries = 0;
      for (final d in [4.0, 5.5, 4.5, 6.0, 5.0, 6.5, 4.2]) {
        if (t.update(d)) entries++;
      }
      expect(entries, 1);
    });

    test('re-entering after leaving counts as a new entry', () {
      final t = AlignmentTracker()..update(0);
      t.update(20);
      expect(t.update(1), isTrue);
    });
  });

  group('CompassAccuracyLevel.fromDegrees', () {
    test('maps the 15 / 30 / 45 scale', () {
      expect(CompassAccuracyLevel.fromDegrees(15), CompassAccuracyLevel.high);
      expect(CompassAccuracyLevel.fromDegrees(30), CompassAccuracyLevel.medium);
      expect(CompassAccuracyLevel.fromDegrees(45), CompassAccuracyLevel.low);
    });

    test('maps iOS degree estimates', () {
      expect(CompassAccuracyLevel.fromDegrees(5.2), CompassAccuracyLevel.high);
      expect(
        CompassAccuracyLevel.fromDegrees(22.0),
        CompassAccuracyLevel.medium,
      );
      expect(CompassAccuracyLevel.fromDegrees(31.0), CompassAccuracyLevel.low);
    });

    test('no estimate is unknown, never low', () {
      expect(
        CompassAccuracyLevel.fromDegrees(null),
        CompassAccuracyLevel.unknown,
      );
      expect(
        CompassAccuracyLevel.fromDegrees(-1),
        CompassAccuracyLevel.unknown,
      );
      expect(
        CompassAccuracyLevel.fromDegrees(double.nan),
        CompassAccuracyLevel.unknown,
      );
    });

    test('only low asks for calibration', () {
      expect(CompassAccuracyLevel.low.needsCalibration, isTrue);
      expect(CompassAccuracyLevel.unknown.needsCalibration, isFalse);
      expect(CompassAccuracyLevel.medium.needsCalibration, isFalse);
      expect(CompassAccuracyLevel.high.needsCalibration, isFalse);
    });
  });
}
