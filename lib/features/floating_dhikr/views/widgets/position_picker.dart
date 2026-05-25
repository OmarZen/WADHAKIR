import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/design_tokens.dart';

import '../../data/floating_dhikr_settings.dart';

/// Visual picker for the overlay anchor position. Renders a small mock
/// phone with a top bar and a bottom bar — the only two anchors we expose
/// to users. Corner anchors were removed because the pill bar reads as a
/// banner; corner placement made it feel cramped against the notch /
/// gesture indicator and users couldn't tell the corner variants apart at
/// a glance.
class PositionPicker extends StatelessWidget {
  final OverlayAnchor selected;
  final ValueChanged<OverlayAnchor> onSelected;

  const PositionPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AspectRatio(
      aspectRatio: 9 / 14, // phone-shape
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.30)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        padding: const EdgeInsets.all(Spacing.sm),
        child: Column(
          children: [
            _BarSlot(
              anchor: OverlayAnchor.topBar,
              selected: selected,
              onSelected: onSelected,
            ),
            Expanded(
              child: Center(
                child: Icon(
                  Icons.smartphone_outlined,
                  size: 36,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                ),
              ),
            ),
            _BarSlot(
              anchor: OverlayAnchor.bottomBar,
              selected: selected,
              onSelected: onSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarSlot extends StatelessWidget {
  final OverlayAnchor anchor;
  final OverlayAnchor selected;
  final ValueChanged<OverlayAnchor> onSelected;

  const _BarSlot({
    required this.anchor,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selected == anchor;
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.10);
    return GestureDetector(
      onTap: () => onSelected(anchor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 24,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isSelected ? 0.85 : 0.9),
          borderRadius: BorderRadius.circular(Radii.sm),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
              : null,
        ),
        child: isSelected
            ? const Center(
                child: Icon(Icons.bubble_chart_rounded,
                    size: 14, color: Colors.white),
              )
            : null,
      ),
    );
  }
}

