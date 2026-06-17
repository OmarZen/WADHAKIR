import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/utils/alarm_permission_helper.dart';

/// Request notification (+ exact-alarm) permission before enabling a reminder;
/// disabling is immediate. Shared by the settings page and the contextual
/// prayer-page tiles so the permission flow is identical everywhere.
Future<void> requestAzkarEnable(
  BuildContext context, {
  required bool enable,
  required VoidCallback onGranted,
  required VoidCallback onDisable,
}) async {
  if (!enable) {
    onDisable();
    return;
  }
  final permissions = await AlarmPermissionHelper.requestAllPermissions(context);
  if (permissions['notifications'] == true) {
    onGranted();
  }
}

/// Open a time picker seeded with [hour]:[minute] and report the result.
Future<void> pickAzkarTime(
  BuildContext context,
  int hour,
  int minute,
  void Function(int hour, int minute) onPicked,
) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: hour, minute: minute),
  );
  if (picked != null) onPicked(picked.hour, picked.minute);
}

/// A compact reminder row: icon + title (+ optional subtitle / time chip) and a
/// switch. Optionally shows a tappable time chip or a trailing control (e.g. a
/// delay stepper) below the row when enabled.
class AzkarReminderToggleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onToggle;

  /// When set (and enabled), shows a tappable time chip.
  final String? timeLabel;
  final VoidCallback? onEditTime;

  /// Arbitrary trailing control shown below the row when enabled.
  final Widget? trailingAction;

  const AzkarReminderToggleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onToggle,
    this.subtitle,
    this.timeLabel,
    this.onEditTime,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: value
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : (isDark ? theme.colorScheme.surface : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.onSurface.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: Column(
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
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value && timeLabel != null && onEditTime != null) ...[
                _TimeChip(label: timeLabel!, onTap: onEditTime!),
                const SizedBox(width: 8),
              ],
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: value,
                  onChanged: onToggle,
                  activeThumbColor: theme.colorScheme.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (value && trailingAction != null) ...[
            const SizedBox(height: 10),
            trailingAction!,
          ],
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A +/- stepper (5-minute steps) used for the after-prayer reminder delay.
class AzkarDelayStepper extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;
  const AzkarDelayStepper({
    super.key,
    required this.minutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          context.l10n?.translate('azkar_reminders.delay_label') ??
              'مدة التأخير',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_circle_outline),
          color: theme.colorScheme.primary,
          onPressed: minutes > 5 ? () => onChanged(minutes - 5) : null,
        ),
        Text(
          '$minutes د',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_circle_outline),
          color: theme.colorScheme.primary,
          onPressed: minutes < 60 ? () => onChanged(minutes + 5) : null,
        ),
      ],
    );
  }
}
