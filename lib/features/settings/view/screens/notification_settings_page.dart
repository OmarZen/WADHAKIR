import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/features/settings/view/widgets/adhan_sounds_section_widget.dart';
import 'package:wadhakir/features/settings/view/widgets/notification_settings_widgets.dart';

/// Dedicated page for prayer notification settings. Hosts the content that
/// used to expand inline under the Notifications section of the settings
/// screen, keeping the main settings page clean.
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  Widget _divider(ThemeData theme) => Divider(
    height: 1,
    thickness: 0.5,
    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.translate('settings.notifications') ?? 'التنبيهات'),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is! SettingsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final settings = state.settings;
          final cubit = context.read<SettingsCubit>();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              NotificationSettingsWidgets.buildNotificationMasterToggle(
                context,
                settings,
                cubit,
              ),
              if (settings.notificationSettings.masterEnabled) ...[
                _divider(theme),
                NotificationSettingsWidgets.buildPersistentNotificationToggle(
                  context,
                  settings,
                  cubit,
                ),
                _divider(theme),
                NotificationSettingsWidgets.buildNotificationTimingSelector(
                  context,
                  settings,
                  cubit,
                ),
                _divider(theme),
                const AdhanSoundsSectionWidget(),
                _divider(theme),
                NotificationSettingsWidgets.buildPrayerNotificationsSettings(
                  context,
                  settings,
                  cubit,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
