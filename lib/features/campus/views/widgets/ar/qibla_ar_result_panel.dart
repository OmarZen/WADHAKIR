import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/features/campus/views/qibla_look.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';

/// Shown once the rug faces the qibla: the green confirmation, the qibla
/// angle and the distance to Makkah, what to do with a real rug, and
/// «إعادة الضبط» to start the steady step again.
class QiblaArResultPanel extends StatelessWidget {
  final double? bearing;
  final double? distanceKm;
  final VoidCallback onReset;

  const QiblaArResultPanel({
    super.key,
    required this.bearing,
    required this.distanceKm,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final success = QiblaLook.success(context);
    final accent = AppAccent.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: dark ? theme.cardColor : cs.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: success, size: 22),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    QiblaStrings.tr(
                      context,
                      'qibla.ar.aligned',
                      'السجادة الآن باتجاه القبلة',
                    ),
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: dark
                          ? success
                          : Color.lerp(success, Colors.black, 0.25),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          if (bearing != null)
            _Row(
              label: QiblaStrings.tr(context, 'qibla.ar.angle', 'زاوية القبلة'),
              value: QiblaFormat.degrees(bearing!),
              valueDirection: TextDirection.ltr,
              color: accent,
            ),
          if (distanceKm != null)
            _Row(
              label: QiblaStrings.tr(
                context,
                'qibla.ar.distance',
                'المسافة إلى مكة المكرمة',
              ),
              value: QiblaStrings.fill(
                QiblaStrings.tr(context, 'qibla.map.km', '{n} كم'),
                {'n': QiblaFormat.km(distanceKm!)},
              ),
              color: cs.onSurface,
            ),
          const SizedBox(height: Spacing.sm),
          Text(
            QiblaStrings.tr(
              context,
              'qibla.ar.place_rug',
              'ضع سجادتك على الأرض بموازاة السجادة الافتراضية',
            ),
            style: QiblaLook.body(
              context,
            ).copyWith(color: QiblaLook.muted(context), fontSize: 14),
          ),
          const SizedBox(height: Spacing.md),
          FButton(
            variant: FButtonVariant.outline,
            onPress: onReset,
            prefix: const Icon(Icons.restart_alt_rounded),
            child: QiblaButtonLabel(
              QiblaStrings.tr(context, 'qibla.ar.reset', 'إعادة الضبط'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final TextDirection? valueDirection;
  final Color color;

  const _Row({
    required this.label,
    required this.value,
    required this.color,
    this.valueDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 14,
                color: QiblaLook.muted(context),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            value,
            textDirection: valueDirection,
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
