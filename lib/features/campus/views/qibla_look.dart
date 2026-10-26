import 'package:flutter/material.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/core/design/design_tokens.dart';

/// The qibla screens' few colours beyond the theme, in one place.
///
/// Everything else comes from `colorScheme` (fills, surfaces) and
/// [AppAccent] (strokes, arcs and accent text, lifted in dark mode so it
/// reads on `#121212`).
abstract final class QiblaLook {
  /// Status green, the app's on-time / prayer green with its brighter dark
  /// sibling: "facing the qibla", high accuracy, the aligned rug.
  static Color success(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkPrayerAzkarColor
      : prayerAzkarColor;

  /// Status amber, as the Salah tracker's "late": low accuracy, a sun too low
  /// for the shadow method.
  static Color warning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFF0B429)
      : const Color(0xFFD98E04);

  /// The accent drawn over the live camera picture. The camera image is
  /// whatever the room looks like, light or dark theme alike, so this is
  /// always the lifted (dark-mode) accent: brand blue that still reads
  /// against a floor.
  static Color cameraAccent(BuildContext context) => AppAccent.forBrightness(
    Theme.of(context).colorScheme.primary,
    Brightness.dark,
  );

  /// Secondary text: ink at 60%, which keeps AA contrast outdoors (DESIGN.md
  /// rules out the companion gray for text).
  static Color muted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

  /// The big degree readout under each dial. Almarai ships only 400 and 700.
  static TextStyle readout(BuildContext context, Color color) => TextStyle(
    fontFamily: 'Almarai',
    fontWeight: FontWeight.w700,
    fontSize: 52,
    height: 1.1,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Body copy under the dial.
  static TextStyle body(BuildContext context) => TextStyle(
    fontFamily: 'Almarai',
    fontSize: 15,
    height: 1.5,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
  );

  /// Card shell shared by the qibla cards: surface, `Radii.md`, a hairline
  /// border and the ambient rest shadow (≤ 5% black).
  static BoxDecoration card(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: dark ? theme.cardColor : cs.surface,
      borderRadius: BorderRadius.circular(Radii.md),
      border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.3 : 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

/// An `FButton` label that wraps instead of overflowing. forui places the
/// child straight into its content `Row`, so a plain `Text` runs off the
/// button at a large text size on a small phone; this is a `Flexible` in
/// that row.
class QiblaButtonLabel extends StatelessWidget {
  final String label;

  const QiblaButtonLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) =>
      Flexible(child: Text(label, textAlign: TextAlign.center));
}
