import 'dart:math' as math;
import 'package:flutter/material.dart';

class IslamicPatternPainter extends CustomPainter {
  final Color color;
  final double gridSize;

  IslamicPatternPainter({required this.color, this.gridSize = 40.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw star pattern grid
    final horizontalCount = (size.width / gridSize).ceil() + 1;
    final verticalCount = (size.height / gridSize).ceil() + 1;

    for (int i = 0; i < horizontalCount; i++) {
      for (int j = 0; j < verticalCount; j++) {
        final centerX = i * gridSize;
        final centerY = j * gridSize;

        // Draw geometric patterns at each grid point
        if ((i + j) % 2 == 0) {
          _drawOctagon(canvas, paint, centerX, centerY, gridSize * 0.4);
        } else {
          _drawStar(canvas, paint, centerX, centerY, gridSize * 0.4);
        }
      }
    }
  }

  void _drawStar(
    Canvas canvas,
    Paint paint,
    double cx,
    double cy,
    double radius,
  ) {
    final starPath = Path();
    final vertices = 8; // 8-pointed star

    for (int i = 0; i < vertices * 2; i++) {
      final angle = i * math.pi / vertices;
      final r = i.isEven ? radius : radius * 0.4;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);

      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }

    starPath.close();
    canvas.drawPath(starPath, paint);
  }

  void _drawOctagon(
    Canvas canvas,
    Paint paint,
    double cx,
    double cy,
    double radius,
  ) {
    final path = Path();
    final sides = 8;

    for (int i = 0; i < sides; i++) {
      final angle = i * 2 * math.pi / sides;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);

    // Inner design
    final innerRadius = radius * 0.6;
    final innerPath = Path();

    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) + (math.pi / sides);
      final x = cx + innerRadius * math.cos(angle);
      final y = cy + innerRadius * math.sin(angle);

      if (i == 0) {
        innerPath.moveTo(x, y);
      } else {
        innerPath.lineTo(x, y);
      }
    }

    innerPath.close();
    canvas.drawPath(innerPath, paint);
  }

  @override
  bool shouldRepaint(IslamicPatternPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.gridSize != gridSize;
  }
}
