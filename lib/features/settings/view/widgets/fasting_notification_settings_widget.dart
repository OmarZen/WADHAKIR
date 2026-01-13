import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';

class FastingNotificationSettingsWidget extends StatelessWidget {
  const FastingNotificationSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // This is a container widget, children use static methods
    return const SizedBox.shrink();
  }

  /// Build Monday fasting toggle
  static Widget buildMondayFastingToggle(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = settings.notificationSettings.mondayFastingEnabled;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isEnabled
            ? (isDark
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.primary.withValues(alpha: 0.08))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Text(
          l10n?.translate('settings.fasting_monday') ?? 'صيام الإثنين',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n?.translate('settings.fasting_monday_subtitle') ??
                'تذكير بصيام يوم الإثنين',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
        value: isEnabled,
        onChanged: (value) async {
          await cubit.toggleMondayFasting(value);
        },
        activeThumbColor: theme.colorScheme.primary,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.calendar_today,
            color: isEnabled
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            size: 18,
          ),
        ),
      ),
    );
  }

  /// Build Thursday fasting toggle
  static Widget buildThursdayFastingToggle(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = settings.notificationSettings.thursdayFastingEnabled;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isEnabled
            ? (isDark
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.primary.withValues(alpha: 0.08))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Text(
          l10n?.translate('settings.fasting_thursday') ?? 'صيام الخميس',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n?.translate('settings.fasting_thursday_subtitle') ??
                'تذكير بصيام يوم الخميس',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
        value: isEnabled,
        onChanged: (value) async {
          await cubit.toggleThursdayFasting(value);
        },
        activeThumbColor: theme.colorScheme.primary,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.calendar_today,
            color: isEnabled
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            size: 18,
          ),
        ),
      ),
    );
  }

  /// Build fasting notification time picker
  static Widget buildFastingTimePicker(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentTime = settings.notificationSettings.fastingNotificationTime;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Text(
          l10n?.translate('settings.fasting_time') ?? 'وقت التنبيه',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n?.translate('settings.fasting_time_subtitle') ??
                'وقت إرسال التذكير (الليلة السابقة)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.access_time,
            color: theme.colorScheme.onPrimary,
            size: 18,
          ),
        ),
        trailing: InkWell(
          onTap: () => _showTimePickerDialog(context, settings, cubit),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.primary, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(currentTime),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit, size: 14, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show time picker dialog
  static void _showTimePickerDialog(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) async {
    final currentTime = settings.notificationSettings.fastingNotificationTime;
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final timeString =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      await cubit.setFastingNotificationTime(timeString);
    }
  }

  /// Format time string for display
  static String _formatTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];

    if (hour == 0) {
      return '12:$minute ص';
    } else if (hour < 12) {
      return '$hour:$minute ص';
    } else if (hour == 12) {
      return '12:$minute م';
    } else {
      return '${hour - 12}:$minute م';
    }
  }
}
