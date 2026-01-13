import 'package:flutter/material.dart';
import 'package:wadhakir/core/widgets/islamic_icons.dart';
import 'dart:math' as math;

/// A collection of Islamic-themed decorations and UI elements
class IslamicDecorations {
  /// Creates a container with an Islamic pattern background
  static Widget lanternBackground({
    required Widget child,
    required BuildContext context,
    Color? backgroundColor,
    double opacity = 0.15,
  }) {
    final primaryColor =
        backgroundColor ?? Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(color: primaryColor),
          child: CustomPaint(
            painter: IslamicPatternPainter(
              color: Theme.of(context).colorScheme.onPrimary,
              opacity: opacity,
            ),
            child: child,
          ),
        ),
        Positioned(
          top: -15,
          right: 10,
          child: Opacity(
            opacity: opacity,
            child: IslamicIcons.lanternIcon(
              size: 40,
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.5),
            ),
          ),
        ),
        Positioned(
          top: -15,
          left: 10,
          child: Opacity(
            opacity: opacity,
            child: IslamicIcons.lanternIcon(
              size: 40,
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Creates a card with Islamic-styled decorations
  static Widget islamicCard({
    required Widget child,
    required BuildContext context,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: CustomPaint(
        painter: GeometricPatternPainter(
          color: Theme.of(context).disabledColor,
          opacity: 0.05,
        ),
        child: child,
      ),
    );
  }

  /// Creates a header decoration with lanterns
  static Widget headerWithLanterns({
    required Widget child,
    required BuildContext context,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
        // Left lantern decoration
        Positioned(top: -15, left: 0, child: _buildLantern(context)),
        // Right lantern decoration
        Positioned(top: -15, right: 0, child: _buildLantern(context)),
      ],
    );
  }

  /// Builds a decorative lantern
  static Widget _buildLantern(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: IslamicIcons.lanternIcon(
        size: 40,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  /// Creates an Islamic divider with ornamental design
  static Widget islamicDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: IslamicIcons.ornamentIcon(
            size: 18,
            color: Theme.of(context).dividerColor,
          ),
        ),
        const Expanded(child: Divider(thickness: 1)),
      ],
    );
  }
}

// Custom painter for Islamic geometric patterns
class IslamicPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;

  IslamicPatternPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;

    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < rows; j++) {
        final centerX = i * spacing;
        final centerY = j * spacing;

        // Draw 8-pointed star
        final path = Path();
        const points = 8;
        const innerRadius = 6.0;
        const outerRadius = 12.0;

        for (var k = 0; k < points * 2; k++) {
          final radius = k.isEven ? outerRadius : innerRadius;
          final angle = k * math.pi / points;

          final x = centerX + math.cos(angle) * radius;
          final y = centerY + math.sin(angle) * radius;

          if (k == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }

        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(IslamicPatternPainter oldDelegate) =>
      color != oldDelegate.color || opacity != oldDelegate.opacity;
}

// Custom painter for subtle geometric patterns
class GeometricPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;

  GeometricPatternPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 20.0;
    final cols = (size.width / spacing).ceil();
    final rows = (size.height / spacing).ceil();

    // Draw horizontal lines
    for (var i = 0; i <= rows; i++) {
      canvas.drawLine(
        Offset(0, i * spacing),
        Offset(size.width, i * spacing),
        paint,
      );
    }

    // Draw vertical lines
    for (var i = 0; i <= cols; i++) {
      canvas.drawLine(
        Offset(i * spacing, 0),
        Offset(i * spacing, size.height),
        paint,
      );
    }

    // Draw diamonds at intersections
    paint.style = PaintingStyle.fill;
    for (var i = 0; i <= cols; i++) {
      for (var j = 0; j <= rows; j++) {
        final centerX = i * spacing;
        final centerY = j * spacing;

        final path = Path();
        const size = 3.0;

        path.moveTo(centerX, centerY - size);
        path.lineTo(centerX + size, centerY);
        path.lineTo(centerX, centerY + size);
        path.lineTo(centerX - size, centerY);
        path.close();

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(GeometricPatternPainter oldDelegate) =>
      color != oldDelegate.color || opacity != oldDelegate.opacity;
}
