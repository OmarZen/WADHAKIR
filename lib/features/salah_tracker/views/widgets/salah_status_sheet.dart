import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';
import 'package:wadhakir/features/salah_tracker/views/widgets/salah_status_ui.dart';

/// Bottom sheet to choose a prayer's status. Returns the chosen [PrayerStatus]
/// (including [PrayerStatus.notLogged] to clear), or null if dismissed.
///
/// [allowOnTime] is false for past days where on-time/late can't be inferred —
/// only qada / missed (and clear) are offered.
Future<PrayerStatus?> showSalahStatusSheet(
  BuildContext context, {
  required PrayerSlot slot,
  required PrayerStatus current,
  bool allowOnTime = true,
}) {
  final options = <PrayerStatus>[
    if (allowOnTime) PrayerStatus.onTime,
    if (allowOnTime) PrayerStatus.late,
    PrayerStatus.qada,
    PrayerStatus.missed,
    PrayerStatus.notLogged,
  ];

  final theme = Theme.of(context);

  return showModalBottomSheet<PrayerStatus>(
    context: context,
    showDragHandle: true,
    backgroundColor: theme.colorScheme.surface,
    clipBehavior: Clip.antiAlias,
    // Rounded top corners matching the app's brand radii.
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
    ),
    // Let the sheet size to its content (and scroll if a small screen / large
    // text scale would otherwise overflow the default capped height).
    isScrollControlled: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final cs = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: prayer name + a short instruction.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.xl,
                Spacing.xs,
                Spacing.xl,
                Spacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SalahStatusUi.slotLabel(sheetContext, slot),
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n?.translate('salah_tracker.choose_status') ??
                        'اختر حالة الصلاة',
                    style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  0,
                  Spacing.md,
                  Spacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final status in options)
                      _StatusTile(
                        status: status,
                        selected: status == current,
                        onTap: () => Navigator.of(sheetContext).pop(status),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _StatusTile extends StatelessWidget {
  final PrayerStatus status;
  final bool selected;
  final VoidCallback onTap;

  const _StatusTile({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = SalahStatusUi.color(context, status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xxs),
      child: Material(
        color: selected ? color.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: Radii.all(Radii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.all(Radii.md),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: Radii.all(Radii.md),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.45)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.md,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: Radii.all(Radii.sm),
                  ),
                  child: Icon(
                    SalahStatusUi.icon(status),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    SalahStatusUi.statusLabel(context, status),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
