import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_cubit.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_state.dart';
import 'package:wadhakir/features/salah_tracker/views/screens/salah_tracker_screen.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';

/// Compact, tappable home banner surfacing the salah streak (🔥) and today's
/// prayer completion ring — the strongest "don't break the chain" retention
/// cue, seen on every app open. Taps through to the full tracker.
class HomeStreakBanner extends StatelessWidget {
  const HomeStreakBanner({super.key});

  static const Color _flame = Color(0xFFE0B341);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalahTrackerCubit, SalahTrackerState>(
      builder: (context, state) {
        if (state is! SalahTrackerLoaded) return const SizedBox.shrink();

        final l10n = context.l10n;
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        final streak = state.currentStreak;
        final prayed = state.todayPrayedCount;
        const total = 5;
        final fraction = prayed / total;

        final streakLabel = streak > 0
            ? (l10n?.translate('salah_tracker.streak_days') ?? 'يوم متتالٍ')
            : (l10n?.translate('salah_tracker.start_streak') ??
                  'ابدأ سلسلتك اليوم');

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            0,
          ),
          child: Semantics(
            button: true,
            label:
                '${l10n?.translate('salah_tracker.home_title') ?? 'سجل الصلاة'}'
                ' — $streak $streakLabel',
            child: FTappable(
              onPress: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalahTrackerScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.md,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      cs.primary,
                      Color.alphaBlend(const Color(0x33000000), cs.primary),
                    ],
                  ),
                  borderRadius: Radii.all(Radii.lg),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Flame badge.
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _flame.withValues(alpha: 0.18),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: _flame,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    // Streak count + label.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (streak > 0)
                            TweenAnimationBuilder<double>(
                              key: ValueKey<int>(streak),
                              tween: Tween<double>(begin: 1.3, end: 1),
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 450),
                              curve: Curves.elasticOut,
                              builder: (context, scale, child) =>
                                  Transform.scale(
                                    scale: scale,
                                    alignment: Alignment.centerRight,
                                    child: child,
                                  ),
                              child: Text(
                                WirdFormat.toArabicDigits(streak),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                            ),
                          if (streak > 0) const SizedBox(height: 2),
                          Text(
                            streakLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onPrimary.withValues(alpha: 0.92),
                              fontWeight: streak > 0
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    // Today's prayer completion ring.
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: fraction),
                                duration: reduceMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 450),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) => SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 5,
                                    strokeCap: StrokeCap.round,
                                    backgroundColor: cs.onPrimary.withValues(
                                      alpha: 0.22,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      cs.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '${WirdFormat.toArabicDigits(prayed)}/${WirdFormat.toArabicDigits(total)}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n?.translate('salah_tracker.today') ?? 'اليوم',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onPrimary.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: Spacing.xs),
                    Icon(
                      isRtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: cs.onPrimary.withValues(alpha: 0.7),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
