import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';

class BasmalaToggleWidget extends StatelessWidget {
  final AppSettingsModel settings;
  final SettingsCubit cubit;

  const BasmalaToggleWidget({
    super.key,
    required this.settings,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
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
}
