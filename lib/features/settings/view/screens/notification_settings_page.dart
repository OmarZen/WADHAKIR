import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/features/settings/view/screens/reminder_health_screen.dart';
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

  /// The way in to [ReminderHealthScreen].
  ///
  /// Phrased as the question the user actually has — «هل تصل تذكيراتك؟» — and
  /// not as "diagnostics". Nobody opens diagnostics; people open the thing that
  /// asks their question back to them.
  Widget _healthRow(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.favorite_outline,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        l10n?.translate('reminder_health.title') ?? 'هل تصل تذكيراتك؟',
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        l10n?.translate('reminder_health.subtitle') ??
            'فحص سريع لحالة التنبيهات على هذا الجهاز',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_left, size: 20),
      onTap: () => ReminderHealthScreen.push(context),
    );
  }

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
              // First, and deliberately outside the master-toggle gate below.
              //
              // Someone opens this page for one of two reasons: to change a
              // setting, or because a prayer went by in silence. The second
              // group should not have to read past six switches to find the
              // screen that answers them — and if they had turned reminders off
              // themselves, that is exactly what the verdict will tell them.
              _healthRow(context, theme),
              _divider(theme),
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
                // Sits under the adhan picker on purpose: it is about how that
                // adhan is heard, not about when the notification arrives.
                // Android-only, and the divider is gated with it — the toggle
                // returns an empty box elsewhere, which would otherwise leave
                // two rules stacked on top of each other.
                if (Platform.isAndroid) ...[
                  _divider(theme),
                  NotificationSettingsWidgets.buildSilentOverrideToggle(
                    context,
                    settings,
                    cubit,
                  ),
                ],
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
