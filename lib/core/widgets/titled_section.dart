import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/spacing.dart';

/// A labelled home/section block: a header row (small brand icon-chip +
/// title + optional trailing action) followed by [child]. Gives the home
/// screen clear, scannable grouping so features are discoverable.
class TitledSection extends StatelessWidget {
  final String title;
  final IconData? icon;

  /// Optional trailing action (e.g. "عرض الكل").
  final String? actionLabel;
  final VoidCallback? onAction;

  final Widget child;

  /// Outer padding around the whole section.
  final EdgeInsetsGeometry padding;

  const TitledSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
      Spacing.lg,
      Spacing.lg,
      Spacing.lg,
      Spacing.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isDark
                        ? cs.onSurface.withValues(alpha: 0.85)
                        : cs.primary,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
          const SizedBox(height: Spacing.md),
          child,
        ],
      ),
    );
  }
}
