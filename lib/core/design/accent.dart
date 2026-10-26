import 'package:flutter/material.dart';

/// The brand accent for strokes, arcs and accent text.
///
/// Both themes use Twilight Blue `#20497D` as `colorScheme.primary`. That is
/// right for fills behind white text, but as a stroke or text colour on the
/// dark surfaces it measures about 2:1 against `#121212`, so arcs, active
/// beads and accent numbers vanish at night. In dark mode the accent is the
/// same hue lifted toward white (about `#7992B1`), which keeps the brand
/// while reading clearly.
///
/// Use `colorScheme.primary` for filled buttons and selected pills; use this
/// for anything drawn *on* the surface.
class AppAccent {
  AppAccent._();

  /// How far the dark-mode accent is lifted toward white.
  static const double darkLift = 0.42;

  static Color of(BuildContext context) {
    final theme = Theme.of(context);
    return forBrightness(theme.colorScheme.primary, theme.brightness);
  }

  static Color forBrightness(Color primary, Brightness brightness) {
    if (brightness == Brightness.light) return primary;
    return Color.lerp(primary, Colors.white, darkLift)!;
  }
}
