import 'dart:ui';

import 'package:flutter/material.dart';

/// Glassmorphism intensity preset. Three levels balance readability against
/// the frosted feel — `light` for chips, `medium` for cards (the default),
/// `heavy` for hero panels that need to read clearly over busy backgrounds.
enum GlassIntensity { light, medium, heavy }

/// Centralised glassmorphism tokens. Keeping blur sigma, opacity, and
/// borders in one place ensures every glass surface in the app feels the
/// same — otherwise glass tends to look inconsistent across screens.
class GlassTokens {
  GlassTokens._();

  static double blurSigma(GlassIntensity intensity) {
    switch (intensity) {
      case GlassIntensity.light:
        return 12.0;
      case GlassIntensity.medium:
        return 20.0;
      case GlassIntensity.heavy:
        return 28.0;
    }
  }

  /// Surface fill opacity over a darker / coloured background.
  static double fillOpacity(GlassIntensity intensity, {required bool isDark}) {
    final base = switch (intensity) {
      GlassIntensity.light => 0.12,
      GlassIntensity.medium => 0.18,
      GlassIntensity.heavy => 0.26,
    };
    // Dark mode needs a touch more opacity to maintain contrast against
    // the deep background colour.
    return isDark ? base + 0.04 : base;
  }

  static double borderOpacity(GlassIntensity intensity) {
    switch (intensity) {
      case GlassIntensity.light:
        return 0.16;
      case GlassIntensity.medium:
        return 0.22;
      case GlassIntensity.heavy:
        return 0.30;
    }
  }

  static const double borderWidth = 0.8;

  /// Convenience to build a [BackdropFilter] with the right blur for an
  /// intensity. Callers wrap their content with this filter inside a
  /// [ClipRRect] so the blur is bounded to the rounded surface.
  static ImageFilter filterFor(GlassIntensity intensity) {
    final s = blurSigma(intensity);
    return ImageFilter.blur(sigmaX: s, sigmaY: s);
  }

  /// Suggested overlay tint to lay over the blurred background. Returns a
  /// translucent white for light/coloured backgrounds and a translucent
  /// black for dark backgrounds, so the glass surface reads correctly in
  /// either theme.
  static Color tintFor({
    required GlassIntensity intensity,
    required bool isDark,
    Color? customTint,
  }) {
    final opacity = fillOpacity(intensity, isDark: isDark);
    final base =
        customTint ?? (isDark ? const Color(0xFF0D1122) : Colors.white);
    return base.withValues(alpha: opacity);
  }
}
