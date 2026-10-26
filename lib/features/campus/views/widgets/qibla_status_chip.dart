import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/views/qibla_look.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';

/// A status pill: a dot (or icon) and a label on a 12% tint of [color], the
/// app's status-chip vocabulary (DESIGN.md, Chips & Badges).
class QiblaStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  /// Read out when it changes (the green "facing the qibla" chip).
  final bool liveRegion;

  const QiblaStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.liveRegion = false,
  });

  /// The green «أنت الآن في اتجاه القبلة».
  factory QiblaStatusChip.aligned(BuildContext context) => QiblaStatusChip(
    label: QiblaStrings.tr(
      context,
      'qibla.compass.aligned',
      'أنت الآن في اتجاه القبلة',
    ),
    color: QiblaLook.success(context),
    icon: Icons.check_circle_rounded,
    liveRegion: true,
  );

  /// The compass accuracy: high green, medium the brand tint, low amber,
  /// unknown neutral.
  factory QiblaStatusChip.accuracy(
    BuildContext context,
    CompassAccuracyLevel level,
  ) {
    switch (level) {
      case CompassAccuracyLevel.high:
        return QiblaStatusChip(
          label: QiblaStrings.tr(
            context,
            'qibla.accuracy.high',
            'الدقة: عالية',
          ),
          color: QiblaLook.success(context),
        );
      case CompassAccuracyLevel.medium:
        return QiblaStatusChip(
          label: QiblaStrings.tr(
            context,
            'qibla.accuracy.medium',
            'الدقة: متوسطة',
          ),
          color: AppAccent.of(context),
        );
      case CompassAccuracyLevel.low:
        return QiblaStatusChip(
          label: QiblaStrings.tr(
            context,
            'qibla.accuracy.low',
            'الدقة: منخفضة',
          ),
          color: QiblaLook.warning(context),
          icon: Icons.warning_amber_rounded,
        );
      case CompassAccuracyLevel.unknown:
        return QiblaStatusChip(
          label: QiblaStrings.tr(
            context,
            'qibla.accuracy.unknown',
            'الدقة: غير معروفة',
          ),
          color: QiblaLook.muted(context),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      liveRegion: liveRegion,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs + Spacing.xxs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: dark ? 0.2 : 0.12),
          borderRadius: Radii.pillBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 16, color: color)
            else
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            const SizedBox(width: Spacing.sm),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  // Text on a 12% tint of itself: darken it a touch in light
                  // mode so green and amber keep their contrast.
                  color: dark ? color : Color.lerp(color, Colors.black, 0.25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
