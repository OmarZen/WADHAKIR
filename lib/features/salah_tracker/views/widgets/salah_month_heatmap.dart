import 'package:flutter/material.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/features/salah_tracker/services/salah_stats_service.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';

/// Gregorian monthly heatmap: a 7-column grid (week starts Saturday) where each
/// day cell is shaded by prayers-completed (0..5). Built like the moon calendar
/// grid — no external calendar widget.
class SalahMonthHeatmap extends StatelessWidget {
  final SalahLogModel log;
  final DateTime today;
  final SalahStatsService stats;

  const SalahMonthHeatmap({
    super.key,
    required this.log,
    required this.today,
    required this.stats,
  });

  // Week starts on Saturday. Columns: Sat Sun Mon Tue Wed Thu Fri.
  static const List<String> _headers = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

  static int _columnOf(DateTime date) =>
      (date.weekday - DateTime.saturday + 7) % 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final green = isDark ? darkPrayerAzkarColor : prayerAzkarColor;
    final l10n = context.l10n;

    final firstOfMonth = DateTime(today.year, today.month, 1);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final leadingBlanks = _columnOf(firstOfMonth);
    final heatmap = stats.monthlyHeatmap(log, today);
    final month = stats.monthStats(log, today);
    final percent = (month.completionFraction * 100).round();

    // Cells: leading blanks (null) then each day number.
    final cells = <int?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var d = 1; d <= daysInMonth; d++) d,
    ];

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
                l10n?.translate('salah_tracker.month_completion') ??
                    'إتمام هذا الشهر',
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
          Row(
            children: [
              for (final h in _headers)
                Expanded(
                  child: Center(
                    child: Text(
                      h,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Spacing.xs,
            crossAxisSpacing: Spacing.xs,
            children: [
              for (final cell in cells)
                if (cell == null)
                  const SizedBox.shrink()
                else
                  _DayCell(
                    day: cell,
                    prayed:
                        heatmap[SalahLogModel.dateKey(
                          DateTime(today.year, today.month, cell),
                        )] ??
                        0,
                    isToday: cell == today.day,
                    isFuture: cell > today.day,
                    isExcused: log.isExcusedDay(
                      DateTime(today.year, today.month, cell),
                    ),
                    green: green,
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final int prayed; // 0..5
  final bool isToday;
  final bool isFuture;
  final bool isExcused;
  final Color green;

  const _DayCell({
    required this.day,
    required this.prayed,
    required this.isToday,
    required this.isFuture,
    required this.isExcused,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color fill;
    if (isExcused) {
      // Neutral, not empty. An excused day rendered as an empty cell would read
      // as a day she failed — which is precisely the guilt this feature exists
      // to remove. A soft neutral tint says "this day was set aside" instead.
      fill = cs.onSurface.withValues(alpha: 0.13);
    } else if (isFuture || prayed == 0) {
      fill = cs.onSurface.withValues(alpha: 0.06);
    } else {
      // 1..5 -> alpha 0.30 .. 1.0
      fill = green.withValues(alpha: 0.30 + 0.70 * (prayed / 5));
    }
    final onFill = (!isFuture && !isExcused && prayed >= 3)
        ? Colors.white
        : cs.onSurface.withValues(alpha: isFuture ? 0.4 : 0.8);

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: Radii.all(Radii.sm),
        border: isToday
            ? Border.all(color: cs.primary, width: 1.6)
            : isExcused
            ? Border.all(color: cs.onSurface.withValues(alpha: 0.18))
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        WirdFormat.toArabicDigits(day),
        style: theme.textTheme.labelSmall?.copyWith(
          color: onFill,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
