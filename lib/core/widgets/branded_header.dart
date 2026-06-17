import 'package:flutter/material.dart';

/// Branded gradient header used across screens in place of a Material AppBar.
/// Rounded-bottom, brand-primary gradient, white title + a circular back
/// affordance — mirrors the welcome section at a smaller scale.
class BrandedHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const BrandedHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topInset + 14, 16, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            cs.primary,
            Color.alphaBlend(const Color(0x33000000), cs.primary),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        // Soft branded elevation so the header separates cleanly from the
        // scrolling content beneath it (consistent in light & dark mode).
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.maybePop(context),
            color: cs.onPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
