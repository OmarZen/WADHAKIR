import 'package:flutter/material.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/features/salah_tracker/services/salah_stats_service.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';

/// Hand-drawn weekly completion bars (last 7 days) — no chart lib needed.
/// Each bar height = prayed/5 for that day; today is highlighted.
class SalahWeekSummary extends StatelessWidget {
  final SalahLogModel log;
  final DateTime today;
  final SalahStatsService stats;

  const SalahWeekSummary({
    super.key,
    required this.log,
    required this.today,
    required this.stats,
  });

  // DateTime.weekday 1=Mon..7=Sun -> single Arabic letter.
  static const List<String> _weekdayLetters = [
    'ن', // الاثنين
    'ث', // الثلاثاء
    'ر', // الأربعاء
    'خ', // الخميس
    'ج', // الجمعة
    'س', // السبت
    'ح', // الأحد
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final green = isDark ? darkPrayerAzkarColor : prayerAzkarColor;
    final l10n = context.l10n;

    final days = <DateTime>[
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final week = stats.weekStats(log, today);
    final percent = (week.completionFraction * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: Radii.all(Radii.md),
        border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.translate('salah_tracker.week_completion') ??
                    'إتمام هذا الأسبوع',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${WirdFormat.toArabicDigits(percent)}٪',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in days)
                  Expanded(
                    child: _DayBar(
                      fraction: stats.completionFraction(log, day),
                      letter: _weekdayLetters[(day.weekday - 1) % 7],
                      dayNumber: day.day,
                      isToday: _sameDay(day, today),
                      color: green,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayBar extends StatelessWidget {
  final double fraction; // 0..1
  final String letter;
  final int dayNumber;
  final bool isToday;
  final Color color;

  const _DayBar({
    required this.fraction,
    required this.letter,
    required this.dayNumber,
    required this.isToday,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const trackHeight = 56.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 14,
              height: trackHeight,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.08),
                borderRadius: Radii.all(Radii.xs),
              ),
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  width: 14,
                  decoration: BoxDecoration(
                    color: fraction == 0
                        ? Colors.transparent
                        : color.withValues(alpha: isToday ? 1 : 0.7),
                    borderRadius: Radii.all(Radii.xs),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          letter,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
