import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';
import 'package:wadhakir/features/wird/services/wird_schedule_service.dart';

/// A single day row in the reading schedule ("جدول القراءة").
class WirdDayTile extends StatelessWidget {
  final WirdDay day;
  final bool completed;
  final bool isToday;

  /// Tap handler for the completion circle. Null ⇒ read-only (preview mode).
  final VoidCallback? onToggle;

  const WirdDayTile({
    super.key,
    required this.day,
    required this.completed,
    required this.isToday,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final primary = theme.colorScheme.primary;

    final card = FCard.raw(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n?.translate('wird.day') ?? 'يوم'} '
                    '${WirdFormat.toArabicDigits(day.dayNumber)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: completed ? primary : null,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    '${l10n?.translate('wird.pages_from') ?? 'صفحات من'} '
                    '${WirdFormat.toArabicDigits(day.startPage)} '
                    '${l10n?.translate('wird.to') ?? 'إلى'} '
                    '${WirdFormat.toArabicDigits(day.endPage)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    WirdFormat.shortDate(day.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            _CompletionCircle(
              completed: completed,
              onTap: onToggle,
              color: primary,
            ),
          ],
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: isToday
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primary.withValues(alpha: 0.6)),
            )
          : null,
      child: card,
    );
  }
}

class _CompletionCircle extends StatelessWidget {
  final bool completed;
  final VoidCallback? onTap;
  final Color color;

  const _CompletionCircle({
    required this.completed,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final circle = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? color : Colors.transparent,
        border: Border.all(
          color: completed
              ? color
              : theme.colorScheme.onSurface.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: completed
          ? Icon(Icons.check, size: 20, color: theme.colorScheme.onPrimary)
          : null,
    );
    if (onTap == null) return circle;
    return InkResponse(onTap: onTap, radius: 26, child: circle);
  }
}
