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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isEnabled
                      ? [
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                        ]
                      : [
                          theme.colorScheme.surface,
                          theme.colorScheme.surface,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isEnabled
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                title: Text(
                  l10n?.translate('settings.enable_notifications') ??
                      'تفعيل التنبيهات',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
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
                onChanged: (value) => cubit.toggleNotifications(value),
                activeColor: theme.colorScheme.primary,
                secondary: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: isEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isEnabled
                      ? [
                          theme.colorScheme.secondary.withValues(alpha: 0.15),
                          theme.colorScheme.secondary.withValues(alpha: 0.05),
                        ]
                      : [
                          theme.colorScheme.surface,
                          theme.colorScheme.surface,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isEnabled
                      ? theme.colorScheme.secondary.withValues(alpha: 0.3)
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                title: Text(
                  l10n?.translate('settings.persistent_notification') ??
                      'إشعار دائم للصلاة القادمة',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n?.translate(
                            'settings.persistent_notification_subtitle') ??
                        'عرض إشعار دائم يوضح وقت الصلاة القادمة والوقت المتبقي',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
                value: isEnabled,
                onChanged: (value) => cubit.togglePersistentNotification(value),
                activeColor: theme.colorScheme.secondary,
                secondary: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? theme.colorScheme.secondary.withValues(alpha: 0.15)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isEnabled ? Icons.push_pin : Icons.push_pin_outlined,
                    color: isEnabled
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget buildNotificationTimingSelector(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                title: Text(
                  l10n?.translate('settings.notification_timing') ??
                      'وقت التنبيه',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.2),
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.schedule,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                onTap: () =>
                    _showNotificationTimingDialog(context, settings, cubit),
              ),
            ),
          ),
        );
      },
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
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return Transform.scale(
          scale: curvedAnimation.value,
          child: Opacity(
            opacity: animation.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n?.translate('settings.notification_timing') ??
                          'وقت التنبيه',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
                        horizontal: 24, vertical: 12),
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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: InkWell(
              onTap: () {
                final notificationSettings = settings.notificationSettings;
                final newSettings = notificationSettings.copyWith(
                  fajrSettings: notificationSettings.fajrSettings
                      .copyWith(timing: timing),
                  dhuhrSettings: notificationSettings.dhuhrSettings
                      .copyWith(timing: timing),
                  asrSettings:
                      notificationSettings.asrSettings.copyWith(timing: timing),
                  maghribSettings: notificationSettings.maghribSettings
                      .copyWith(timing: timing),
                  ishaSettings: notificationSettings.ishaSettings
                      .copyWith(timing: timing),
                );
                cubit.setNotificationSettings(newSettings);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                            theme.colorScheme.primary.withValues(alpha: 0.05),
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isSelected)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (context, checkValue, child) {
                          return Transform.scale(
                            scale: checkValue,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.tertiary.withValues(alpha: 0.2),
                          theme.colorScheme.tertiary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: theme.colorScheme.tertiary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    l10n?.translate('settings.customize_prayers') ??
                        'تخصيص كل صلاة',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l10n?.translate('settings.customize_prayers_subtitle') ??
                          'تخصيص التنبيهات لكل صلاة على حدة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.08),
                          theme.colorScheme.primary.withValues(alpha: 0.03),
                        ],
                      )
                    : null,
                color: isEnabled
                    ? null
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEnabled
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isEnabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
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
                activeColor: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
