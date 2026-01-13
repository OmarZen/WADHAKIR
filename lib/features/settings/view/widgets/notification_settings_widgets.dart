import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/core/utils/alarm_permission_helper.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';

class NotificationSettingsWidgets extends StatelessWidget {
  const NotificationSettingsWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    // This is a container widget, children use static methods
    return const SizedBox.shrink();
  }

  static Widget buildNotificationMasterToggle(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = settings.notificationSettings.masterEnabled;

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
          l10n?.translate('settings.enable_notifications') ?? 'تفعيل التنبيهات',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n?.translate('settings.enable_notifications_subtitle') ??
                'إرسال تنبيه عند حلول وقت كل صلاة',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
        value: isEnabled,
        onChanged: (value) async {
          if (value) {
            // Request permissions before enabling
            final permissions =
                await AlarmPermissionHelper.requestAllPermissions(context);

            // Only enable if we got notification permission at minimum
            if (permissions['notifications'] == true) {
              cubit.toggleNotifications(value);

              // Show warning if exact alarm permission was denied
              if (permissions['exactAlarms'] != true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.translate(
                            'settings.exact_alarm_permission_warning',
                          ) ??
                          'لن تصل التنبيهات في الوقت المحدد بدون إذن "التنبيهات والتذكيرات"',
                    ),
                    action: SnackBarAction(
                      label:
                          l10n?.translate('settings.settings') ?? 'الإعدادات',
                      onPressed: () =>
                          AlarmPermissionHelper.showPermissionDeniedDialog(
                            context,
                          ),
                    ),
                  ),
                );
              }
            }
          } else {
            // Disable notifications
            cubit.toggleNotifications(value);
          }
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
            isEnabled ? Icons.notifications_active : Icons.notifications_off,
            color: isEnabled
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            size: 18,
          ),
        ),
      ),
    );
  }

  static Widget buildPersistentNotificationToggle(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled =
        settings.notificationSettings.persistentNotificationEnabled;

    // Check if platform is Windows - persistent notifications not supported
    final bool isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

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
          l10n?.translate('settings.persistent_notification') ??
              'إشعار دائم للصلاة القادمة',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.translate('settings.persistent_notification_subtitle') ??
                    'عرض إشعار دائم يوضح وقت الصلاة القادمة والوقت المتبقي',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n?.translate(
                              'settings.persistent_notification_mobile_only',
                            ) ??
                            'هذه الميزة متاحة على الهواتف فقط',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        value: isEnabled,
        onChanged: isDesktop
            ? null
            : (value) => cubit.togglePersistentNotification(value),
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
            isEnabled ? Icons.push_pin : Icons.push_pin_outlined,
            color: isEnabled
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            size: 18,
          ),
        ),
      ),
    );
  }

  static Widget buildNotificationTimingSelector(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          l10n?.translate('settings.notification_timing') ?? 'وقت التنبيه',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n?.translate('settings.notification_timing_subtitle') ??
                'اختر متى تريد استلام التنبيه',
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
            Icons.schedule,
            color: theme.colorScheme.onPrimary,
            size: 18,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onTap: () => _showNotificationTimingDialog(context, settings, cubit),
      ),
    );
  }

  static void _showNotificationTimingDialog(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: Curves.easeOut.transform(animation.value),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n?.translate('settings.notification_timing') ??
                          'وقت التنبيه',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTimingOption(
                    context,
                    l10n?.translate('settings.on_time') ?? 'عند الأذان',
                    NotificationTiming.onTime,
                    Icons.alarm,
                    settings,
                    cubit,
                    0,
                  ),
                  const SizedBox(height: 8),
                  _buildTimingOption(
                    context,
                    l10n?.translate('settings.before_5_min') ?? 'قبل 5 دقائق',
                    NotificationTiming.before5Min,
                    Icons.alarm_on,
                    settings,
                    cubit,
                    1,
                  ),
                  const SizedBox(height: 8),
                  _buildTimingOption(
                    context,
                    l10n?.translate('settings.before_10_min') ?? 'قبل 10 دقائق',
                    NotificationTiming.before10Min,
                    Icons.timer,
                    settings,
                    cubit,
                    2,
                  ),
                  const SizedBox(height: 8),
                  _buildTimingOption(
                    context,
                    l10n?.translate('settings.before_15_min') ?? 'قبل 15 دقيقة',
                    NotificationTiming.before15Min,
                    Icons.timer_10_select,
                    settings,
                    cubit,
                    3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    l10n?.translate('common.close') ?? 'إغلاق',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildTimingOption(
    BuildContext context,
    String title,
    NotificationTiming timing,
    IconData icon,
    AppSettingsModel settings,
    SettingsCubit cubit,
    int index,
  ) {
    final currentTiming = settings.notificationSettings.fajrSettings.timing;
    final theme = Theme.of(context);
    final isSelected = currentTiming == timing;

    return InkWell(
      onTap: () {
        final notificationSettings = settings.notificationSettings;
        final newSettings = notificationSettings.copyWith(
          fajrSettings: notificationSettings.fajrSettings.copyWith(
            timing: timing,
          ),
          dhuhrSettings: notificationSettings.dhuhrSettings.copyWith(
            timing: timing,
          ),
          asrSettings: notificationSettings.asrSettings.copyWith(
            timing: timing,
          ),
          maghribSettings: notificationSettings.maghribSettings.copyWith(
            timing: timing,
          ),
          ishaSettings: notificationSettings.ishaSettings.copyWith(
            timing: timing,
          ),
        );
        cubit.setNotificationSettings(newSettings);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildPrayerNotificationsSettings(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          l10n?.translate('settings.customize_prayers') ?? 'تخصيص كل صلاة',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n?.translate('settings.customize_prayers_subtitle') ??
                'تخصيص التنبيهات لكل صلاة على حدة',
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
            Icons.tune,
            color: isDark
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onPrimary,
            size: 18,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onTap: () => _showPrayerCustomizationDialog(context, settings, cubit),
      ),
    );
  }

  static void _showPrayerCustomizationDialog(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: Curves.easeOut.transform(animation.value),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: theme.colorScheme.onTertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n?.translate('settings.customize_prayers') ??
                          'تخصيص كل صلاة',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPrayerNotificationTile(
                      context,
                      'Fajr',
                      settings.notificationSettings.fajrSettings,
                      cubit,
                      Icons.wb_twilight,
                      0,
                    ),
                    const SizedBox(height: 8),
                    _buildPrayerNotificationTile(
                      context,
                      'Dhuhr',
                      settings.notificationSettings.dhuhrSettings,
                      cubit,
                      Icons.wb_sunny,
                      1,
                    ),
                    const SizedBox(height: 8),
                    _buildPrayerNotificationTile(
                      context,
                      'Asr',
                      settings.notificationSettings.asrSettings,
                      cubit,
                      Icons.wb_cloudy,
                      2,
                    ),
                    const SizedBox(height: 8),
                    _buildPrayerNotificationTile(
                      context,
                      'Maghrib',
                      settings.notificationSettings.maghribSettings,
                      cubit,
                      Icons.nights_stay,
                      3,
                    ),
                    const SizedBox(height: 8),
                    _buildPrayerNotificationTile(
                      context,
                      'Isha',
                      settings.notificationSettings.ishaSettings,
                      cubit,
                      Icons.dark_mode,
                      4,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    l10n?.translate('common.close') ?? 'إغلاق',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildPrayerNotificationTile(
    BuildContext context,
    String prayerNameEnglish,
    PrayerNotificationSettings prayerSettings,
    SettingsCubit cubit,
    IconData icon,
    int index,
  ) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    // Prayer name translations
    final prayerNames = {
      'Fajr': {'ar': 'الفجر', 'en': 'Fajr'},
      'Dhuhr': {'ar': 'الظهر', 'en': 'Dhuhr'},
      'Asr': {'ar': 'العصر', 'en': 'Asr'},
      'Maghrib': {'ar': 'المغرب', 'en': 'Maghrib'},
      'Isha': {'ar': 'العشاء', 'en': 'Isha'},
    };

    final isArabic = l10n?.locale.languageCode == 'ar';
    final displayName = isArabic
        ? (prayerNames[prayerNameEnglish]?['ar'] ?? prayerNameEnglish)
        : (prayerNames[prayerNameEnglish]?['en'] ?? prayerNameEnglish);

    final isEnabled = prayerSettings.enabled;

    return Container(
      margin: const EdgeInsets.all(0),
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isEnabled
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              displayName,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        value: prayerSettings.enabled,
        onChanged: (value) {
          final newSettings = prayerSettings.copyWith(enabled: value);
          cubit.updatePrayerNotificationSettings(
            prayerName: prayerNameEnglish,
            prayerSettings: newSettings,
          );
        },
        activeThumbColor: theme.colorScheme.primary,
      ),
    );
  }
}
