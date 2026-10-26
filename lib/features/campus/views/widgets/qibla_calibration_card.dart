import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/views/qibla_look.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';

/// «معايرة البوصلة»: shown by the compass tab only when the magnetometer
/// itself reports low accuracy (see `QiblaState.showCalibration`).
///
/// It shows the figure-8 motion rather than describing it, and a three-step
/// level instead of a percentage: Android only reports three calibration
/// levels, and a number like "62%" would be invented precision.
class QiblaCalibrationCard extends StatefulWidget {
  final CompassAccuracyLevel level;
  final VoidCallback onSkip;

  const QiblaCalibrationCard({
    super.key,
    required this.level,
    required this.onSkip,
  });

  @override
  State<QiblaCalibrationCard> createState() => _QiblaCalibrationCardState();
}

class _QiblaCalibrationCardState extends State<QiblaCalibrationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: the path is drawn with the phone resting on it; the
    // card still explains everything without moving.
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
      _motion.value = 0.125;
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = AppAccent.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: QiblaLook.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  QiblaStrings.tr(
                    context,
                    'qibla.calibration.title',
                    'معايرة البوصلة',
                  ),
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              _LevelBar(level: widget.level),
            ],
          ),
          const SizedBox(height: Spacing.md),
          SizedBox(
            height: 96,
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _motion,
                builder: (context, _) => CustomPaint(
                  painter: _FigureEightPainter(
                    t: _motion.value,
                    color: accent.withValues(alpha: 0.5),
                  ),
                  child: _PhoneOnPath(t: _motion.value, color: accent),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            QiblaStrings.tr(
              context,
              'qibla.calibration.body',
              'حرّك هاتفك في الهواء برسم الرقم 8 عدة مرات، بعيدًا عن المعادن والأجهزة الكهربائية.',
            ),
            textAlign: TextAlign.center,
            style: QiblaLook.body(context),
          ),
          const SizedBox(height: Spacing.md),
          FButton(
            variant: FButtonVariant.ghost,
            onPress: widget.onSkip,
            child: QiblaButtonLabel(
              QiblaStrings.tr(
                context,
                'qibla.calibration.skip',
                'تخطي المعايرة',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A point on a figure 8 (Bernoulli's lemniscate) of half-width [a], for
/// [t] in 0..1 once round.
Offset _lemniscate(double t, double a) {
  final th = t * 2 * math.pi;
  final s = math.sin(th);
  final d = 1 + s * s;
  return Offset(a * math.cos(th) / d, a * s * math.cos(th) / d);
}

class _FigureEightPainter extends CustomPainter {
  final double t;
  final Color color;

  const _FigureEightPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final a = math.min(size.width * 0.36, size.height * 1.2);
    final path = Path();
    for (var i = 0; i <= 120; i++) {
      final p = c + _lemniscate(i / 120, a);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    // Dashed: the path is the motion to make, not an object on the screen.
    for (final PathMetric metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_FigureEightPainter old) =>
      old.color != color || old.t != t;
}

class _PhoneOnPath extends StatelessWidget {
  final double t;
  final Color color;

  const _PhoneOnPath({required this.t, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final a = math.min(size.width * 0.36, size.height * 1.2);
        final p = _lemniscate(t, a);
        return Center(
          child: Transform.translate(
            offset: p,
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedSmartPhone01,
              color: color,
              size: 26,
            ),
          ),
        );
      },
    );
  }
}

/// Three segments: one amber (low), two in the accent (medium), three green
/// (high); none lit when the phone has not said.
class _LevelBar extends StatelessWidget {
  final CompassAccuracyLevel level;

  const _LevelBar({required this.level});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final int lit;
    final Color color;
    switch (level) {
      case CompassAccuracyLevel.high:
        lit = 3;
        color = QiblaLook.success(context);
      case CompassAccuracyLevel.medium:
        lit = 2;
        color = AppAccent.of(context);
      case CompassAccuracyLevel.low:
        lit = 1;
        color = QiblaLook.warning(context);
      case CompassAccuracyLevel.unknown:
        lit = 0;
        color = cs.onSurface;
    }
    return Semantics(
      label: QiblaStrings.tr(
        context,
        'qibla.calibration.level',
        'مستوى المعايرة',
      ),
      value: '$lit/3',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: Spacing.xs),
            Container(
              width: 18,
              height: 6,
              decoration: BoxDecoration(
                color: i < lit ? color : cs.onSurface.withValues(alpha: 0.12),
                borderRadius: Radii.pillBorder,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
