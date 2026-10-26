import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/views/qibla_look.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';

/// «وجّه الكاميرا نحو الأرض وثبّت الهاتف», with a bar that fills while the
/// phone is held still at a floor-viewing angle.
///
/// The copy is deliberately plain about what is measured: a steady tilt. It
/// does not claim to "scan" or "detect" the floor, because nothing here
/// does (there is no ARCore).
class QiblaArSteadyStep extends StatelessWidget {
  final double progress;
  final ArSteadyHint hint;

  const QiblaArSteadyStep({
    super.key,
    required this.progress,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final accent = AppAccent.of(context);

    final String line;
    switch (hint) {
      case ArSteadyHint.tiltDown:
        line = QiblaStrings.tr(
          context,
          'qibla.ar.tilt_down',
          'أمِل الهاتف نحو الأرض قليلًا',
        );
      case ArSteadyHint.tiltUp:
        line = QiblaStrings.tr(
          context,
          'qibla.ar.tilt_up',
          'ارفع الهاتف قليلًا',
        );
      case ArSteadyHint.holdStill:
        line = QiblaStrings.tr(
          context,
          'qibla.ar.hold_still',
          'ثبّت يدك قليلًا',
        );
      case ArSteadyHint.ok:
        line = QiblaStrings.tr(
          context,
          'qibla.ar.steady_progress',
          'جارٍ تثبيت القراءة…',
        );
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: (dark ? theme.cardColor : cs.surface).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: dark ? 0.22 : 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSmartPhone01,
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  QiblaStrings.tr(
                    context,
                    'qibla.ar.steady_hint',
                    'وجّه الكاميرا نحو الأرض وثبّت الهاتف',
                  ),
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Semantics(
            label: line,
            value: '${(progress * 100).round()}%',
            child: ClipRRect(
              borderRadius: Radii.pillBorder,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                color: accent,
                backgroundColor: cs.onSurface.withValues(alpha: 0.1),
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          ExcludeSemantics(
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 13,
                color: hint == ArSteadyHint.ok
                    ? QiblaLook.muted(context)
                    : QiblaLook.warning(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
