import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Unified, minimalistic tile used for every card in the home feature grid.
///
/// Vertical layout — a tinted circular icon chip on top, label centered
/// below — so a 3-column grid stays scannable and features are easy to spot.
/// Built on forui's [FTappable] for consistent press semantics and styled
/// from the app's [ColorScheme] so every tile shares one calm, on-brand look.
class FeatureGridCard extends StatelessWidget {
  /// Leading icon shown in the tinted circular chip.
  final IconData icon;

  /// Card label.
  final String label;

  /// Tap handler.
  final VoidCallback onTap;

  /// Optional trailing widget (e.g. a progress badge) shown as a corner badge.
  final Widget? trailing;

  const FeatureGridCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

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
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: isDark ? 0.22 : 0.12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isDark
                    ? cs.onSurface.withValues(alpha: 0.9)
                    : cs.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
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
