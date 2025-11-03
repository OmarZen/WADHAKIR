import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';

class FontSizeSelectorWidget extends StatelessWidget {
  final AppSettingsModel settings;
  final SettingsCubit cubit;

  const FontSizeSelectorWidget({
    super.key,
    required this.settings,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
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
}
