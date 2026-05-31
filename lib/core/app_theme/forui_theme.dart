import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';

/// Builds a forui [FThemeData] from the app's live Material [ThemeData].
///
/// forui is layered alongside Material (the Quran reader, syncfusion pickers,
/// etc. stay on Material). Deriving forui's colors from the active
/// [ColorScheme] keeps a single source of truth — `app_theme.dart` — so forui
/// components automatically track the app's brand colors and light/dark mode.
FThemeData buildForuiTheme(ThemeData theme) {
  final cs = theme.colorScheme;
  final isDark = cs.brightness == Brightness.dark;

  Color blend(Color over, double alpha) =>
      Color.alphaBlend(over.withValues(alpha: alpha), cs.surface);

  final colors = FColors(
    brightness: cs.brightness,
    systemOverlayStyle: isDark
        ? kOverlayStyleLightIcons
        : kOverlayStyleDarkIcons,
    barrier: Colors.black54,
    background: theme.scaffoldBackgroundColor,
    foreground: cs.onSurface,
    primary: cs.primary,
    primaryForeground: cs.onPrimary,
    // Secondary surfaces use a subtle primary tint so buttons/tiles stay
    // on-brand rather than the default Material 2 secondary (purple-ish).
    secondary: blend(cs.primary, isDark ? 0.18 : 0.08),
    secondaryForeground: cs.onSurface,
    muted: blend(cs.onSurface, isDark ? 0.10 : 0.04),
    mutedForeground: cs.onSurface.withValues(alpha: 0.6),
    destructive: cs.error,
    destructiveForeground: cs.onError,
    error: cs.error,
    errorForeground: cs.onError,
    card: theme.cardColor,
    border: cs.onSurface.withValues(alpha: isDark ? 0.16 : 0.12),
  );

  final touch = !PlatformUtils.isDesktop;

  return FThemeData(
    colors: colors,
    touch: touch,
    // Match the rest of the app — keep Almarai everywhere.
    typography: FTypography.inherit(
      colors: colors,
      touch: touch,
      fontFamily: 'Almarai',
    ),
  );
}
