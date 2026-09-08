import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/quran/views/screens/quran_screen.dart';
import 'package:wadhakir/features/wird/cubit/wird_cubit.dart';
import 'package:wadhakir/features/wird/cubit/wird_state.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';
import 'package:wadhakir/features/wird/services/wird_motivations.dart';
import 'package:wadhakir/features/wird/services/wird_schedule_service.dart';

/// "Current wird" card on the progress screen — shows the day to read now,
/// the pace status (متأخر / متقدم / على المسار), a motivational line, and the
/// read/continue + mark-complete actions. Falls back to a celebratory card
/// when the whole ختمة is finished.
class WirdTodayCard extends StatelessWidget {
  final WirdLoaded state;

  const WirdTodayCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final cubit = context.read<WirdCubit>();

    if (state.isFinished) {
      return _FinishedCard(state: state);
    }

    final idx = state.currentDayIndex;
    if (idx < 0 || idx >= state.schedule.length) {
      return const SizedBox.shrink();
    }
    final day = state.schedule[idx];
    final completed = state.plan.completedDayIndices.contains(day.dayIndex);
    final hasResume = cubit.hasResumePoint;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.translate('wird.current_wird_title') ??
                            'وردك الحالي',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        '${l10n?.translate('wird.day') ?? 'يوم'} '
                        '${WirdFormat.toArabicDigits(day.dayNumber)}',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        '${l10n?.translate('wird.pages_from') ?? 'صفحات من'} '
                        '${WirdFormat.toArabicDigits(day.startPage)} '
                        '${l10n?.translate('wird.to') ?? 'إلى'} '
                        '${WirdFormat.toArabicDigits(day.endPage)}'
                        '${day.juzLabel.isNotEmpty ? '  •  ${WirdFormat.toArabicDigits(day.juzLabel)}' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      // One muted line, every day. The dedication is why this
                      // khatma is being read, so it belongs on the card the
                      // user actually looks at — not buried in setup.
                      if (state.plan.dedication case final d?
                          when d.trim().isNotEmpty) ...[
                        const SizedBox(height: Spacing.xxs),
                        Text(
                          '${l10n?.translate('wird.dedicated_to') ?? 'إهداءً إلى'} '
                          '${d.trim()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (completed)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            _PaceBanner(state: state),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    onPress: () async {
                      cubit.openReaderAtPage(cubit.resumePageForCurrentDay());
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QuranScreen()),
                      );
                      await cubit.saveReaderStopPage();
                    },
                    variant: FButtonVariant.outline,
                    prefix: Icon(
                      hasResume
                          ? Icons.play_circle_outline
                          : Icons.menu_book_rounded,
                    ),
                    child: Text(
                      hasResume
                          ? (l10n?.translate('wird.continue_reading') ??
                                'متابعة القراءة')
                          : (l10n?.translate('wird.read_now') ?? 'اقرأ الآن'),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: FButton(
                    onPress: () => cubit.toggleTodayComplete(),
                    prefix: Icon(completed ? Icons.undo : Icons.check),
                    child: Text(
                      completed
                          ? (l10n?.translate('wird.mark_incomplete') ??
                                'إلغاء الإكمال')
                          : (l10n?.translate('wird.mark_complete') ??
                                'حدد اليوم كمكتمل'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pace status pill + motivational line shown inside the current-wird card.
class _PaceBanner extends StatelessWidget {
  final WirdLoaded state;

  const _PaceBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final ({String emoji, String text, Color color, List<String> bucket}) info =
        switch (state.pace) {
          WirdPace.behind => (
            emoji: '😔',
            text:
                '${l10n?.translate('wird.behind_by') ?? 'أنت متأخر بـ'} '
                '${WirdFormat.daysLabel(state.daysLate)}',
            color: theme.colorScheme.error,
            bucket: WirdMotivations.behind,
          ),
          WirdPace.ahead => (
            emoji: '🌟',
            text:
                '${l10n?.translate('wird.ahead_by') ?? 'أنت متقدم بـ'} '
                '${WirdFormat.daysLabel(state.daysAhead)}',
            color: theme.colorScheme.primary,
            bucket: WirdMotivations.ahead,
          ),
          _ => (
            emoji: '📖',
            text: l10n?.translate('wird.on_track') ?? 'أنت على المسار',
            color: theme.colorScheme.primary,
            bucket: WirdMotivations.onTrack,
          ),
        };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: info.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(info.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.text,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: info.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Spacing.xxs),
                Text(
                  WirdMotivations.pick(info.bucket),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

/// Celebratory card shown when every day is complete.
class _FinishedCard extends StatelessWidget {
  final WirdLoaded state;

  const _FinishedCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final cubit = context.read<WirdCubit>();

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Text('🎉', style: TextStyle(fontSize: 40))),
            const SizedBox(height: Spacing.sm),
            Text(
              l10n?.translate('wird.finished_title') ??
                  'أتممت ختمتك! تقبّل الله',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Spacing.xxs),
            Text(
              WirdMotivations.pick(WirdMotivations.finished),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: Spacing.md),
            FButton(
              onPress: () => cubit.resetPlan(),
              prefix: const Icon(Icons.refresh),
              child: Text(
                l10n?.translate('wird.start_new_khatma') ?? 'ابدأ ختمة جديدة',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
