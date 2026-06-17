import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:forui/forui.dart';

/// How loud a celebration should be. [light] for a single daily action
/// (one wird day, a full salah day, an azkar set, a tasbih target); [big]
/// for the rarer milestones (finished khatma, a 7/30/100-day streak) so the
/// reward stays proportional to the achievement.
enum CelebrationIntensity { light, big }

/// One-shot confetti + haptic reward, fired imperatively from wherever a
/// completion happens. Uses `flutter_confetti`'s overlay API so no persistent
/// `ConfettiController` has to live in the widget tree — call [burst] and the
/// overlay self-disposes.
///
/// RTL-safe: only centered or symmetric (mirrored) bursts are used, so the
/// effect reads identically in Arabic (default) and English.
class Celebration {
  Celebration._();

  // Brand palette for everyday bursts: the app primary (#20497D) + the
  // onboarding accents, plus warm gold and white so particles pop.
  static const List<Color> _brandColors = <Color>[
    Color(0xFF20497D), // primary
    Color(0xFF3A6BA8), // accent
    Color(0xFF7BA7D9), // glow
    Color(0xFFE0B341), // warm gold
    Colors.white,
  ];

  // Gold-forward palette for milestone star bursts — feels like a trophy.
  static const List<Color> _goldColors = <Color>[
    Color(0xFFE0B341),
    Color(0xFFF4D67A),
    Color(0xFFFFF3C4),
    Color(0xFF20497D),
    Colors.white,
  ];

  /// Fire confetti (and a heavy haptic). [big] swaps the plain burst for the
  /// richer gold-star fountain. When [message] is provided it is also shown as
  /// a short forui toast alongside the burst.
  static void burst(
    BuildContext context, {
    CelebrationIntensity intensity = CelebrationIntensity.light,
    String? message,
  }) {
    HapticFeedback.heavyImpact();

    if (intensity == CelebrationIntensity.big) {
      _stars(context);
    } else {
      // Centered fountain — direction-neutral, so identical under RTL/LTR.
      Confetti.launch(
        context,
        options: const ConfettiOptions(
          particleCount: 60,
          spread: 70,
          startVelocity: 32,
          y: 0.35,
          colors: _brandColors,
        ),
      );
    }

    if (message != null && message.isNotEmpty) {
      showFToast(context: context, title: Text(message));
    }
  }

  /// A milestone celebration: a gold-star burst + a brief, non-blocking
  /// "achievement unlocked" card that scales in, holds, and fades out on its
  /// own. Use for the rare, earned moments (finished khatma, streak
  /// milestones) so they feel bigger than an everyday completion.
  static void milestone(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    HapticFeedback.heavyImpact();
    _stars(context);

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AchievementOverlay(
        title: title,
        subtitle: subtitle,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  /// Gold star fountain: a tall centered burst + two mirrored side cannons.
  static void _stars(BuildContext context) {
    Star starBuilder(int _) => Star();
    Confetti.launch(
      context,
      particleBuilder: starBuilder,
      options: const ConfettiOptions(
        particleCount: 80,
        spread: 100,
        startVelocity: 42,
        y: 0.35,
        scalar: 1.4,
        colors: _goldColors,
      ),
    );
    Confetti.launch(
      context,
      particleBuilder: starBuilder,
      options: const ConfettiOptions(
        particleCount: 50,
        angle: 60,
        spread: 55,
        x: 0,
        y: 0.6,
        scalar: 1.2,
        colors: _goldColors,
      ),
    );
    Confetti.launch(
      context,
      particleBuilder: starBuilder,
      options: const ConfettiOptions(
        particleCount: 50,
        angle: 120,
        spread: 55,
        x: 1,
        y: 0.6,
        scalar: 1.2,
        colors: _goldColors,
      ),
    );
  }
}

/// Self-animating, non-interactive milestone card. Scales + fades in, holds
/// ~1.9s, fades out, then asks to be removed via [onDismiss].
class _AchievementOverlay extends StatefulWidget {
  const _AchievementOverlay({
    required this.title,
    required this.onDismiss,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onDismiss;

  @override
  State<_AchievementOverlay> createState() => _AchievementOverlayState();
}

class _AchievementOverlayState extends State<_AchievementOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _run();
  }

  Future<void> _run() async {
    await _controller.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const gold = Color(0xFFE0B341);

    return Positioned.fill(
      // Non-interactive so it never traps taps; it dismisses itself.
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _controller,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOutBack,
                  reverseCurve: Curves.easeIn,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: gold.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.25),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
