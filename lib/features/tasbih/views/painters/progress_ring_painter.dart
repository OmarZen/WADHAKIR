import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// The tap mode's ring: a faint track with the round's progress drawn over it.
///
/// The arc always runs clockwise from twelve o'clock, in Arabic as in English.
/// A clock face is not text and does not mirror; an arc that ran the other way
/// in RTL would read as counting down.
class ProgressRingPainter extends CustomPainter {
  ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
    this.strokeWidth = 8,
    this.glow = 0,
  });

  /// 0..1.
  final double progress;
  final Color trackColor;
  final Color arcColor;
  final double strokeWidth;

  /// 0..1: the soft halo a finished round holds for a moment.
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - strokeWidth) / 2 - 6;
    if (radius <= 0) return;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = arcColor;
    if (glow > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 2
          ..color = arcColor.withValues(alpha: 0.35 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(ProgressRingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.arcColor != arcColor ||
      old.strokeWidth != strokeWidth ||
      old.glow != glow;
}
