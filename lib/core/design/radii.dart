import 'package:flutter/widgets.dart';

/// Standard corner radii. `pill` is for fully-rounded shapes (pill bars,
/// status indicators). Keep cards consistent across the app by using `md`
/// for compact cards and `lg` for hero/glass cards.
class Radii {
  Radii._();

  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 16.0;
  static const double lg = 22.0;
  static const double pill = 999.0;

  static BorderRadius all(double value) => BorderRadius.circular(value);

  static const BorderRadius pillBorder = BorderRadius.all(
    Radius.circular(pill),
  );
}
