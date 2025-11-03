import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/features/settings/view/widgets/settings_section.dart';
import 'package:wadhakir/features/settings/view/widgets/theme_selector_widget.dart';
import 'package:wadhakir/features/settings/view/widgets/basmala_toggle_widget.dart';
import 'package:wadhakir/features/settings/view/widgets/about_section_widgets.dart';
import 'package:wadhakir/features/settings/view/widgets/language_selector_widget.dart';
import 'package:wadhakir/features/settings/view/widgets/font_size_selector_widget.dart';
import 'package:wadhakir/features/settings/view/widgets/adhan_sounds_section_widget.dart';
import 'package:wadhakir/features/settings/view/widgets/notification_settings_widgets.dart';

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
                  ThemeSelectorWidget(settings: settings, cubit: cubit),
                  const Divider(),
                  FontSizeSelectorWidget(settings: settings, cubit: cubit),
                  const Divider(),
                  BasmalaToggleWidget(settings: settings, cubit: cubit),
                ],
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: l10n?.translate('settings.language') ?? 'اللغة',
                icon: Icons.language_outlined,
                subtitle: l10n?.translate('settings.language_subtitle') ??
                    'تغيير لغة التطبيق',
                children: [LanguageSelectorWidget(settings: settings, cubit: cubit)],
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: l10n?.translate('settings.notifications') ?? 'التنبيهات',
                icon: Icons.notifications_outlined,
                subtitle: l10n?.translate('settings.notifications_subtitle') ??
                    'تنبيهات أوقات الصلاة',
                children: [
                  NotificationSettingsWidgets.buildNotificationMasterToggle(context, settings, cubit),
                  if (settings.notificationSettings.masterEnabled) ...[
                    const Divider(),
                    NotificationSettingsWidgets.buildPersistentNotificationToggle(context, settings, cubit),
                    const Divider(),
                    NotificationSettingsWidgets.buildNotificationTimingSelector(context, settings, cubit),
                    const Divider(),
                    const AdhanSoundsSectionWidget(),
                    const Divider(),
                    NotificationSettingsWidgets.buildPrayerNotificationsSettings(context, settings, cubit),
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
                  AboutSectionWidgets.buildAboutTile(context),
                  AboutSectionWidgets.buildFeedbackTile(context),
                  AboutSectionWidgets.buildWebsiteTile(context),
                  AboutSectionWidgets.buildPrivacyTile(context),
                  AboutSectionWidgets.buildRateAppTile(context),
                ],
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}
