import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/quran/views/screens/quran_screen.dart';
import 'package:wadhakir/features/wird/cubit/wird_cubit.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';
import 'package:wadhakir/features/wird/services/wird_schedule_service.dart';

/// "Today" card on the progress screen — shows today's reading and the
/// read-now / mark-complete actions.
class WirdTodayCard extends StatelessWidget {
  final WirdDay day;
  final bool completed;

  const WirdTodayCard({super.key, required this.day, required this.completed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final cubit = context.read<WirdCubit>();

    return FCard.raw(
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
                        '${l10n?.translate('wird.day') ?? 'يوم'} '
                        '${WirdFormat.toArabicDigits(day.dayNumber)}',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        WirdFormat.shortDate(day.date),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        '${l10n?.translate('wird.pages_from') ?? 'صفحات من'} '
                        '${WirdFormat.toArabicDigits(day.startPage)} '
                        '${l10n?.translate('wird.to') ?? 'إلى'} '
                        '${WirdFormat.toArabicDigits(day.endPage)}'
                        '${day.juzLabel.isNotEmpty ? '  •  ${day.juzLabel}' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
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
            Row(
              children: [
                Expanded(
                  child: FButton(
                    onPress: () {
                      cubit.openReaderAtPage(day.startPage);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QuranScreen()),
                      );
                    },
                    variant: FButtonVariant.outline,
                    prefix: const Icon(Icons.menu_book_rounded),
                    child: Text(
                      l10n?.translate('wird.read_now') ?? 'اقرأ الآن',
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
