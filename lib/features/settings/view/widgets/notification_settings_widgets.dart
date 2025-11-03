import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
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
    final isEnabled = settings.notificationSettings.masterEnabled;

    return SwitchListTile(
      title: Text(
        l10n?.translate('settings.enable_notifications') ?? 'تفعيل التنبيهات',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          l10n?.translate('settings.enable_notifications_subtitle') ??
              'إرسال تنبيه عند حلول وقت كل صلاة',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ),
      value: isEnabled,
      onChanged: (value) => cubit.toggleNotifications(value),
      activeThumbColor: theme.colorScheme.primary,
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isEnabled
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isEnabled ? Icons.notifications_active : Icons.notifications_off,
          color: isEnabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          size: 22,
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
    final isEnabled =
        settings.notificationSettings.persistentNotificationEnabled;

    return SwitchListTile(
      title: Text(
        l10n?.translate('settings.persistent_notification') ??
            'إشعار دائم للصلاة القادمة',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          l10n?.translate('settings.persistent_notification_subtitle') ??
              'عرض إشعار دائم يوضح وقت الصلاة القادمة والوقت المتبقي',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ),
      value: isEnabled,
      onChanged: (value) => cubit.togglePersistentNotification(value),
      activeThumbColor: theme.colorScheme.primary,
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isEnabled
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isEnabled ? Icons.push_pin : Icons.push_pin_outlined,
          color: isEnabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          size: 22,
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        l10n?.translate('settings.notification_timing') ?? 'وقت التنبيه',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          l10n?.translate('settings.notification_timing_subtitle') ??
              'اختر متى تريد استلام التنبيه',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.schedule,
          color: theme.colorScheme.primary,
          size: 22,
        ),
      ),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      onTap: () => _showNotificationTimingDialog(context, settings, cubit),
    );
  }

  static void _showNotificationTimingDialog(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n?.translate('settings.notification_timing') ?? 'وقت التنبيه',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimingOption(
              context,
              l10n?.translate('settings.on_time') ?? 'عند الأذان',
              NotificationTiming.onTime,
              settings,
              cubit,
            ),
            _buildTimingOption(
              context,
              l10n?.translate('settings.before_5_min') ?? 'قبل 5 دقائق',
              NotificationTiming.before5Min,
              settings,
              cubit,
            ),
            _buildTimingOption(
              context,
              l10n?.translate('settings.before_10_min') ?? 'قبل 10 دقائق',
              NotificationTiming.before10Min,
              settings,
              cubit,
            ),
            _buildTimingOption(
              context,
              l10n?.translate('settings.before_15_min') ?? 'قبل 15 دقيقة',
              NotificationTiming.before15Min,
              settings,
              cubit,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n?.translate('common.close') ?? 'إغلاق',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTimingOption(
    BuildContext context,
    String title,
    NotificationTiming timing,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final currentTiming = settings.notificationSettings.fajrSettings.timing;
    final theme = Theme.of(context);

    return RadioListTile<NotificationTiming>(
      title: Text(title),
      value: timing,
      groupValue: currentTiming,
      activeColor: theme.colorScheme.primary,
      onChanged: (value) {
        if (value != null) {
          final notificationSettings = settings.notificationSettings;
          final newSettings = notificationSettings.copyWith(
            fajrSettings:
                notificationSettings.fajrSettings.copyWith(timing: value),
            dhuhrSettings:
                notificationSettings.dhuhrSettings.copyWith(timing: value),
            asrSettings:
                notificationSettings.asrSettings.copyWith(timing: value),
            maghribSettings:
                notificationSettings.maghribSettings.copyWith(timing: value),
            ishaSettings:
                notificationSettings.ishaSettings.copyWith(timing: value),
          );
          cubit.setNotificationSettings(newSettings);
          Navigator.pop(context);
        }
      },
    );
  }

  static Widget buildPrayerNotificationsSettings(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.tune,
          color: theme.colorScheme.primary,
          size: 22,
        ),
      ),
      title: Text(
        l10n?.translate('settings.customize_prayers') ?? 'تخصيص كل صلاة',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          l10n?.translate('settings.customize_prayers_subtitle') ??
              'تخصيص التنبيهات لكل صلاة على حدة',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ),
      children: [
        _buildPrayerNotificationTile(
          context,
          'Fajr',
          settings.notificationSettings.fajrSettings,
          cubit,
          Icons.brightness_5_outlined,
        ),
        const Divider(height: 1),
        _buildPrayerNotificationTile(
          context,
          'Dhuhr',
          settings.notificationSettings.dhuhrSettings,
          cubit,
          Icons.wb_sunny_outlined,
        ),
        const Divider(height: 1),
        _buildPrayerNotificationTile(
          context,
          'Asr',
          settings.notificationSettings.asrSettings,
          cubit,
          Icons.wb_twilight_outlined,
        ),
        const Divider(height: 1),
        _buildPrayerNotificationTile(
          context,
          'Maghrib',
          settings.notificationSettings.maghribSettings,
          cubit,
          Icons.nights_stay_outlined,
        ),
        const Divider(height: 1),
        _buildPrayerNotificationTile(
          context,
          'Isha',
          settings.notificationSettings.ishaSettings,
          cubit,
          Icons.bedtime_outlined,
        ),
      ],
    );
  }

  static Widget _buildPrayerNotificationTile(
    BuildContext context,
    String prayerNameEnglish,
    PrayerNotificationSettings prayerSettings,
    SettingsCubit cubit,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

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

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            displayName,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
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
    );
  }
}
