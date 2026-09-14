import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/wird/cubit/wird_state.dart';
import 'package:wadhakir/features/wird/services/quran_structure.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';
import 'package:wadhakir/features/wird/services/wird_schedule_service.dart';

/// Progress summary card ("تقدّمك"): percent, pages read, expected
/// completion date and remaining days.
class WirdProgressHeader extends StatelessWidget {
  final WirdLoaded state;

  const WirdProgressHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final percent = (state.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.translate('wird.your_progress') ?? 'تقدّمك',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${WirdFormat.toArabicDigits(percent)}٪',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            '${l10n?.translate('wird.pages_read') ?? 'التقدم الحالي'}: '
            '${WirdFormat.toArabicDigits(state.pagesRead)} / '
            '${WirdFormat.toArabicDigits(kTotalPages)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.onPrimary.withValues(
                alpha: 0.25,
              ),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
            ),
          ),
          const SizedBox(height: Spacing.md),
          if (state.expectedCompletionDate != null)
            Text(
              '${l10n?.translate('wird.expected_completion') ?? 'موعد الختم المتوقع'}: '
              '${WirdFormat.longDate(state.expectedCompletionDate!)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
              ),
            ),
          const SizedBox(height: Spacing.xxs),
          Text(
            '${l10n?.translate('wird.remaining_days') ?? 'الأيام المتبقية'}: '
            '${WirdFormat.toArabicDigits(state.remainingDays)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          ..._paceLine(context),
        ],
      ),
    );
  }

  /// "متأخر / متقدم / على المسار / تمت الختمة" line under the stats. Hidden
  /// when there is no active pace (notStarted).
  List<Widget> _paceLine(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    if (state.pace == WirdPace.notStarted) return const [];

    final (String emoji, String text) = switch (state.pace) {
      WirdPace.finished => (
        '🎉',
        l10n?.translate('wird.finished_short') ?? 'تمت الختمة',
      ),
      WirdPace.behind => (
        '😔',
        '${l10n?.translate('wird.behind_by') ?? 'أنت متأخر بـ'} '
            '${WirdFormat.daysLabel(state.daysLate)}',
      ),
      WirdPace.ahead => (
        '🌟',
        '${l10n?.translate('wird.ahead_by') ?? 'أنت متقدم بـ'} '
            '${WirdFormat.daysLabel(state.daysAhead)}',
      ),
      _ => ('📖', l10n?.translate('wird.on_track') ?? 'أنت على المسار'),
    };

    return [
      const SizedBox(height: Spacing.sm),
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: Spacing.xs),
            Flexible(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
