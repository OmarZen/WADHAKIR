import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';
import 'package:wadhakir/features/wird/services/wird_schedule_service.dart';

/// A single day row in the reading schedule ("جدول القراءة").
///
/// Tapping the card body opens the reader at this day ([onOpen]); the
/// completion circle toggles complete independently ([onToggle]). Visuals
/// adapt to four states: completed, current wird, overdue, and future.
class WirdDayTile extends StatelessWidget {
  final WirdDay day;
  final bool completed;

  /// True for the "current wird" (first incomplete day).
  final bool isCurrent;

  /// True for a past, still-incomplete day (the user fell behind on it).
  final bool isOverdue;

  /// Tap handler for the completion circle. Null ⇒ read-only (preview mode).
  final VoidCallback? onToggle;

  /// Tap handler for the card body (open the reader). Null ⇒ not tappable.
  final VoidCallback? onOpen;

  const WirdDayTile({
    super.key,
    required this.day,
    required this.completed,
    this.isCurrent = false,
    this.isOverdue = false,
    this.onToggle,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final primary = theme.colorScheme.primary;
    final error = theme.colorScheme.error;

    // Accent + optional state chip driven by the day's status.
    final Color accent = completed
        ? primary
        : isCurrent
        ? primary
        : isOverdue
        ? error
        : theme.colorScheme.onSurface.withValues(alpha: 0.4);

    final card = FCard(
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
                  Row(
                    children: [
                      Text(
                        '${l10n?.translate('wird.day') ?? 'يوم'} '
                        '${WirdFormat.toArabicDigits(day.dayNumber)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: completed ? primary : null,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      _StateChip(
                        isCurrent: isCurrent,
                        isOverdue: isOverdue,
                        completed: completed,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    '${l10n?.translate('wird.pages_from') ?? 'صفحات من'} '
                    '${WirdFormat.toArabicDigits(day.startPage)} '
                    '${l10n?.translate('wird.to') ?? 'إلى'} '
                    '${WirdFormat.toArabicDigits(day.endPage)}'
                    '${day.juzLabel.isNotEmpty ? '  •  ${WirdFormat.toArabicDigits(day.juzLabel)}' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Row(
                    children: [
                      Text(
                        WirdFormat.shortDate(day.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                      if (onOpen != null) ...[
                        const SizedBox(width: Spacing.sm),
                        Icon(
                          Icons.menu_book_rounded,
                          size: 14,
                          color: primary.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
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

    final bordered = Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: (isCurrent || isOverdue)
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: isCurrent ? 0.7 : 0.5),
                width: isCurrent ? 1.6 : 1.0,
              ),
            )
          : null,
      child: card,
    );

    if (onOpen == null) return bordered;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: bordered,
    );
  }
}

/// Small status pill: "الورد الحالي" / "متأخّر" / "مكتمل".
class _StateChip extends StatelessWidget {
  final bool isCurrent;
  final bool isOverdue;
  final bool completed;

  const _StateChip({
    required this.isCurrent,
    required this.isOverdue,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final ({String label, Color color})? info;
    if (completed) {
      info = null; // the green circle already conveys completion
    } else if (isCurrent) {
      info = (
        label: l10n?.translate('wird.chip_current') ?? 'الورد الحالي',
        color: theme.colorScheme.primary,
      );
    } else if (isOverdue) {
      info = (
        label: l10n?.translate('wird.chip_overdue') ?? 'متأخّر',
        color: theme.colorScheme.error,
      );
    } else {
      info = null;
    }

    if (info == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 1),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: info.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        info.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: info.color,
          fontWeight: FontWeight.bold,
        ),
      ),
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
    // GestureDetector here consumes the tap so it does not bubble to the
    // card's onOpen handler.
    return GestureDetector(
      onTap: onTap,
      child: InkResponse(onTap: onTap, radius: 26, child: circle),
    );
  }
}
