import 'package:flutter/material.dart';

import '../design/design_tokens.dart';

/// A reusable frosted-glass surface. Wraps a [BackdropFilter] with a
/// rounded clip, a translucent tint, and a subtle border so glass surfaces
/// across the app look identical.
///
/// Prefer this over hand-rolled `Container + boxShadow` panels — those tend
/// to drift in opacity, blur, and border thickness across screens.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final GlassIntensity intensity;
  final double radius;
  final Color? tint;
  final BoxBorder? border;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.intensity = GlassIntensity.medium,
    this.radius = Radii.md,
    this.tint,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tintColor = GlassTokens.tintFor(
      intensity: intensity,
      isDark: isDark,
      customTint: tint,
    );
    final borderColor = (isDark ? Colors.white : Colors.white).withValues(
      alpha: GlassTokens.borderOpacity(intensity),
    );

    Widget surface = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: GlassTokens.filterFor(intensity),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tintColor,
            borderRadius: BorderRadius.circular(radius),
            border:
                border ??
                Border.all(color: borderColor, width: GlassTokens.borderWidth),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: surface,
        ),
      );
    }

    if (margin != null) {
      return Padding(padding: margin!, child: surface);
    }
    return surface;
  }
}
