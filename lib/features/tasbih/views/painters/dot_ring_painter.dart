import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// The ring mode's circle of dots, one per tasbiha.
///
/// A target outside 12..100 is drawn with that many dots, each standing for
/// a share of the round: fewer than twelve looks like a broken clock, more
/// than a hundred turns into a solid line on a phone.
class DotRingPainter extends CustomPainter {
  DotRingPainter({
    required this.count,
    required this.target,
    required this.countedColor,
    required this.currentColor,
    required this.restColor,
    this.holdingFull = false,
  });

  final int count;
  final int target;
  final Color countedColor;
  final Color currentColor;
  final Color restColor;

  /// A finished round: every dot lit for a moment.
  final bool holdingFull;

  static const int minDots = 12;
  static const int maxDots = 100;

  static int dotsFor(int target) => target.clamp(minDots, maxDots);

  /// How many dots [count] fills.
  static int filledFor(int count, int target) {
    final dots = dotsFor(target);
    if (target <= 0) return 0;
    return (count * dots / target).floor().clamp(0, dots);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dots = dotsFor(target);
    final filled = holdingFull ? dots : filledFor(count, target);
    final outer = size.shortestSide / 2;
    final dotRadius = (2 * math.pi * outer / dots * 0.32).clamp(3.0, 7.0);
    // Room for the current dot's halo.
    final radius = outer - dotRadius * 2.2;
    if (radius <= 0) return;
    final center = size.center(Offset.zero);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < dots; i++) {
      // Clockwise from twelve o'clock in both directions; see
      // ProgressRingPainter.
      final angle = -math.pi / 2 + 2 * math.pi * i / dots;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i < filled) {
        paint.color = holdingFull ? currentColor : countedColor;
        canvas.drawCircle(p, dotRadius, paint);
      } else if (i == filled) {
        // The one lit element on the surface.
        canvas.drawCircle(
          p,
          dotRadius * 2,
          Paint()
            ..color = currentColor.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        paint.color = currentColor;
        canvas.drawCircle(p, dotRadius * 1.35, paint);
      } else {
        paint.color = restColor;
        canvas.drawCircle(p, dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotRingPainter old) =>
      old.count != count ||
      old.target != target ||
      old.countedColor != countedColor ||
      old.currentColor != currentColor ||
      old.restColor != restColor ||
      old.holdingFull != holdingFull;
}
