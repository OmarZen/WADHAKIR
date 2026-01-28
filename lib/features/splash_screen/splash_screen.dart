import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import 'package:wadhakir/core/widgets/scaffold_with_nav_bar.dart';

/// Wadhakir animated splash screen
class WadhakirSplashScreen extends StatefulWidget {
  const WadhakirSplashScreen({super.key});

  @override
  State<WadhakirSplashScreen> createState() => _WadhakirSplashScreenState();
}

class _WadhakirSplashScreenState extends State<WadhakirSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Phase animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _backgroundExpand;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Logo fade in and scale (0-800ms)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.5,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // Text fade in (600-1400ms)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.24, 0.56, curve: Curves.easeIn),
      ),
    );

    // Background expand to full screen (1600-2500ms)
    _backgroundExpand = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.64, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    // Start animation after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _controller.forward();
    });

    // Navigate to main app after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Remove this after testing - Loop animation for testing
        // Future.delayed(const Duration(milliseconds: 1000), () {
        //   if (mounted) {
        //     _controller.reset();
        //     _controller.forward();
        //   }
        // });

        // Uncomment this when ready to enable navigation
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ScaffoldWithNavBar(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeIn,
                    ),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Animated background
              _buildAnimatedBackground(size, theme, isDark),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated logo with circle and crescent
                    _buildAnimatedLogo(),

                    // Tagline
                    _buildTagline(theme, l10n!),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size, ThemeData theme, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary, // Primary blue
            isDark ? Colors.black : theme.colorScheme.onSurface,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated waves in background
          CustomPaint(size: size, painter: _WavesPainter(_controller.value)),

          // Expanding circle effect
          if (_backgroundExpand.value > 0)
            Center(
              child: Transform.scale(
                scale: _backgroundExpand.value * 15,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),

          // Decorative Islamic mosque pattern overlay
          Opacity(
            opacity: 0.5,
            child: CustomPaint(size: size, painter: _MosquePatternPainter()),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Transform.scale(
      scale: _logoScale.value,
      child: Opacity(
        opacity: _logoOpacity.value,
        child: Container(
          width: 180,
          height: 180,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildTagline(ThemeData theme, AppLocalizations l10n) {
    return Opacity(
      opacity: _textOpacity.value * 0.8,
      child: Text(
        l10n.translate("splash.tag_line"),
        style: TextStyle(
          fontSize: 24,
          color: theme.colorScheme.onPrimary,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Custom painter for animated waves
class _WavesPainter extends CustomPainter {
  final double animationValue;

  _WavesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    // First wave
    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);

    for (double i = 0; i <= size.width; i++) {
      path1.lineTo(
        i,
        size.height * 0.7 +
            30 *
                math.sin(
                  (i / size.width * 2 * math.pi) +
                      (animationValue * 2 * math.pi),
                ),
      );
    }

    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Second wave (offset)
    final path2 = Path();
    path2.moveTo(0, size.height * 0.75);

    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.75 +
            25 *
                math.sin(
                  (i / size.width * 2 * math.pi) +
                      (animationValue * 2 * math.pi) +
                      math.pi / 2,
                ),
      );
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);

    // Third wave (top)
    final path3 = Path();
    path3.moveTo(0, size.height * 0.3);

    for (double i = 0; i <= size.width; i++) {
      path3.lineTo(
        i,
        size.height * 0.3 +
            20 *
                math.sin(
                  (i / size.width * 3 * math.pi) -
                      (animationValue * 2 * math.pi),
                ),
      );
    }

    path3.lineTo(size.width, 0);
    path3.lineTo(0, 0);
    path3.close();
    canvas.drawPath(path3, paint1);
  }

  @override
  bool shouldRepaint(_WavesPainter oldDelegate) => true;
}

/// Custom painter for mosque/masjid pattern
class _MosquePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const spacingX = 120.0;
    const spacingY = 140.0;

    for (double x = spacingX / 2; x < size.width; x += spacingX) {
      for (double y = spacingY / 2; y < size.height; y += spacingY) {
        _drawMosque(canvas, Offset(x, y), paint, fillPaint);
      }
    }
  }

  void _drawMosque(
    Canvas canvas,
    Offset center,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    final mosqueWidth = 40.0;
    final mosqueHeight = 50.0;

    // Draw main dome
    final domePath = Path();
    domePath.moveTo(center.dx - mosqueWidth / 2, center.dy);
    domePath.quadraticBezierTo(
      center.dx - mosqueWidth / 2,
      center.dy - mosqueHeight / 2,
      center.dx,
      center.dy - mosqueHeight / 2,
    );
    domePath.quadraticBezierTo(
      center.dx + mosqueWidth / 2,
      center.dy - mosqueHeight / 2,
      center.dx + mosqueWidth / 2,
      center.dy,
    );
    canvas.drawPath(domePath, fillPaint);
    canvas.drawPath(domePath, strokePaint);

    // Draw crescent on top of dome
    final crescentCenter = Offset(center.dx, center.dy - mosqueHeight / 2 - 5);
    _drawCrescent(canvas, crescentCenter, 4, strokePaint);

    // Draw minaret (left)
    final minaretLeft = Rect.fromCenter(
      center: Offset(center.dx - mosqueWidth / 2 - 8, center.dy + 5),
      width: 6,
      height: 35,
    );
    canvas.drawRect(minaretLeft, fillPaint);
    canvas.drawRect(minaretLeft, strokePaint);

    // Small dome on left minaret
    canvas.drawCircle(
      Offset(center.dx - mosqueWidth / 2 - 8, center.dy - 12),
      4,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(center.dx - mosqueWidth / 2 - 8, center.dy - 12),
      4,
      strokePaint,
    );

    // Draw minaret (right)
    final minaretRight = Rect.fromCenter(
      center: Offset(center.dx + mosqueWidth / 2 + 8, center.dy + 5),
      width: 6,
      height: 35,
    );
    canvas.drawRect(minaretRight, fillPaint);
    canvas.drawRect(minaretRight, strokePaint);

    // Small dome on right minaret
    canvas.drawCircle(
      Offset(center.dx + mosqueWidth / 2 + 8, center.dy - 12),
      4,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + mosqueWidth / 2 + 8, center.dy - 12),
      4,
      strokePaint,
    );

    // Draw main building base
    final baseRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 15),
      width: mosqueWidth,
      height: 20,
    );
    canvas.drawRect(baseRect, fillPaint);
    canvas.drawRect(baseRect, strokePaint);

    // Draw door/entrance arch
    final doorPath = Path();
    doorPath.moveTo(center.dx - 8, center.dy + 25);
    doorPath.lineTo(center.dx - 8, center.dy + 10);
    doorPath.quadraticBezierTo(
      center.dx - 8,
      center.dy + 5,
      center.dx,
      center.dy + 5,
    );
    doorPath.quadraticBezierTo(
      center.dx + 8,
      center.dy + 5,
      center.dx + 8,
      center.dy + 10,
    );
    doorPath.lineTo(center.dx + 8, center.dy + 25);
    canvas.drawPath(doorPath, strokePaint);
  }

  void _drawCrescent(Canvas canvas, Offset center, double radius, Paint paint) {
    final crescentPath = Path();
    crescentPath.addOval(Rect.fromCircle(center: center, radius: radius));
    crescentPath.addOval(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.5, center.dy - radius * 0.3),
        radius: radius * 0.8,
      ),
    );
    crescentPath.fillType = PathFillType.evenOdd;
    canvas.drawPath(crescentPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
