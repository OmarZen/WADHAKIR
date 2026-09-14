import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';

/// Hero panel: current streak (big), best streak, and today's completion ring.
/// Primary-colored card mirroring WirdProgressHeader.
class SalahStreakHeader extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;
  final int todayPrayed;
  final int todayTotal;

  const SalahStreakHeader({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    required this.todayPrayed,
    required this.todayTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    final fraction = todayTotal == 0 ? 0.0 : todayPrayed / todayTotal;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.xs,
      ),
      padding: const EdgeInsets.all(Spacing.lg),
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
      ),
      child: Row(
        children: [
          // Today's completion ring.
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  // Fills smoothly toward the new fraction when a prayer is
                  // logged — a calm reveal, not a jump. Instant if the user
                  // has reduced-motion enabled.
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: fraction),
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      backgroundColor: cs.onPrimary.withValues(alpha: 0.25),
                      valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                    ),
                  ),
                ),
                Text(
                  '${WirdFormat.toArabicDigits(todayPrayed)}/${WirdFormat.toArabicDigits(todayTotal)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: cs.onPrimary,
                      size: 28,
                    ),
                    const SizedBox(width: Spacing.xs),
                    // Pops with a little bounce whenever the streak changes
                    // (keyed on the value so it re-animates on each increment).
                    TweenAnimationBuilder<double>(
                      key: ValueKey<int>(currentStreak),
                      tween: Tween<double>(begin: 1.4, end: 1),
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 450),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Text(
                        WirdFormat.toArabicDigits(currentStreak),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        l10n?.translate('salah_tracker.streak_days') ??
                            'يوم متتالٍ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  '${l10n?.translate('salah_tracker.best_streak') ?? 'أطول سلسلة'}: '
                  '${WirdFormat.toArabicDigits(bestStreak)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onPrimary.withValues(alpha: 0.85),
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
