import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/constants/adhan_sounds.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/features/settings/view/widgets/adhan_sound_selector.dart';

class AdhanSoundsSectionWidget extends StatelessWidget {
  const AdhanSoundsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Icon(
                Icons.music_note,
                color: isDark
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.translate('settings.adhan_sounds') ?? 'أصوات الأذان',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        // Adhan Sound Selectors in Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (builderContext, state) {
              if (state is! SettingsLoaded) {
                return const SizedBox.shrink();
              }

              // Get cubit from builder context
              final settingsCubit = builderContext.read<SettingsCubit>();

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fajr Adhan Sound Selector
                  Expanded(
                    child: AdhanSoundSelector(
                      title:
                          l10n?.translate('settings.fajr_adhan') ??
                          'أذان الفجر',
                      subtitle:
                          l10n?.translate('settings.fajr_adhan_subtitle') ??
                          'اختر صوت أذان الفجر',
                      currentSoundPath: state
                          .settings
                          .notificationSettings
                          .fajrSettings
                          .customSoundPath,
                      soundOptions: AdhanSounds.fajrSounds,
                      onSoundSelected: (path) {
                        debugPrint('🔔 Fajr sound selected: $path');

                        final newSettings = state
                            .settings
                            .notificationSettings
                            .fajrSettings
                            .copyWith(customSoundPath: path);

                        debugPrint(
                          '🔔 Updating Fajr settings with customSoundPath: $path',
                        );
                        settingsCubit.updatePrayerNotificationSettings(
                          prayerName: 'Fajr',
                          prayerSettings: newSettings,
                        );
                      },
                      enabled: state
                          .settings
                          .notificationSettings
                          .fajrSettings
                          .enabled,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Regular Prayers Adhan Sound Selector
                  Expanded(
                    child: AdhanSoundSelector(
                      title:
                          l10n?.translate('settings.regular_adhan') ??
                          'أذان الصلوات الأخرى',
                      subtitle:
                          l10n?.translate('settings.regular_adhan_subtitle') ??
                          'اختر صوت أذان الظهر، العصر، المغرب والعشاء',
                      currentSoundPath: state
                          .settings
                          .notificationSettings
                          .dhuhrSettings
                          .customSoundPath,
                      soundOptions: AdhanSounds.regularSounds,
                      onSoundSelected: (path) async {
                        debugPrint(
                          '🔔 ════════════════════════════════════════',
                        );
                        debugPrint('🔔 Regular prayers sound selected: $path');
                        debugPrint(
                          '🔔 Current Dhuhr customSoundPath: ${state.settings.notificationSettings.dhuhrSettings.customSoundPath}',
                        );

                        // Update all regular prayers with a single batch update
                        debugPrint(
                          '🔔 Calling updateAllRegularPrayersSounds...',
                        );
                        await settingsCubit.updateAllRegularPrayersSounds(path);

                        debugPrint(
                          '🔔 All regular prayers updated with sound: $path',
                        );
                        debugPrint(
                          '🔔 ════════════════════════════════════════',
                        );
                      },
                      enabled:
                          state
                              .settings
                              .notificationSettings
                              .dhuhrSettings
                              .enabled ||
                          state
                              .settings
                              .notificationSettings
                              .asrSettings
                              .enabled ||
                          state
                              .settings
                              .notificationSettings
                              .maghribSettings
                              .enabled ||
                          state
                              .settings
                              .notificationSettings
                              .ishaSettings
                              .enabled,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
