import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/widgets/scaffold_with_nav_bar.dart';
import 'package:wadhakir/features/settings/view/widgets/app_lock_settings_widget.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/features/pray_times/views/widgets/prayer_settings_dialog.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/core/utils/alarm_permission_helper.dart';
import 'package:wadhakir/features/floating_dhikr/data/floating_dhikr_settings.dart';
import 'package:wadhakir/features/floating_dhikr/service/floating_dhikr_service.dart';
import 'package:wadhakir/features/floating_dhikr/views/widgets/pill_preview.dart';

/// Calm & spiritual onboarding. Five pages, each with its own primary-derived
/// accent (no harsh blacks, no off-brand colors). Pages live inside a real
/// PageView so users can swipe naturally; the background, accents and orbs
/// interpolate smoothly between pages using the page controller's offset.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _pageCount = 6;

  late final PageController _controller;
  // Continuous page offset (e.g. 1.32 while mid-swipe). Drives every smooth
  // interpolation: backgrounds, orbs, progress, icon morph. Listening on
  // the controller and lifting this into setState gives us per-frame
  // smoothness without rebuilding the heavy page content.
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController()..addListener(_onScroll);
  }

  void _onScroll() {
    final next = _controller.page ?? 0;
    if ((next - _page).abs() < 0.0005) return;
    setState(() => _page = next);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  int get _currentPage => _page.round().clamp(0, _pageCount - 1);

  Future<void> _animateTo(int index) async {
    if (index < 0 || index >= _pageCount) return;
    await _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 520),
      // Emphasized cubic — buttery acceleration into the page, gentle settle.
      curve: Curves.easeOutCubic,
    );
  }

  void _next() => _animateTo(_currentPage + 1);
  void _back() => _animateTo(_currentPage - 1);

  /// Persist the "user has seen onboarding" flag in SharedPreferences and
  /// route to the main app. The splash screen reads this flag on next
  /// launch and skips straight to home — so onboarding only ever shows
  /// once per install (or until the user clears app data).
  Future<void> _finishOnboarding(BuildContext context) async {
    final settingsCubit = context.read<SettingsCubit>();
    final navigator = Navigator.of(context);
    await settingsCubit.setOnboardingCompleted(true);
    // New users were already offered the name field on the dedicated
    // onboarding page, so suppress the existing-user name prompt for them.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.namePromptSeenKey, true);
    if (!mounted) return;
    navigator.pushReplacement(_homeRoute());
  }

  PageRouteBuilder _homeRoute() {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => const ScaffoldWithNavBar(),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 450),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final settingsState = context.watch<SettingsCubit>().state;
    final notificationsEnabled = settingsState is SettingsLoaded
        ? settingsState.settings.notificationSettings.masterEnabled
        : true;

    // Interpolated palette for the current scroll offset. Drives everything
    // chromed by the onboarding (background, orbs, hero icon glow, accent
    // tint), so the whole screen breathes together as the user swipes.
    final palette = _OnboardingPalette.lerp(_page);

    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentPage > 0) _back();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: _AnimatedBackdrop(
          palette: palette,
          isDark: isDark,
          child: SafeArea(
            child: Stack(
              children: [
                _ParallaxOrbs(page: _page, palette: palette),
                Column(
                  children: [
                    _OnboardingHeader(
                      currentPage: _currentPage,
                      pageCount: _pageCount,
                      l10n: l10n,
                      onBack: _currentPage > 0 ? _back : null,
                      onSkip: () => _finishOnboarding(context),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        physics: const _SmoothPageScrollPhysics(),
                        itemCount: _pageCount,
                        itemBuilder: (_, index) {
                          return _OnboardingPageScaffold(
                            page: _page,
                            index: index,
                            palette: _OnboardingPalette.forPage(index),
                            isDark: isDark,
                            child: _buildPageBody(
                              context: context,
                              index: index,
                              theme: theme,
                              isDark: isDark,
                              l10n: l10n,
                              settingsState: settingsState,
                              notificationsEnabled: notificationsEnabled,
                            ),
                          );
                        },
                      ),
                    ),
                    _OnboardingFooter(
                      page: _page,
                      pageCount: _pageCount,
                      palette: palette,
                      currentPage: _currentPage,
                      l10n: l10n,
                      onBack: _currentPage > 0 ? _back : null,
                      onNext: () {
                        if (_currentPage == _pageCount - 1) {
                          _finishOnboarding(context);
                        } else {
                          _next();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- Page bodies
  // Each page returns ONLY the inner content. The card chrome (icon + title
  // + subtitle + glass surface) is rendered by _OnboardingPageScaffold so
  // the visual shell stays consistent across pages.

  Widget _buildPageBody({
    required BuildContext context,
    required int index,
    required ThemeData theme,
    required bool isDark,
    required AppLocalizations? l10n,
    required SettingsState settingsState,
    required bool notificationsEnabled,
  }) {
    final fonts = _OnboardingFonts.of(context, theme);
    final palette = _OnboardingPalette.forPage(index);

    switch (index) {
      case 0:
        return _WelcomePage(palette: palette, fonts: fonts, l10n: l10n);
      case 1:
        return _NamePage(palette: palette, fonts: fonts, l10n: l10n);
      case 2:
        return _SetupPage(
          palette: palette,
          fonts: fonts,
          l10n: l10n,
          notificationsEnabled: notificationsEnabled,
          onToggle: (enabled) async {
            if (enabled) {
              final perms = await AlarmPermissionHelper.requestAllPermissions(
                context,
              );
              if (!context.mounted) return;
              if (perms['notifications'] == true) {
                await context.read<SettingsCubit>().toggleNotifications(true);
              } else {
                AlarmPermissionHelper.showPermissionDeniedDialog(context);
              }
            } else {
              await context.read<SettingsCubit>().toggleNotifications(false);
            }
          },
        );
      case 3:
        return _AppLockPage(
          palette: palette,
          fonts: fonts,
          l10n: l10n,
          settingsState: settingsState,
        );
      case 4:
        return _PrayerPage(palette: palette, fonts: fonts, l10n: l10n);
      default:
        return _FloatingDhikrPage(
          palette: palette,
          fonts: fonts,
          isDark: isDark,
          l10n: l10n,
        );
    }
  }
}

// -------------------------------------------------------------- Color palette
//
// The brand `colorScheme.secondary` is #0D1122 (nearly black). Onboarding
// used to mix that into every gradient, making icons read as harsh black.
// The replacement is a single brand-blue palette used across every page —
// no per-page accent colors, no warm tints, just the app's primary blue
// rendered at different weights so the chrome feels cohesive with the
// rest of the app.

class _OnboardingPalette {
  const _OnboardingPalette();

  // Brand primary (same `#20497D` the app theme uses elsewhere) and a
  // lighter variant that already appears in the floating-dhikr pill bar.
  Color get primary => const Color(0xFF20497D);
  Color get accent => const Color(0xFF3A6BA8);
  Color get glow => const Color(0xFF7BA7D9);
  Color get surfaceTint => const Color(0xFFEEF3FB);

  // The page-aware constructors are kept as no-ops so we never have to
  // re-thread the palette through every widget if we later decide to
  // introduce per-page subtle variations again.
  static const _OnboardingPalette _brand = _OnboardingPalette();
  static _OnboardingPalette forPage(int index) => _brand;
  static _OnboardingPalette lerp(double page) => _brand;
}

// -------------------------------------------------------------- Backdrop
// Light gradient that interpolates with the palette + a soft radial halo
// near the top so the hero icon sits on a glow rather than a hard color.

class _AnimatedBackdrop extends StatelessWidget {
  const _AnimatedBackdrop({
    required this.palette,
    required this.isDark,
    required this.child,
  });

  final _OnboardingPalette palette;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final baseTop = isDark ? const Color(0xFF0F1A2A) : palette.surfaceTint;
    final baseBottom = isDark ? const Color(0xFF080C14) : Colors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [baseTop, baseBottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.7),
                    radius: 0.9,
                    colors: [
                      palette.glow.withValues(alpha: isDark ? 0.20 : 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- Parallax orbs

class _ParallaxOrbs extends StatelessWidget {
  const _ParallaxOrbs({required this.page, required this.palette});
  final double page;
  final _OnboardingPalette palette;

  @override
  Widget build(BuildContext context) {
    // Each orb shifts at a different rate as the user swipes, giving the
    // background a sense of depth without grabbing focus.
    final dx = page;
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned(
              left: 24 - dx * 18,
              top: 90 + math.sin(dx) * 8,
              child: _orb(palette.accent.withValues(alpha: 0.18), 200),
            ),
            Positioned(
              right: 16 + dx * 22,
              top: 220 + math.cos(dx) * 10,
              child: _orb(palette.glow.withValues(alpha: 0.20), 150),
            ),
            Positioned(
              right: 28 - dx * 14,
              bottom: 80 + math.sin(dx * 0.8) * 6,
              child: _orb(palette.primary.withValues(alpha: 0.10), 220),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

// -------------------------------------------------------------- Header

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.currentPage,
    required this.pageCount,
    required this.l10n,
    required this.onBack,
    required this.onSkip,
  });

  final int currentPage;
  final int pageCount;
  final AppLocalizations? l10n;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
      child: Row(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: onBack == null ? 0 : 1,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              tooltip: _t(l10n, 'onboarding.back', 'Back'),
            ),
          ),
          const Spacer(),
          // Pill counter so the step number is always visible without
          // needing a chunky stepper at the top.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              ),
            ),
            child: Text(
              '${currentPage + 1} / $pageCount',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Skip stays available on every page — onboarding should never
          // feel like a trap.
          FButton(
            onPress: onSkip,
            variant: FButtonVariant.ghost,
            mainAxisSize: MainAxisSize.min,
            child: Text(_t(l10n, 'onboarding.skip', 'Skip')),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- Footer

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({
    required this.page,
    required this.pageCount,
    required this.palette,
    required this.currentPage,
    required this.l10n,
    required this.onBack,
    required this.onNext,
  });

  final double page;
  final int pageCount;
  final _OnboardingPalette palette;
  final int currentPage;
  final AppLocalizations? l10n;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = currentPage == pageCount - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Column(
        children: [
          _ProgressBar(
            page: page,
            pageCount: pageCount,
            accent: palette.primary,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (onBack != null) ...[
                Expanded(
                  flex: 1,
                  child: FButton(
                    onPress: onBack,
                    variant: FButtonVariant.outline,
                    child: Text(
                      _t(l10n, 'onboarding.back', 'Back'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: _PrimaryCtaButton(
                  palette: palette,
                  onPressed: onNext,
                  label: isLast
                      ? _t(l10n, 'onboarding.finish', 'Get started')
                      : _t(l10n, 'onboarding.next', 'Continue'),
                  icon: isLast
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _t(l10n, 'onboarding.swipe_hint', 'Swipe or tap to navigate'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient CTA with a subtle inner glow — visually anchors the action
/// without the heaviness of a solid filled button on the soft backdrop.
class _PrimaryCtaButton extends StatelessWidget {
  const _PrimaryCtaButton({
    required this.palette,
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  final _OnboardingPalette palette;
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.primary, palette.accent],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.18),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.page,
    required this.pageCount,
    required this.accent,
  });

  final double page;
  final int pageCount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (i) {
        // Each dot widens & brightens based on how close the current scroll
        // offset is to it — gives a smooth "tracker" feel during swipes.
        final distance = (page - i).abs().clamp(0.0, 1.0);
        final closeness = 1.0 - distance;
        final width = 8 + closeness * 22;
        final color = Color.lerp(
          theme.colorScheme.onSurface.withValues(alpha: 0.18),
          accent,
          closeness,
        );
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: width,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

// -------------------------------------------------------------- Page chrome

class _OnboardingPageScaffold extends StatelessWidget {
  const _OnboardingPageScaffold({
    required this.page,
    required this.index,
    required this.palette,
    required this.isDark,
    required this.child,
  });

  final double page;
  final int index;
  final _OnboardingPalette palette;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Distance to the centred page (0 = fully visible, 1 = next/prev card).
    // Drives small parallax + fade so cards feel layered during the swipe.
    final t = (page - index);
    final offset = t * -24;
    final fade = (1 - t.abs() * 0.6).clamp(0.0, 1.0);
    final scale = 1.0 - (t.abs() * 0.04);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: Transform.scale(
          scale: scale,
          child: Opacity(opacity: fade, child: child),
        ),
      ),
    );
  }
}

/// Reusable "hero card" used by all 5 pages.
class _PageHero extends StatelessWidget {
  const _PageHero({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.fonts,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _OnboardingPalette palette;
  final _OnboardingFonts fonts;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(
              alpha: isDark ? 0.78 : 0.92,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: palette.primary.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: isDark ? 0.30 : 0.10),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeroIcon(icon: icon, palette: palette),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: fonts.titleStyle?.copyWith(color: palette.primary),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: fonts.subtitleStyle,
              ),
              const SizedBox(height: 22),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated icon disc — slow rotating glow ring + gradient fill. The glow
/// is the warm accent so the page feels alive even when it's static.
class _HeroIcon extends StatefulWidget {
  const _HeroIcon({required this.icon, required this.palette});
  final IconData icon;
  final _OnboardingPalette palette;

  @override
  State<_HeroIcon> createState() => _HeroIconState();
}

class _HeroIconState extends State<_HeroIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final angle = _ctrl.value * 2 * math.pi;
        return SizedBox(
          width: 128,
          height: 128,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating glow ring — kept very soft so it reads as
              // ambient light rather than a UI element.
              Transform.rotate(
                angle: angle,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        widget.palette.glow.withValues(alpha: 0.0),
                        widget.palette.glow.withValues(alpha: 0.55),
                        widget.palette.accent.withValues(alpha: 0.20),
                        widget.palette.glow.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.35, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              // Solid filled disc with the brand gradient — no black tones.
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [widget.palette.primary, widget.palette.accent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.palette.primary.withValues(alpha: 0.42),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(widget.icon, size: 54, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------- Pages

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.palette,
    required this.fonts,
    required this.l10n,
  });
  final _OnboardingPalette palette;
  final _OnboardingFonts fonts;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PageHero(
      icon: Icons.mosque_rounded,
      palette: palette,
      fonts: fonts,
      title: _t(l10n, 'onboarding.welcome_title', 'Welcome to Wadhakir'),
      subtitle: _t(
        l10n,
        'onboarding.welcome_subtitle',
        'A calm Islamic companion for prayer times, Quran, dhikr and daily reminders.',
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroChip(
              palette: palette,
              icon: Icons.nights_stay_rounded,
              label: _t(
                l10n,
                'onboarding.hero_label',
                'Prayer • Quran • Azkar',
              ),
            ),
            const SizedBox(height: 18),
            _FeatureRow(
              palette: palette,
              icon: Icons.access_time_rounded,
              title: _t(l10n, 'onboarding.feature_prayer', 'Prayer times'),
              subtitle: _t(
                l10n,
                'onboarding.feature_prayer_subtitle',
                'Accurate timings and reminders.',
              ),
            ),
            const SizedBox(height: 10),
            _FeatureRow(
              palette: palette,
              icon: Icons.menu_book_rounded,
              title: _t(l10n, 'onboarding.feature_quran', 'Quran'),
              subtitle: _t(
                l10n,
                'onboarding.feature_quran_subtitle',
                'A focused reading experience.',
              ),
            ),
            const SizedBox(height: 10),
            _FeatureRow(
              palette: palette,
              icon: Icons.auto_awesome_rounded,
              title: _t(l10n, 'onboarding.feature_azkar', 'Azkar'),
              subtitle: _t(
                l10n,
                'onboarding.feature_azkar_subtitle',
                'Easy daily remembrance and dhikr.',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _t(
                l10n,
                'onboarding.intro_hint',
                'We only ask for what helps the app work better for you.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                fontFamily: fonts.bodyFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dedicated, optional name-collection page. Persists live so the name
/// survives Skip / swiping back and forth, and the home greeting already
/// reflects it by the time onboarding finishes.
class _NamePage extends StatefulWidget {
  const _NamePage({
    required this.palette,
    required this.fonts,
    required this.l10n,
  });

  final _OnboardingPalette palette;
  final _OnboardingFonts fonts;
  final AppLocalizations? l10n;

  @override
  State<_NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<_NamePage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill if a name is already stored (e.g. re-running onboarding).
    final state = context.read<SettingsCubit>().state;
    if (state is SettingsLoaded && state.settings.userName.isNotEmpty) {
      _controller.text = state.settings.userName;
    }
    _controller.addListener(_persist);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_persist)
      ..dispose();
    super.dispose();
  }

  void _persist() =>
      context.read<SettingsCubit>().setUserName(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PageHero(
      icon: Icons.person_outline_rounded,
      palette: widget.palette,
      fonts: widget.fonts,
      title: _t(widget.l10n, 'onboarding.name_title', 'What should we call you?'),
      subtitle: _t(
        widget.l10n,
        'onboarding.name_subtitle',
        "We'll greet you by name on the home screen. This is optional.",
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FTextField(
              control: FTextFieldControl.managed(controller: _controller),
              hint: _t(widget.l10n, 'onboarding.name_hint', 'Your first name'),
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            Text(
              _t(
                widget.l10n,
                'onboarding.name_optional_hint',
                'You can skip this and add it later in Settings.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                fontFamily: widget.fonts.bodyFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupPage extends StatelessWidget {
  const _SetupPage({
    required this.palette,
    required this.fonts,
    required this.l10n,
    required this.notificationsEnabled,
    required this.onToggle,
  });

  final _OnboardingPalette palette;
  final _OnboardingFonts fonts;
  final AppLocalizations? l10n;
  final bool notificationsEnabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PageHero(
      icon: Icons.notifications_active_rounded,
      palette: palette,
      fonts: fonts,
      title: _t(l10n, 'onboarding.setup_title', 'Stay reminded'),
      subtitle: _t(
        l10n,
        'onboarding.setup_subtitle',
        'Turn on prayer notifications so we can gently remind you on time.',
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingToggleCard(
              palette: palette,
              icon: Icons.notifications_active_rounded,
              title: _t(
                l10n,
                'onboarding.notifications_title',
                'Prayer notifications',
              ),
              subtitle: _t(
                l10n,
                'onboarding.notifications_subtitle',
                'Turn reminders on for prayer times and daily alerts.',
              ),
              value: notificationsEnabled,
              onChanged: onToggle,
            ),
            const SizedBox(height: 18),
            _InfoRow(
              palette: palette,
              icon: Icons.auto_awesome_rounded,
              title: _t(l10n, 'onboarding.setup_benefit_1', 'Fast setup'),
              subtitle: _t(
                l10n,
                'onboarding.setup_benefit_1_subtitle',
                'You can change these preferences any time from Settings.',
              ),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              palette: palette,
              icon: Icons.verified_user_rounded,
              title: _t(
                l10n,
                'onboarding.setup_benefit_2',
                'Private by default',
              ),
              subtitle: _t(
                l10n,
                'onboarding.setup_benefit_2_subtitle',
                'Only the essentials are asked during first launch.',
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _t(
                l10n,
                'onboarding.setup_hint',
                'Use the toggle above, then continue when you are ready.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                fontFamily: fonts.bodyFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppLockPage extends StatelessWidget {
  const _AppLockPage({
    required this.palette,
    required this.fonts,
    required this.l10n,
    required this.settingsState,
  });
  final _OnboardingPalette palette;
  final _OnboardingFonts fonts;
  final AppLocalizations? l10n;
  final SettingsState settingsState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PageHero(
      icon: Icons.shield_moon_rounded,
      palette: palette,
      fonts: fonts,
      title: _t(l10n, 'onboarding.applock_setup_title', 'App lock setup'),
      subtitle: _t(
        l10n,
        'onboarding.applock_setup_subtitle',
        'Pause distracting apps during prayer windows.',
      ),
      child: SingleChildScrollView(
        child: settingsState is SettingsLoaded
            ? AppLockSettingsWidget(
                settings: (settingsState as SettingsLoaded).settings,
                cubit: context.read<SettingsCubit>(),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: palette.primary),
                      const SizedBox(height: 12),
                      Text(
                        _t(l10n, 'common.loading', 'Loading...'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _PrayerPage extends StatelessWidget {
  const _PrayerPage({
    required this.palette,
    required this.fonts,
    required this.l10n,
  });
  final _OnboardingPalette palette;
  final _OnboardingFonts fonts;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PageHero(
      icon: Icons.wb_twilight_rounded,
      palette: palette,
      fonts: fonts,
      title: _t(l10n, 'onboarding.prayer_settings_title', 'Prayer settings'),
      subtitle: _t(
        l10n,
        'onboarding.prayer_settings_subtitle',
        'Choose calculation method, madhhab and location source.',
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoRow(
              palette: palette,
              icon: Icons.location_on_rounded,
              title: _t(
                l10n,
                'onboarding.prayer_loc',
                'Location-based timings',
              ),
              subtitle: _t(
                l10n,
                'onboarding.prayer_loc_subtitle',
                'Prayer times calculated from your current location.',
              ),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              palette: palette,
              icon: Icons.calculate_rounded,
              title: _t(l10n, 'onboarding.prayer_method', 'Calculation method'),
              subtitle: _t(
                l10n,
                'onboarding.prayer_method_subtitle',
                'Pick the calculation method that matches your community.',
              ),
            ),
            const SizedBox(height: 18),
            // The CTA replaces the old FilledButton.tonalIcon which inherited
            // dark default colors. This one is keyed to the palette accent
            // (warm amber on this page) so it never reads as black.
            Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.primary, palette.accent],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  splashColor: Colors.white.withValues(alpha: 0.18),
                  onTap: () => PrayerSettingsDialog.show(
                    context,
                    context.read<PrayerTimesCubit>(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _t(
                            l10n,
                            'onboarding.open_prayer_settings',
                            'Open prayer settings',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _t(
                l10n,
                'onboarding.prayer_settings_hint',
                'You can change these later from Settings.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                fontFamily: fonts.bodyFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingDhikrPage extends StatefulWidget {
  const _FloatingDhikrPage({
    required this.palette,
    required this.fonts,
    required this.isDark,
    required this.l10n,
  });

  final _OnboardingPalette palette;
  final _OnboardingFonts fonts;
  final bool isDark;
  final AppLocalizations? l10n;

  @override
  State<_FloatingDhikrPage> createState() => _FloatingDhikrPageState();
}

class _FloatingDhikrPageState extends State<_FloatingDhikrPage> {
  final _service = FloatingDhikrService.instance;
  FloatingDhikrSettings _settings = const FloatingDhikrSettings();
  bool _hasPermission = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _service.getSettings();
    final perm = await _service.hasPermission();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _hasPermission = perm;
    });
  }

  String _tr(String key, String fallback) =>
      widget.l10n?.translate(key) ?? fallback;

  Future<void> _enable() async {
    if (!_service.isSupported) {
      showFToast(
        context: context,
        title: Text(
          _tr(
            'floating_dhikr.unsupported_platform',
            'This feature is only available on Android.',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    var perm = _hasPermission;
    if (!perm) perm = await _service.requestPermission();
    if (!mounted) return;
    if (!perm) {
      setState(() {
        _busy = false;
        _hasPermission = false;
      });
      showFToast(
        context: context,
        variant: FToastVariant.destructive,
        title: Text(
          _tr(
            'floating_dhikr.permission_denied',
            "Permission denied. The floating reminder can't run without it.",
          ),
        ),
      );
      return;
    }
    final next = _settings.copyWith(enabled: true);
    await _service.updateSettings(next);
    if (!mounted) return;
    setState(() {
      _settings = next;
      _hasPermission = perm;
      _busy = false;
    });
  }

  Future<void> _setInterval(int minutes) async {
    final next = _settings.copyWith(interval: Duration(minutes: minutes));
    await _service.updateSettings(next);
    if (!mounted) return;
    setState(() => _settings = next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = widget.palette;
    final isEnabled = _settings.enabled && _hasPermission;

    return _PageHero(
      icon: Icons.bubble_chart_rounded,
      palette: palette,
      fonts: widget.fonts,
      title: _tr('onboarding.floating_dhikr_title', 'Floating dhikr reminder'),
      subtitle: _tr(
        'onboarding.floating_dhikr_subtitle',
        'A gentle reminder slides over your other apps at a chosen interval.',
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.primary.withValues(
                      alpha: widget.isDark ? 0.28 : 0.10,
                    ),
                    palette.accent.withValues(
                      alpha: widget.isDark ? 0.24 : 0.08,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.16),
                ),
              ),
              child: PillPreview(opacity: _settings.opacity),
            ),
            const SizedBox(height: 14),
            _InfoRow(
              palette: palette,
              icon: Icons.refresh_rounded,
              title: _tr(
                'onboarding.floating_dhikr_benefit_1',
                'Regular gentle reminders',
              ),
              subtitle: _tr(
                'onboarding.floating_dhikr_benefit_1_subtitle',
                'A dhikr appears over your other apps at a chosen interval.',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _tr('floating_dhikr.interval', 'Interval'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: widget.fonts.bodyFontFamily,
                color: palette.primary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [5, 10, 15, 30, 60].map((m) {
                final selected = _settings.interval.inMinutes == m;
                return ChoiceChip(
                  label: Text('$m ${_tr('floating_dhikr.minutes', 'min')}'),
                  selected: selected,
                  selectedColor: palette.primary.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: palette.primary.withValues(
                      alpha: selected ? 0.6 : 0.2,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? palette.primary : null,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => _setInterval(m),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (isEnabled)
              _SuccessBadge(
                palette: palette,
                label: _tr(
                  'onboarding.floating_dhikr_enabled',
                  'Floating reminder enabled. You can fine-tune later from Settings.',
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [palette.primary, palette.accent],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: palette.primary.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _busy ? null : _enable,
                      splashColor: Colors.white.withValues(alpha: 0.18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.bubble_chart_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                            const SizedBox(width: 10),
                            Text(
                              _tr(
                                'onboarding.floating_dhikr_enable_cta',
                                'Enable floating reminder',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              _tr(
                'onboarding.floating_dhikr_skip_hint',
                'You can skip and enable this later from Settings → Floating dhikr reminder.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                fontFamily: widget.fonts.bodyFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- Shared atoms

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.palette,
    required this.icon,
    required this.label,
  });
  final _OnboardingPalette palette;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            palette.primary.withValues(alpha: 0.10),
            palette.accent.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: palette.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: palette.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final _OnboardingPalette palette;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.primary.withValues(alpha: 0.18),
                  palette.accent.withValues(alpha: 0.22),
                ],
              ),
            ),
            child: Icon(icon, color: palette.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final _OnboardingPalette palette;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.primary.withValues(alpha: 0.10),
          ),
          child: Icon(icon, size: 18, color: palette.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingToggleCard extends StatelessWidget {
  const _SettingToggleCard({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final _OnboardingPalette palette;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary.withValues(alpha: value ? 0.10 : 0.04),
            palette.accent.withValues(alpha: value ? 0.12 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: palette.primary.withValues(alpha: value ? 0.35 : 0.12),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.primary.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: palette.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: palette.primary,
          ),
        ],
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({required this.palette, required this.label});
  final _OnboardingPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.primary.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: palette.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- Fonts helper

class _OnboardingFonts {
  const _OnboardingFonts({
    required this.titleStyle,
    required this.subtitleStyle,
    required this.bodyFontFamily,
  });

  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final String bodyFontFamily;

  static _OnboardingFonts of(BuildContext context, ThemeData theme) {
    final locale = AppLocalizations.of(context)?.locale.languageCode ?? 'en';
    final isArabic = locale == 'ar';
    if (isArabic) {
      return _OnboardingFonts(
        titleStyle: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.25,
          fontFamily: 'ScheherazadeNew',
        ),
        subtitleStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
          height: 1.6,
          fontFamily: 'ScheherazadeNew',
          fontSize: 18,
        ),
        bodyFontFamily: 'ScheherazadeNew',
      );
    }
    return _OnboardingFonts(
      titleStyle: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
      subtitleStyle: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
        height: 1.45,
      ),
      bodyFontFamily: theme.textTheme.bodyLarge?.fontFamily ?? '',
    );
  }
}

// -------------------------------------------------------------- Utilities

String _t(AppLocalizations? l10n, String key, String fallback) =>
    l10n?.translate(key) ?? fallback;

/// Slightly heavier scroll resistance than the default PageScrollPhysics so
/// page changes feel intentional rather than flicky. The mass/spring values
/// were picked by feel — change carefully.
class _SmoothPageScrollPhysics extends PageScrollPhysics {
  const _SmoothPageScrollPhysics({super.parent});

  @override
  _SmoothPageScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _SmoothPageScrollPhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 80, stiffness: 100, damping: 1);
}
