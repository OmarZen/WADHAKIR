import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../core/localization/app_localizations.dart';
import 'package:wadhakir/core/notifications/notification_router.dart';
import 'package:wadhakir/core/widgets/scaffold_with_nav_bar.dart';
import 'package:wadhakir/features/onboarding/view/screens/onboarding_screen.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';

/// Brand palette for the splash. Fixed (theme-independent) so it always matches
/// the native splash background and reads well in both light and dark mode.
const Color _splashTop = Color(0xFF2C6BB0); // lighter brand blue
const Color _splashMid = Color(0xFF20497D); // brand primary
const Color _splashBottom = Color(0xFF0D1122); // deep navy

/// Wadhakir animated splash screen.
///
/// Navigation is gated on readiness (intro animation done AND settings loaded)
/// rather than a fixed timer, so the app moves on as soon as it can.
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

  // Readiness gating
  StreamSubscription<SettingsState>? _settingsSub;
  bool _animationDone = false;
  bool _settingsReady = false;
  bool _onboardingCompleted = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Logo fade in (0-30%)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Logo scale: rise with a gentle overshoot, then settle.
    _logoScale =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 0.6,
              end: 1.08,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 1.08,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 40,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.55, curve: Curves.easeInOut),
          ),
        );

    // Tagline fade in (24-56%)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.24, 0.56, curve: Curves.easeIn),
      ),
    );

    // Soft expanding bloom near the end (64-100%)
    _backgroundExpand = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.64, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationDone = true;
        _maybeNavigate();
      }
    });

    // Start immediately — no artificial pre-delay.
    _controller.forward();

    // Hand off from the native splash on the first frame so there's no white
    // flash between the OS splash and this Dart splash.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    // Readiness gate: capture settings now and listen for them to load.
    final settingsCubit = context.read<SettingsCubit>();
    _captureSettings(settingsCubit.state);
    _settingsSub = settingsCubit.stream.listen(_captureSettings);

    // Safety net: if settings never report Loaded (e.g. a load error), don't
    // hang on the splash — proceed to the main screen once the intro has played.
    Future.delayed(const Duration(seconds: 3), () {
      if (_navigated || !mounted || _settingsReady) return;
      _navigated = true;
      _goTo(const ScaffoldWithNavBar());
      _consumePendingNotification();
    });
  }

  /// Route a notification tap that launched the app from a killed state, now
  /// that the home shell is on the navigator. Only meaningful when we land on
  /// the shell (a deep-link tap can't precede onboarding completion).
  void _consumePendingNotification() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationRouter.consumePending();
    });
  }

  void _captureSettings(SettingsState state) {
    if (state is SettingsLoaded) {
      _settingsReady = true;
      _onboardingCompleted = state.settings.onboardingCompleted;
      _maybeNavigate();
    }
  }

  void _maybeNavigate() {
    if (_navigated || !_animationDone || !_settingsReady || !mounted) return;
    _navigated = true;
    _goTo(
      _onboardingCompleted
          ? const ScaffoldWithNavBar()
          : const OnboardingScreen(),
    );
    if (_onboardingCompleted) _consumePendingNotification();
  }

  void _goTo(Widget destination) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              _buildAnimatedBackground(size),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedLogo(),
                    const SizedBox(height: 28),
                    if (l10n != null) _buildTagline(l10n),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_splashTop, _splashMid, _splashBottom],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle animated waves
          CustomPaint(size: size, painter: _WavesPainter(_controller.value)),

          // Soft radial glow behind the logo, fading in with it
          Center(
            child: Opacity(
              opacity: _logoOpacity.value * 0.6,
              child: Container(
                width: size.width * 0.85,
                height: size.width * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Expanding bloom for a soft hand-off at the end
          if (_backgroundExpand.value > 0)
            Center(
              child: Transform.scale(
                scale: 0.6 + (_backgroundExpand.value * 14),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(
                          alpha: 0.10 * _backgroundExpand.value,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Decorative Islamic mosque pattern overlay
          Opacity(
            opacity: 0.4,
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
            color: Colors.white.withValues(alpha: 0.06),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildTagline(AppLocalizations l10n) {
    return Opacity(
      opacity: _textOpacity.value,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.24, 0.56, curve: Curves.easeOut),
          ),
        ),
        child: Text(
          l10n.translate("splash.tag_line"),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the subtle animated waves. Samples the wave coarsely
/// (every ~10px) and only repaints when the animation value changes, so it
/// stays cheap and smooth.
class _WavesPainter extends CustomPainter {
  final double animationValue;

  _WavesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = animationValue * 2 * math.pi;

    // Two lower waves rising from the bottom + one near the top.
    _drawWave(
      canvas,
      size,
      baseY: size.height * 0.70,
      amplitude: 30,
      freq: 2,
      phase: phase,
      color: Colors.white.withValues(alpha: 0.03),
      fromTop: false,
    );
    _drawWave(
      canvas,
      size,
      baseY: size.height * 0.75,
      amplitude: 25,
      freq: 2,
      phase: phase + math.pi / 2,
      color: Colors.white.withValues(alpha: 0.02),
      fromTop: false,
    );
    _drawWave(
      canvas,
      size,
      baseY: size.height * 0.30,
      amplitude: 20,
      freq: 3,
      phase: -phase,
      color: Colors.white.withValues(alpha: 0.03),
      fromTop: true,
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double amplitude,
    required double freq,
    required double phase,
    required Color color,
    required bool fromTop,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(0, baseY);
    const step = 10.0;
    final w = size.width;
    for (double x = 0; x <= w; x += step) {
      final y = baseY + amplitude * math.sin((x / w * freq * math.pi) + phase);
      path.lineTo(x, y);
    }
    // Ensure the wave reaches the right edge.
    path.lineTo(w, baseY + amplitude * math.sin((freq * math.pi) + phase));

    if (fromTop) {
      path.lineTo(w, 0);
      path.lineTo(0, 0);
    } else {
      path.lineTo(w, size.height);
      path.lineTo(0, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavesPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

/// Custom painter for the static mosque/masjid pattern.
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
