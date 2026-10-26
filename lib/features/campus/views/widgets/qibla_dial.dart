import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/core/geo/qibla_geodesy.dart';
import 'package:wadhakir/features/campus/views/qibla_look.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_dial_painter.dart';

/// What sits fixed at the top of the dial, i.e. what the user points the top
/// of the phone at.
enum QiblaDialTop {
  /// The compass: an index mark. The phone itself is the reference.
  heading,

  /// The Shadow tab: a thin needle to line up with a stick's shadow.
  shadowNeedle,

  /// The Sun/Moon tab: the sun's mark.
  sun,

  /// The Sun/Moon tab: the moon's mark.
  moon,
}

/// The dial shared by the Compass, Shadow and Sun/Moon tabs.
///
/// One rule drives all three: whatever the user lines the top of the phone up
/// with (where it points, a shadow, the sun) is [referenceBearing], so the
/// card turns by −reference and the arrow by `qibla − reference`. The old
/// dial turned by +heading and started its labels at 3 o'clock, which put
/// north 90° off and turned it the wrong way.
///
/// The card (ticks and labels) and the arrow are painted once and turned by
/// transforms, so a live heading only re-composites; the arc, the one piece
/// that changes shape, is the only repaint.
class QiblaDial extends StatelessWidget {
  final double size;

  /// Degrees from true north of whatever the top of the dial stands for.
  final double referenceBearing;

  /// Degrees from true north; null hides the arrow, the arc and the Kaaba.
  final double? qiblaBearing;

  final QiblaDialTop top;

  /// Facing the qibla (Compass only): the arrow takes the accent and the
  /// screen's one glow, and the arc disappears.
  final bool aligned;

  /// On the Shadow and Sun/Moon tabs the arrow IS the answer, so it is filled
  /// in the accent from the start (without the glow, which belongs to
  /// "aligned").
  final bool answerArrow;

  /// The reading cannot be trusted (low accuracy, no reading yet, the sun
  /// below the horizon): the whole dial fades to 30%.
  final bool muted;

  const QiblaDial({
    super.key,
    required this.size,
    required this.referenceBearing,
    required this.qiblaBearing,
    this.top = QiblaDialTop.heading,
    this.aligned = false,
    this.answerArrow = false,
    this.muted = false,
  });

  /// The dial size for the space a tab has: as wide as fits, never huge on a
  /// tablet, never so small the labels collide.
  ///
  /// With [maxHeight], it also leaves room for the readouts under the dial
  /// (the number, the guidance line and the status chip), so on a standard
  /// phone the chip is on screen without scrolling. Width alone made the dial
  /// as tall as the screen allowed and pushed the chip below the fold.
  static double sizeFor(double maxWidth, {double? maxHeight}) {
    var size = maxWidth - 2 * Spacing.xl;
    if (maxHeight != null && maxHeight.isFinite) {
      size = math.min(size, maxHeight - _readoutsHeight);
    }
    return size.clamp(200.0, 320.0);
  }

  /// Roughly what the tabs stack under and above the dial.
  static const double _readoutsHeight = 280;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final accent = AppAccent.of(context);
    final labelScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.25);
    final geometry = QiblaDialGeometry(size, labelScale);

    final bearing = qiblaBearing;
    final delta = bearing == null
        ? null
        : QiblaGeodesy.signedDelta(bearing, referenceBearing);

    final Color arrowColor;
    Color? glow;
    if (aligned) {
      arrowColor = accent;
      glow = accent.withValues(alpha: 0.35);
    } else if (answerArrow) {
      arrowColor = accent;
    } else {
      arrowColor = cs.onSurface.withValues(alpha: 0.55);
    }

    final cardinals = [
      QiblaStrings.tr(context, 'qibla.cardinal.n', 'ش'),
      QiblaStrings.tr(context, 'qibla.cardinal.e', 'ق'),
      QiblaStrings.tr(context, 'qibla.cardinal.s', 'ج'),
      QiblaStrings.tr(context, 'qibla.cardinal.w', 'غ'),
    ];

    final dial = SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: QiblaDialDiskPainter(
              geometry: geometry,
              fill: dark ? theme.cardColor : cs.surface,
              rim: cs.onSurface.withValues(alpha: 0.08),
              shadow: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
              indexColor: top == QiblaDialTop.heading
                  ? (aligned ? accent : cs.onSurface.withValues(alpha: 0.7))
                  : null,
            ),
          ),
          Transform.rotate(
            angle: -referenceBearing * math.pi / 180,
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.square(size),
                painter: QiblaDialFacePainter(
                  geometry: geometry,
                  cardinals: cardinals,
                  tick: cs.onSurface.withValues(alpha: 0.45),
                  label: cs.onSurface.withValues(alpha: 0.6),
                  cardinal: cs.onSurface.withValues(alpha: 0.85),
                  north: accent,
                ),
              ),
            ),
          ),
          if (delta != null && !aligned)
            CustomPaint(
              size: Size.square(size),
              painter: QiblaDialArcPainter(
                geometry: geometry,
                delta: delta,
                color: accent.withValues(alpha: 0.45),
              ),
            ),
          if (top == QiblaDialTop.shadowNeedle)
            CustomPaint(
              size: Size.square(size),
              painter: QiblaDialNeedlePainter(
                geometry: geometry,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          if (delta != null)
            Transform.rotate(
              angle: delta * math.pi / 180,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.square(size),
                  painter: QiblaDialArrowPainter(
                    geometry: geometry,
                    color: arrowColor,
                    glow: glow,
                  ),
                ),
              ),
            ),
          if (top == QiblaDialTop.sun || top == QiblaDialTop.moon)
            _OnRing(
              degrees: 0,
              radius: geometry.rimRadius,
              child: _DialChip(
                size: geometry.chipSize,
                icon: top == QiblaDialTop.sun
                    ? HugeIcons.strokeRoundedSun03
                    : HugeIcons.strokeRoundedMoon02,
                color: top == QiblaDialTop.sun
                    ? QiblaLook.warning(context)
                    : accent,
              ),
            ),
          if (delta != null)
            _OnRing(
              degrees: delta,
              radius: geometry.rimRadius,
              child: _DialChip(
                size: geometry.chipSize,
                icon: HugeIcons.strokeRoundedKaaba01,
                color: cs.onSurface.withValues(alpha: 0.85),
                border: accent.withValues(alpha: aligned ? 0.6 : 0.16),
              ),
            ),
        ],
      ),
    );

    return RepaintBoundary(
      child: Opacity(opacity: muted ? 0.3 : 1, child: dial),
    );
  }
}

/// Places [child]'s centre on the ring at [degrees] clockwise from the top,
/// upright: the Kaaba never stands on its head.
class _OnRing extends StatelessWidget {
  final double degrees;
  final double radius;
  final Widget child;

  const _OnRing({
    required this.degrees,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final a = degrees * math.pi / 180;
    return Transform.translate(
      offset: Offset(math.sin(a) * radius, -math.cos(a) * radius),
      child: child,
    );
  }
}

class _DialChip extends StatelessWidget {
  final double size;
  final List<List<dynamic>> icon;
  final Color color;
  final Color? border;

  const _DialChip({
    required this.size,
    required this.icon,
    required this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? theme.cardColor : cs.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: border ?? cs.onSurface.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: HugeIcon(icon: icon, color: color, size: size * 0.58),
    );
  }
}
