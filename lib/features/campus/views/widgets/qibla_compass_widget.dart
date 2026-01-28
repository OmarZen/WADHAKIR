import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/qibla_model.dart';

class QiblaCompassWidget extends StatefulWidget {
  final QiblaModel qiblaModel;
  final bool isAligned;

  const QiblaCompassWidget({
    super.key,
    required this.qiblaModel,
    this.isAligned = false,
  });

  @override
  State<QiblaCompassWidget> createState() => _QiblaCompassWidgetState();
}

class _QiblaCompassWidgetState extends State<QiblaCompassWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the angle to rotate the compass
    // Subtract compass direction from Qibla direction to get the relative angle
    double compassAngle = (widget.qiblaModel.compassDirection) * (pi / 180);
    double qiblaAngle = (widget.qiblaModel.qiblaDirection -
            widget.qiblaModel.compassDirection) *
        (pi / 180);
    final size = MediaQuery.of(context).size;

    // Colors based on alignment
    final primaryColor = widget.isAligned
        ? const Color(0xFF27AE60) // App theme green when aligned
        : Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Animated glow effect when aligned
            if (widget.isAligned)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: size.width *
                        0.65 *
                        (0.98 + _pulseAnimation.value * 0.02),
                    height: size.width *
                        0.65 *
                        (0.98 + _pulseAnimation.value * 0.02),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Outer compass circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: size.width * 0.65,
              height: size.width * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.4),
                  width: 4,
                ),
              ),
              child: Transform.rotate(
                angle: compassAngle,
                child: CustomPaint(
                  painter: CompassPainter(
                    primaryColor: primaryColor,
                    secondaryColor: Theme.of(context).colorScheme.secondary,
                    isAligned: widget.isAligned,
                  ),
                ),
              ),
            ),

            // Qibla arrow indicator - simplified
            Transform.rotate(
              angle: qiblaAngle,
              child: Icon(
                Icons.mosque_rounded,
                size: size.width * 0.08, // Smaller icon
                color: primaryColor,
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
  final bool isAligned;

  CompassPainter({
    required this.primaryColor,
    required this.secondaryColor,
    this.isAligned = false,
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
    canvas.drawCircle(Offset(centerX, centerY), radius, tertiaryLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
