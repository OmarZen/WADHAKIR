import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/azkar_reminder_settings_model.dart';
import 'package:wadhakir/features/azkar_reminders/cubit/azkar_reminders_cubit.dart';
import 'package:wadhakir/features/azkar_reminders/cubit/azkar_reminders_state.dart';
import 'package:wadhakir/features/azkar_reminders/views/widgets/azkar_reminder_toggle_card.dart';

/// Qiyam al-Layl reminder: a toggle plus a mode selector (last third of the
/// night — auto from prayer times — vs a fixed time). Self-contained so it can
/// live on both the azkar settings page and the prayer-times page (both have
/// the top-level [AzkarRemindersCubit] in scope).
class QiyamReminderTile extends StatelessWidget {
  const QiyamReminderTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final l10n = context.l10n;

    return BlocBuilder<AzkarRemindersCubit, AzkarRemindersState>(
      builder: (context, state) {
        final s = state.settings;
        final cubit = context.read<AzkarRemindersCubit>();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: s.qiyamEnabled
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : (isDark ? theme.colorScheme.surface : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: s.qiyamEnabled
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: isDark ? 0.18 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.nightlight_round,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n?.translate('azkar_reminders.qiyam') ?? 'قيام الليل',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: s.qiyamEnabled,
                      onChanged: (v) => requestAzkarEnable(
                        context,
                        enable: v,
                        onGranted: () => cubit.setQiyamEnabled(true),
                        onDisable: () => cubit.setQiyamEnabled(false),
                      ),
                      activeThumbColor: theme.colorScheme.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              if (s.qiyamEnabled) ...[
                const SizedBox(height: 10),
                _ModeChip(
                  label:
                      l10n?.translate('azkar_reminders.qiyam_last_third') ??
                      'الثلث الأخير من الليل',
                  selected: s.qiyamMode == QiyamMode.lastThird,
                  onTap: () => cubit.setQiyamMode(QiyamMode.lastThird),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _ModeChip(
                        label:
                            l10n?.translate('azkar_reminders.qiyam_fixed') ??
                            'وقت محدد',
                        selected: s.qiyamMode == QiyamMode.fixed,
                        onTap: () => cubit.setQiyamMode(QiyamMode.fixed),
                      ),
                    ),
                    if (s.qiyamMode == QiyamMode.fixed) ...[
                      const SizedBox(width: 8),
                      _FixedTimeChip(
                        label: TimeOfDay(
                          hour: s.qiyamHour,
                          minute: s.qiyamMinute,
                        ).format(context),
                        onTap: () => pickAzkarTime(
                          context,
                          s.qiyamHour,
                          s.qiyamMinute,
                          cubit.setQiyamTime,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FixedTimeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FixedTimeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
