import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/qibla_model.dart';

class QiblaCompassWidget extends StatelessWidget {
  final QiblaModel qiblaModel;

  const QiblaCompassWidget({
    super.key,
    required this.qiblaModel,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the angle to rotate the compass
    // Subtract compass direction from Qibla direction to get the relative angle
    double compassAngle = (qiblaModel.compassDirection) * (pi / 180);
    double qiblaAngle =
        (qiblaModel.qiblaDirection - qiblaModel.compassDirection) * (pi / 180);
    final size = MediaQuery.of(context).size;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer compass circle
            Container(
              width: size.width * 0.65,
              height: size.width * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  width: 8,
                ),
              ),
              child: Transform.rotate(
                angle: compassAngle,
                child: CustomPaint(
                  painter: CompassPainter(
                    primaryColor: Theme.of(context).colorScheme.primary,
                    secondaryColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),

            // Qibla arrow indicator
            Transform.rotate(
              angle: qiblaAngle,
              child: Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Qibla arrow
                    Icon(
                      Icons.mosque_rounded,
                      size: size.width * 0.1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CompassPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  CompassPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint mainLinePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint secondaryLinePaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final Paint tertiaryLinePaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = min(centerX, centerY) - 10;

    // Draw cardinal directions
    for (int i = 0; i < 360; i += 90) {
      final double angle = i * (pi / 180);
      final double startX = centerX + (radius - 40) * cos(angle);
      final double startY = centerY + (radius - 40) * sin(angle);
      final double endX = centerX + radius * cos(angle);
      final double endY = centerY + radius * sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        mainLinePaint,
      );

      // Draw cardinal direction labels
      String directionText = '';
      if (i == 0) {
        directionText = 'N';
      } else if (i == 90) {
        directionText = 'E';
      } else if (i == 180) {
        directionText = 'S';
      } else if (i == 270) {
        directionText = 'W';
      }

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: directionText,
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: size.width * 0.1,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          centerX + (radius - 70) * cos(angle) - textPainter.width / 2,
          centerY + (radius - 70) * sin(angle) - textPainter.height / 2,
        ),
      );
    }

    // Draw subcardinal directions
    for (int i = 45; i < 360; i += 90) {
      final double angle = i * (pi / 180);
      final double startX = centerX + (radius - 30) * cos(angle);
      final double startY = centerY + (radius - 30) * sin(angle);
      final double endX = centerX + radius * cos(angle);
      final double endY = centerY + radius * sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        secondaryLinePaint,
      );
    }

    // Draw minor tick marks (15°)
    for (int i = 0; i < 360; i += 15) {
      // Skip the major and subcardinal directions
      if (i % 45 != 0) {
        final double angle = i * (pi / 180);
        final double startX = centerX + (radius - 20) * cos(angle);
        final double startY = centerY + (radius - 20) * sin(angle);
        final double endX = centerX + radius * cos(angle);
        final double endY = centerY + radius * sin(angle);

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          tertiaryLinePaint,
        );
      }
    }

    // Outer circle
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      tertiaryLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
