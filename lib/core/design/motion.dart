import 'package:flutter/animation.dart';

/// Motion tokens. Durations follow Material's "fast / base / slow" pacing
/// (150 / 240 / 320 ms) which feels responsive without being snappy.
class Motion {
  Motion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 320);

  /// "Emphasized" easing — slightly more dramatic than the standard curve;
  /// good for hero transitions and large entrances.
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);

  /// Standard easing for everyday motion.
  static const Curve standard = Curves.easeOutCubic;
}
