import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/design_tokens.dart';

/// The colours the tasbih paints with, resolved once per build for the
/// current theme — or for focus mode, which is dark whatever the theme is.
///
/// Focus mode cannot simply wrap itself in a dark [Theme]: [AppAccent.of]
/// would then lift the *focus background* toward white and produce a grey,
/// not the brand blue. So the accent is derived from the real brand primary
/// here, and only the header gets a local theme (see the screen).
@immutable
class TasbihLook {
  const TasbihLook({
    required this.focus,
    required this.isDark,
    required this.primary,
    required this.accent,
    required this.ink,
    required this.muted,
    required this.neutral,
    required this.surface,
    required this.background,
  });

  /// The UI face. Spelled out on every style taken from a text-theme slot
  /// the app theme leaves unset (titleMedium, labelLarge, bodySmall): those
  /// fall back to Roboto, which has no Arabic, and the platform then picks
  /// some other Arabic face — never Almarai.
  static const String uiFont = 'Almarai';

  /// Midnight Ink, the brand's darkest colour.
  static const Color _midnightInk = Color(0xFF0D1122);

  /// Focus mode's background: Midnight Ink with a breath of the brand blue,
  /// so it reads as Wadhakir at night rather than as a generic black screen.
  static Color focusBackground(Color primary) =>
      Color.lerp(_midnightInk, primary, 0.12)!;

  factory TasbihLook.of(BuildContext context, {required bool focus}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (focus) {
      return TasbihLook(
        focus: true,
        isDark: true,
        primary: cs.primary,
        accent: AppAccent.forBrightness(cs.primary, Brightness.dark),
        ink: Colors.white,
        muted: Colors.white.withValues(alpha: 0.62),
        neutral: Colors.white,
        surface: Colors.white.withValues(alpha: 0.08),
        background: focusBackground(cs.primary),
      );
    }
    final isDark = theme.brightness == Brightness.dark;
    return TasbihLook(
      focus: false,
      isDark: isDark,
      primary: cs.primary,
      accent: AppAccent.of(context),
      ink: cs.onSurface,
      muted: cs.onSurface.withValues(alpha: 0.62),
      neutral: cs.onSurface,
      surface: cs.surface,
      background: theme.scaffoldBackgroundColor,
    );
  }

  final bool focus;
  final bool isDark;

  /// The brand primary, for fills behind white.
  final Color primary;

  /// Strokes, arcs, accent text — readable on [background] in every mode.
  final Color accent;

  /// Main text.
  final Color ink;

  /// Secondary text; at 62% it stays above 4.5:1 on both backgrounds.
  final Color muted;

  /// The base for neutral tints (tracks, remaining beads, chips).
  final Color neutral;

  /// Raised surfaces: the tap circle, the action pill.
  final Color surface;

  final Color background;

  /// The "selected" tint for pills and toggles: 12% light, 22% dark (the
  /// feature-tile rule in DESIGN.md), white in focus mode.
  Color get selectedTint => focus
      ? Colors.white.withValues(alpha: 0.14)
      : primary.withValues(alpha: isDark ? 0.22 : 0.12);

  /// Text and icons on a selected tint. In dark mode the primary itself is too
  /// dark to read on the tint, so the lifted accent is used.
  Color get onSelected => accent;
}
