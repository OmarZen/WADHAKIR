import 'dart:math' as math;

import 'package:wadhakir/core/geo/qibla_geodesy.dart';

/// How far the compass can be trusted right now.
///
/// Only [low] asks the user to calibrate. [unknown] is the honest answer for
/// "the phone did not say", and nagging someone to wave their phone about on
/// a reading that may well be fine is worse than saying nothing.
enum CompassAccuracyLevel {
  high,
  medium,
  low,
  unknown;

  /// Maps an error estimate in degrees to a level.
  ///
  /// Two sources feed this, on the same scale:
  /// * iOS: flutter_compass passes `CLHeading.headingAccuracy` straight
  ///   through, a real ± estimate in degrees.
  /// * Android: the native qibla bridge maps the MAGNETOMETER's own
  ///   `SENSOR_STATUS_*` to 15 / 30 / 45 (high / medium / low), the same
  ///   numbers flutter_compass uses. flutter_compass's own Android accuracy
  ///   is not used: it reports whichever of the accelerometer and
  ///   magnetometer spoke last, so a calibrated accelerometer routinely
  ///   hides an uncalibrated magnetometer.
  ///
  /// Null, negative and non-finite values mean the platform gave no estimate.
  static CompassAccuracyLevel fromDegrees(num? degrees) {
    if (degrees == null || degrees.isNaN || degrees.isInfinite || degrees < 0) {
      return CompassAccuracyLevel.unknown;
    }
    if (degrees <= 15) return CompassAccuracyLevel.high;
    if (degrees <= 30) return CompassAccuracyLevel.medium;
    return CompassAccuracyLevel.low;
  }

  /// The only level that shows the calibration card on its own.
  bool get needsCalibration => this == CompassAccuracyLevel.low;
}

/// Low-pass filter for a compass heading.
///
/// Headings are smoothed as unit vectors, not as numbers: averaging 359° and
/// 1° as numbers gives 180°, the exact opposite of the truth, and the needle
/// would swing through south every time the user faced north.
///
/// A small [alpha] gives a calm needle; a sudden large turn switches to
/// [jumpAlpha] so the needle catches up in a few samples instead of drifting
/// round for a second while the user waits.
class HeadingSmoother {
  /// Weight of a new sample in normal running.
  final double alpha;

  /// Weight of a new sample when it differs from the current value by more
  /// than [jumpThresholdDegrees].
  final double jumpAlpha;

  final double jumpThresholdDegrees;

  HeadingSmoother({
    this.alpha = 0.15,
    this.jumpAlpha = 0.5,
    this.jumpThresholdDegrees = 30,
  }) : assert(alpha > 0 && alpha <= 1),
       assert(jumpAlpha > 0 && jumpAlpha <= 1);

  double? _x;
  double? _y;
  double? _value;

  /// The smoothed heading in `[0, 360)`, or null before the first sample.
  double? get value => _value;

  /// Feeds one heading (any range; it is normalised) and returns the new
  /// smoothed heading.
  double add(double headingDegrees) {
    final heading = QiblaGeodesy.normalize(headingDegrees);
    final rad = heading * math.pi / 180;
    final sx = math.cos(rad);
    final sy = math.sin(rad);
    final current = _value;
    if (current == null) {
      return _set(sx, sy, heading);
    }
    final jump =
        QiblaGeodesy.signedDelta(heading, current).abs() > jumpThresholdDegrees;
    final a = jump ? jumpAlpha : alpha;
    var x = (1 - a) * _x! + a * sx;
    var y = (1 - a) * _y! + a * sy;
    final length = math.sqrt(x * x + y * y);
    // A sample exactly opposite the current value at a = 0.5 cancels the
    // vector out; its direction is then whatever rounding says. The new
    // sample is the only defensible answer.
    if (length < 1e-9) return _set(sx, sy, heading);
    x /= length;
    y /= length;
    return _set(x, y, QiblaGeodesy.normalize(math.atan2(y, x) * 180 / math.pi));
  }

  /// Forgets the history; the next sample is taken as-is.
  void reset() {
    _x = null;
    _y = null;
    _value = null;
  }

  double _set(double x, double y, double value) {
    _x = x;
    _y = y;
    _value = value;
    return value;
  }
}

/// "Facing the qibla", with hysteresis.
///
/// Entering takes [enterDegrees] or better; leaving takes worse than
/// [leaveDegrees]. A single threshold flickers on and off as the needle
/// trembles across it, and every flicker would fire the aligned haptic.
class AlignmentTracker {
  final double enterDegrees;
  final double leaveDegrees;

  AlignmentTracker({this.enterDegrees = 4, this.leaveDegrees = 7})
    : assert(leaveDegrees >= enterDegrees);

  bool _aligned = false;

  bool get aligned => _aligned;

  /// Feeds the current offset from the qibla (signed or not) and returns
  /// true on exactly the sample that ENTERS alignment, so the caller can fire
  /// one haptic per entry.
  bool update(double deltaDegrees) {
    final off = deltaDegrees.abs();
    if (!_aligned && off <= enterDegrees) {
      _aligned = true;
      return true;
    }
    if (_aligned && off > leaveDegrees) {
      _aligned = false;
    }
    return false;
  }

  void reset() => _aligned = false;
}
