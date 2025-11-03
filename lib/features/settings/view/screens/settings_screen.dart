import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';
import 'package:wadhakir/features/settings/view/widgets/settings_section.dart';
import 'package:wadhakir/features/pray_times/services/prayer_notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0.97),
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SettingsError) {
              return Center(child: Text(state.message));
            } else if (state is SettingsLoaded) {
              return _buildSettingsContent(context, state.settings);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    AppSettingsModel settings,
  ) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Modern Custom Header
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App info card with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // App logo
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 35,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // App info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.translate('settings.app_name') ?? 'وذكّر',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n?.translate('settings.description') ??
                                  'خصص تجربتك مع التطبيق',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Settings Sections
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SettingsSection(
                title: l10n?.translate('settings.theme') ?? 'السمة',
                icon: Icons.palette_outlined,
                subtitle: l10n?.translate('settings.theme_subtitle') ??
                    'تخصيص مظهر التطبيق',
                children: [
                  _buildThemeSelector(context, settings, cubit),
                  const Divider(),
                  _buildFontSizeSelector(context, settings, cubit),
                  const Divider(),
                  _buildBasmalaToggle(context, settings, cubit),
                ],
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: l10n?.translate('settings.language') ?? 'اللغة',
                icon: Icons.language_outlined,
                subtitle: l10n?.translate('settings.language_subtitle') ??
                    'تغيير لغة التطبيق',
                children: [_buildLanguageSelector(context, settings, cubit)],
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: l10n?.translate('settings.notifications') ?? 'التنبيهات',
                icon: Icons.notifications_outlined,
                subtitle: l10n?.translate('settings.notifications_subtitle') ??
                    'تنبيهات أوقات الصلاة',
                children: [
                  _buildNotificationMasterToggle(context, settings, cubit),
                  if (settings.notificationSettings.masterEnabled) ...[
                    const Divider(),
                    _buildPersistentNotificationToggle(
                        context, settings, cubit),
                    const Divider(),
                    _buildNotificationTimingSelector(context, settings, cubit),
                    const Divider(),
                    _buildPrayerNotificationsSettings(context, settings, cubit),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: l10n?.translate('settings.about_app') ?? 'حول التطبيق',
                icon: Icons.info_outline,
                subtitle: l10n?.translate('settings.about_subtitle') ??
                    'معلومات عن التطبيق',
                children: [
                  _buildAboutTile(context),
                  _buildFeedbackTile(context),
                  _buildWebsiteTile(context),
                  _buildPrivacyTile(context),
                  _buildRateAppTile(context),
                ],
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        l10n?.translate('settings.theme') ?? 'السمة',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          settings.themeMode == ThemeMode.system
              ? l10n?.translate('settings.system_theme') ?? 'حسب النظام'
              : settings.themeMode == ThemeMode.light
                  ? l10n?.translate('settings.light_theme') ?? 'فاتح'
                  : l10n?.translate('settings.dark_theme') ?? 'داكن',
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
          settings.themeMode == ThemeMode.light
              ? Icons.light_mode
              : settings.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.brightness_auto,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => _showThemeDialog(context, settings, cubit),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n?.translate('settings.select_theme') ?? 'اختر السمة',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const Divider(),
              const SizedBox(height: 8),
              _themeOptionTile(
                context,
                title: l10n?.translate('settings.light_theme') ?? 'فاتح',
                icon: Icons.light_mode,
                themeMode: ThemeMode.light,
                currentMode: settings.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    cubit.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 8),
              _themeOptionTile(
                context,
                title: l10n?.translate('settings.dark_theme') ?? 'داكن',
                icon: Icons.dark_mode,
                themeMode: ThemeMode.dark,
                currentMode: settings.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    cubit.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 8),
              _themeOptionTile(
                context,
                title: l10n?.translate('settings.system_theme') ?? 'حسب النظام',
                icon: Icons.brightness_auto,
                themeMode: ThemeMode.system,
                currentMode: settings.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    cubit.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n?.translate('settings.cancel') ?? 'إلغاء',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeOptionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ThemeMode themeMode,
    required ThemeMode currentMode,
    required Function(ThemeMode?) onChanged,
  }) {
    final theme = Theme.of(context);
    final isSelected = themeMode == currentMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(themeMode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.3),
              width: 1.5,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: theme.colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      title: Text(l10n?.translate('settings.language') ?? 'اللغة'),
      subtitle: Text(settings.languageCode == 'ar' ? 'العربية' : 'English'),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.translate, color: theme.colorScheme.primary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showLanguageDialog(context, settings, cubit),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n?.translate('settings.select_language') ?? 'اختر اللغة',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageOptionTile(
                context,
                title: l10n?.translate('settings.english') ?? 'English',
                flagCode: '🇺🇸',
                languageCode: 'en',
                currentLanguage: settings.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    cubit.setLanguage(value);
                    Navigator.pop(context);
                  }
                },
              ),
              _languageOptionTile(
                context,
                title: l10n?.translate('settings.arabic') ?? 'العربية',
                flagCode: '🇸🇦',
                languageCode: 'ar',
                currentLanguage: settings.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    cubit.setLanguage(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.translate('settings.cancel') ?? 'إلغاء'),
          ),
        ],
      ),
    );
  }

  Widget _languageOptionTile(
    BuildContext context, {
    required String title,
    required String flagCode,
    required String languageCode,
    required String currentLanguage,
    required Function(String?) onChanged,
  }) {
    final theme = Theme.of(context);
    final isSelected = languageCode == currentLanguage;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(languageCode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: 2,
                  ),
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 12,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(flagCode, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontSizeSelector(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      title: Text(l10n?.translate('settings.font_size') ?? 'حجم الخط'),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.format_size, color: theme.colorScheme.primary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (settings.fontSize > 0.8) {
                cubit.setFontSize(settings.fontSize - 0.1);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.remove,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Text(
              _getFontSizeLabel(context, settings.fontSize),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (settings.fontSize < 1.2) {
                cubit.setFontSize(settings.fontSize + 0.1);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.add,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            l10n?.translate('settings.sample_text') ??
                'نموذج للنص بالحجم المختار',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 14) *
                  settings.fontSize,
            ),
          ),
        ],
      ),
    );
  }

  String _getFontSizeLabel(BuildContext context, double fontSize) {
    final l10n = context.l10n;
    if (fontSize <= 0.9) {
      return l10n?.translate('settings.small') ?? 'صغير';
    } else if (fontSize >= 1.1) {
      return l10n?.translate('settings.large') ?? 'كبير';
    } else {
      return l10n?.translate('settings.medium') ?? 'متوسط';
    }
  }

  Widget _buildBasmalaToggle(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SwitchListTile(
      title: Text(l10n?.translate('settings.show_basmala') ?? 'إظهار البسملة'),
      subtitle: Text(
        l10n?.translate('settings.show_basmala_description') ??
            'إظهار البسملة في بداية السور',
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.menu_book, color: theme.colorScheme.primary),
      ),
      value: settings.showBasmala,
      onChanged: (value) => cubit.setShowBasmala(value),
      activeThumbColor: theme.colorScheme.primary,
      activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      title: Text(l10n?.translate('settings.about_app') ?? 'حول التطبيق'),
      subtitle: Text(
        l10n?.translate('settings.app_description') ??
            'تطبيق وذكّر لمساعدتك في شعائر الإسلام',
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.info_outline, color: theme.colorScheme.primary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showAboutDialog(context),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(l10n?.translate('settings.about_app') ?? 'حول التطبيق'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                l10n?.translate('settings.app_name') ?? 'وذكّر',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                l10n?.translate('settings.version') ?? 'الإصدار 1.1.0',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.translate('settings.app_description') ??
                  'تطبيق وذكّر لمساعدتك في شعائر الإسلام',
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.translate('settings.copyright') ??
                  '© 2025 جميع الحقوق محفوظة',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.translate('settings.close') ?? 'إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      title: Text(l10n?.translate('settings.feedback') ?? 'إرسال تعليق'),
      subtitle: Text(
        l10n?.translate('settings.feedback_description') ??
            'شاركنا رأيك لتحسين التطبيق',
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.feedback_outlined, color: theme.colorScheme.primary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _openFeedbackForm(context),
    );
  }

  void _openFeedbackForm(BuildContext context) async {
    final l10n = context.l10n;
    final url = Uri.parse('https://forms.gle/DVtTnGBukUqKhNxi9');

    try {
      // Open directly in external browser
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      // If external browser fails, try platform default
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e) {
        // Show error if nothing works
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.translate('settings.feedback_error') ??
                    'لا يمكن فتح نموذج التعليقات: ${url.toString()}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildWebsiteTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      title: Text(l10n?.translate('settings.website') ?? 'موقع التطبيق'),
      subtitle: Text(
        l10n?.translate('settings.website_description') ??
            'زيارة موقع التطبيق الرسمي',
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.language, color: theme.colorScheme.primary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _openWebsite(context),
    );
  }

  Widget _buildPrivacyTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      title: Text(l10n?.translate('settings.privacy') ?? 'سياسة الخصوصية'),
      subtitle: Text(
        l10n?.translate('settings.privacy_description') ??
            'اطلع على سياسة الخصوصية',
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.privacy_tip_outlined,
          color: theme.colorScheme.primary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _openPrivacyPolicy(context),
    );
  }

  void _openWebsite(BuildContext context) async {
    final l10n = context.l10n;
    final url = Uri.parse('https://wadhakir.vercel.app/');

    try {
      // Open directly in external browser
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      // If external browser fails, try platform default
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e) {
        // Show error if nothing works
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.translate('settings.website_error') ??
                    'لا يمكن فتح موقع التطبيق: ${url.toString()}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _openPrivacyPolicy(BuildContext context) async {
    final l10n = context.l10n;
    final url = Uri.parse('https://wadhakir.vercel.app/privacy');

    try {
      // Open directly in external browser
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      // If external browser fails, try platform default
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e) {
        // Show error if nothing works
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.translate('settings.privacy_error') ??
                    'لا يمكن فتح سياسة الخصوصية: ${url.toString()}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildRateAppTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      title: Text(l10n?.translate('settings.rate_app') ?? 'قيّم التطبيق'),
      subtitle: Text(
        l10n?.translate('settings.rate_app_description') ??
            'قيّم التطبيق في متجر التطبيقات',
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.star_rate, color: theme.colorScheme.primary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _openPlayStore(context),
    );
  }

  void _openPlayStore(BuildContext context) async {
    final l10n = context.l10n;
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.bloom.wadhakir',
    );

    try {
      // Open directly in external browser
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      // If external browser fails, try platform default
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e) {
        // Show error if nothing works
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.translate('settings.rate_app_error') ??
                    'لا يمكن فتح متجر التطبيقات: ${url.toString()}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  // Notification Settings Methods
  Widget _buildNotificationMasterToggle(
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

  Widget _buildPersistentNotificationToggle(
    BuildContext context,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isEnabled =
        settings.notificationSettings.persistentNotificationEnabled;

    return Column(
      children: [
        SwitchListTile(
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
        ),
        // Test button to show persistent notification
        if (isEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () => _testPersistentNotification(context),
              icon: const Icon(Icons.bug_report),
              label: Text(
                l10n?.translate('settings.test_notification') ??
                    'اختبار الإشعار',
                style: theme.textTheme.labelLarge,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationTimingSelector(
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

  Widget _buildPrayerNotificationsSettings(
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
          'الفجر',
          'Fajr',
          settings.notificationSettings.fajrSettings,
          cubit,
          Icons.brightness_5_outlined,
        ),
        const Divider(height: 1),
        _buildPrayerNotificationTile(
          context,
          'الظهر',
          'Dhuhr',
          settings.notificationSettings.dhuhrSettings,
          cubit,
          Icons.wb_sunny_outlined,
        ),
        const Divider(height: 1),
        _buildPrayerNotificationTile(
          context,
          'العصر',
          'Asr',
          settings.notificationSettings.asrSettings,
          cubit,
          Icons.wb_twilight_outlined,
        ),
        const Divider(height: 1),
        _buildPrayerNotificationTile(
          context,
          'المغرب',
          'Maghrib',
          settings.notificationSettings.maghribSettings,
          cubit,
          Icons.nights_stay_outlined,
        ),
        const Divider(height: 1),
        _buildPrayerNotificationTile(
          context,
          'العشاء',
          'Isha',
          settings.notificationSettings.ishaSettings,
          cubit,
          Icons.bedtime_outlined,
        ),
      ],
    );
  }

  Widget _buildPrayerNotificationTile(
    BuildContext context,
    String prayerNameArabic,
    String prayerNameEnglish,
    PrayerNotificationSettings prayerSettings,
    SettingsCubit cubit,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            prayerNameArabic,
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

  void _showNotificationTimingDialog(
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

  Widget _buildTimingOption(
    BuildContext context,
    String title,
    NotificationTiming timing,
    AppSettingsModel settings,
    SettingsCubit cubit,
  ) {
    // Get the current timing from Fajr settings (as default for all)
    final currentTiming = settings.notificationSettings.fajrSettings.timing;
    final theme = Theme.of(context);

    return RadioListTile<NotificationTiming>(
      title: Text(title),
      value: timing,
      groupValue: currentTiming,
      activeColor: theme.colorScheme.primary,
      onChanged: (value) {
        if (value != null) {
          // Update all prayer timings
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

  // Test persistent notification with next prayer info
  Future<void> _testPersistentNotification(BuildContext context) async {
    final l10n = context.l10n;

    try {
      final notificationService = PrayerNotificationService();

      // Get next prayer time (example: Dhuhr in 2 hours)
      final now = DateTime.now();
      final nextPrayerTime = now.add(const Duration(hours: 2, minutes: 15));

      await notificationService.showPersistentNotification(
        nextPrayerName: 'Dhuhr',
        nextPrayerNameArabic: 'الظهر',
        nextPrayerTime: nextPrayerTime,
        locationName: 'مكة المكرمة',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.translate('settings.persistent_notification_success') ??
                  '✅ تم عرض الإشعار الدائم بنجاح',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n?.translate('settings.notification_error') ?? '❌ خطأ'}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
