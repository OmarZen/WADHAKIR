import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Unified, minimalistic tile used for every card in the home feature grid.
///
/// Vertical layout — a tinted circular icon chip on top, label centered
/// below — so a 3-column grid stays scannable and features are easy to spot.
/// Built on forui's [FTappable] for consistent press semantics and styled
/// from the app's [ColorScheme] so every tile shares one calm, on-brand look.
class FeatureGridCard extends StatelessWidget {
  /// Leading icon shown in the tinted circular chip. Optional when
  /// [iconBuilder] is supplied (e.g. for non-[IconData] glyphs like HugeIcons).
  final IconData? icon;

  /// Builds a custom icon when the glyph isn't a plain [IconData] (e.g. a
  /// `HugeIcon`). Receives the resolved tint [color] and [size] so it matches
  /// the standard [Icon] rendering. Takes precedence over [icon].
  final Widget Function(Color color, double size)? iconBuilder;

  /// Card label.
  final String label;

  /// Tap handler.
  final VoidCallback onTap;

  /// Optional trailing widget (e.g. a progress badge) shown as a corner badge.
  final Widget? trailing;

  const FeatureGridCard({
    super.key,
    this.icon,
    this.iconBuilder,
    required this.label,
    required this.onTap,
    this.trailing,
  }) : assert(
         icon != null || iconBuilder != null,
         'Provide either icon or iconBuilder',
       );

  /// Height of the icon chip: a 24pt glyph inside 12pt of padding on each side.
  /// Fixed — the chip does not grow with the text scale, only the label does.
  static const double _chipExtent = 48;

  /// Gap between the chip and the label.
  static const double _chipToLabel = 10;

  /// The card's own vertical padding, top and bottom.
  static const double _verticalPadding = 28;

  /// Leading applied to the label.
  static const double _labelHeight = 1.2;

  /// The label is allowed two lines before it ellipsizes.
  static const int _labelLines = 2;

  /// The height this card needs at the caller's current text scale.
  ///
  /// Exposed because the grid above it has to know. A fixed
  /// `childAspectRatio` derives height from width, which is fine until the
  /// reader turns the text up: the label is the only part that grows, the cell
  /// is not, and the tile overflows by exactly the extra leading. The grid uses
  /// this as a floor — see `more_islamic_excerpts_widget.dart`.
  static double minExtentFor(BuildContext context) {
    final theme = Theme.of(context);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final scaled = MediaQuery.textScalerOf(context).scale(fontSize);
    return _verticalPadding +
        _chipExtent +
        _chipToLabel +
        scaled * _labelHeight * _labelLines;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: isDark ? 0.22 : 0.12),
              ),
              child: Builder(
                builder: (_) {
                  final color = isDark
                      ? cs.onSurface.withValues(alpha: 0.9)
                      : cs.primary;
                  return iconBuilder?.call(color, 24) ??
                      Icon(icon, size: 24, color: color);
                },
              ),
            ),
            const SizedBox(height: _chipToLabel),
            // Flexible, not a bare Text: [minExtentFor] tells the grid how much
            // room this needs, but a caller that gives it less must lose a line
            // of label rather than paint outside the card.
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: _labelLines,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: _labelHeight,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return FTappable(
      onPress: onTap,
      child: trailing == null
          ? tile
          : Stack(
              children: [
                Positioned.fill(child: tile),
                PositionedDirectional(top: 6, end: 6, child: trailing!),
              ],
            ),
    );
  }
}
