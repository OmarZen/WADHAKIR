import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Draws a stylised moon disc with realistic terminator (the day/night line)
/// based on a phase fraction. Pure CustomPainter — no images required, so
/// the calendar stays light and crisp at any size.
///
/// Set [animated] for a subtle breathing scale + slow rotation on the lit
/// surface, used by the calendar hero. Calendar grid cells leave it off so
/// scrolling stays cheap.
class MoonDisc extends StatefulWidget {
  /// Size in logical pixels (diameter of the moon disc).
  final double size;

  /// 0.0 = new moon, 0.5 = full moon, 1.0 = new moon again.
  final double phaseFraction;

  /// 0.0..1.0 fraction of disc illuminated. Used for visual contrast.
  final double illumination;

  /// Optional texture-style speckles to fake craters on larger sizes.
  final bool showCraters;

  /// When true, the disc breathes (scale 1.0 ↔ 1.03) and the lit surface
  /// gradient slowly drifts to give a subtle 3D feel.
  final bool animated;

  const MoonDisc({
    super.key,
    required this.size,
    required this.phaseFraction,
    required this.illumination,
    this.showCraters = false,
    this.animated = false,
  });

  @override
  State<MoonDisc> createState() => _MoonDiscState();
}

class _MoonDiscState extends State<MoonDisc> with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    );
    if (widget.animated) {
      _breathController.repeat(reverse: true);
      _rotateController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MoonDisc old) {
    super.didUpdateWidget(old);
    if (widget.animated && !_breathController.isAnimating) {
      _breathController.repeat(reverse: true);
      _rotateController.repeat();
    } else if (!widget.animated && _breathController.isAnimating) {
      _breathController.stop();
      _rotateController.stop();
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animated) {
      return CustomPaint(
        size: Size.square(widget.size),
        painter: _MoonPainter(
          phaseFraction: widget.phaseFraction,
          illumination: widget.illumination,
          showCraters: widget.showCraters,
          highlightDrift: 0,
        ),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_breathController, _rotateController]),
      builder: (context, _) {
        final breath = Curves.easeInOut.transform(_breathController.value);
        final scale = 1.0 + (breath * 0.03);
        return Transform.scale(
          scale: scale,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _MoonPainter(
              phaseFraction: widget.phaseFraction,
              illumination: widget.illumination,
              showCraters: widget.showCraters,
              highlightDrift: _rotateController.value,
            ),
          ),
        );
      },
    );
  }
}

class _MoonPainter extends CustomPainter {
  final double phaseFraction;
  final double illumination;
  final bool showCraters;

  /// 0..1 drift fraction used to slowly rotate the radial highlight on the
  /// lit surface, faking a "rolling" 3D moon.
  final double highlightDrift;

  _MoonPainter({
    required this.phaseFraction,
    required this.illumination,
    required this.showCraters,
    required this.highlightDrift,
  });

  // App-themed shadow colours: deep variant of the primary blue keeps the
  // moon disc on-brand instead of pure black.
  static const Color _shadowOuter = Color(0xFF1B2A45);
  static const Color _shadowInner = Color(0xFF0E1830);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final radius = math.min(w, h) / 2;
    final center = Offset(w / 2, h / 2);

    // Subtle outer glow ring so the moon reads against any background.
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 1.05, glowPaint);

    // Shadow side using the app's primary-blue family rather than black.
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: const [_shadowOuter, _shadowInner],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shadowPaint);

    // Lit portion: an ellipse intersected with the disc gives the terminator
    // curve. The horizontal radius of the ellipse goes from -radius (new) to
    // +radius (full) and back, with a sign change at half-cycle for the
    // illuminated side switch.
    final p = phaseFraction;
    final double cosPhase = math.cos(2 * math.pi * p);
    final bool lightOnRight = p <= 0.5;
    final double terminatorRx = radius * cosPhase.abs();

    // Animate the radial highlight position to simulate a slow rotation.
    final highlightAngle = 2 * math.pi * highlightDrift;
    final highlightOffset = Offset(
      math.cos(highlightAngle) * 0.15,
      math.sin(highlightAngle) * 0.08 - 0.2,
    );
    final litAlignment = Alignment(
      (lightOnRight ? 0.35 : -0.35) + highlightOffset.dx * 0.2,
      highlightOffset.dy,
    );

    final litPaint = Paint()
      ..shader = RadialGradient(
        center: litAlignment,
        radius: 0.85,
        colors: const [Color(0xFFF5F1E1), Color(0xFFE8E1C7), Color(0xFFC8C0A5)],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    if (p < 0.5) {
      // Waxing: lit area is on the right.
      if (illumination <= 0.5) {
        canvas.drawPath(_rightHalfPath(center, radius), litPaint);
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: 2 * terminatorRx,
            height: 2 * radius,
          ),
          Paint()..blendMode = BlendMode.clear,
        );
      } else {
        canvas.drawPath(_rightHalfPath(center, radius), litPaint);
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: 2 * terminatorRx,
            height: 2 * radius,
          ),
          litPaint,
        );
      }
    } else {
      // Waning: lit area is on the left.
      if (illumination <= 0.5) {
        canvas.drawPath(_leftHalfPath(center, radius), litPaint);
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: 2 * terminatorRx,
            height: 2 * radius,
          ),
          Paint()..blendMode = BlendMode.clear,
        );
      } else {
        canvas.drawPath(_leftHalfPath(center, radius), litPaint);
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: 2 * terminatorRx,
            height: 2 * radius,
          ),
          litPaint,
        );
      }
    }
    canvas.restore();

    // Re-draw outline so the disc edge stays crisp after the clear-blend.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, outline);

    if (showCraters && radius > 40) {
      _drawCraters(canvas, center, radius);
    }
  }

  Path _rightHalfPath(Offset c, double r) {
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..arcToPoint(
        Offset(c.dx, c.dy + r),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..close();
  }

  Path _leftHalfPath(Offset c, double r) {
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..arcToPoint(
        Offset(c.dx, c.dy + r),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..close();
  }

  void _drawCraters(Canvas canvas, Offset center, double radius) {
    // Deterministic crater pattern — looks better than random and lets the
    // same moon image render identically across rebuilds.
    final cratersPaint = Paint()
      ..color = const Color(0xFFB5AE92).withValues(alpha: 0.45);
    final craters = const [
      [0.20, -0.25, 0.10],
      [-0.18, 0.08, 0.08],
      [0.30, 0.30, 0.06],
      [-0.10, -0.45, 0.05],
      [0.05, 0.40, 0.07],
      [-0.45, -0.15, 0.05],
    ];
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    for (final c in craters) {
      canvas.drawCircle(
        Offset(center.dx + c[0] * radius, center.dy + c[1] * radius),
        c[2] * radius,
        cratersPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MoonPainter old) =>
      old.phaseFraction != phaseFraction ||
      old.illumination != illumination ||
      old.showCraters != showCraters ||
      old.highlightDrift != highlightDrift;
}
