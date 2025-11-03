import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';

class LanguageSelectorWidget extends StatelessWidget {
  final AppSettingsModel settings;
  final SettingsCubit cubit;

  const LanguageSelectorWidget({
    super.key,
    required this.settings,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
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
      onTap: () => _showLanguageDialog(context),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = context.l10n;

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
              _LanguageOptionTile(
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
              _LanguageOptionTile(
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
}

class _LanguageOptionTile extends StatelessWidget {
  final String title;
  final String flagCode;
  final String languageCode;
  final String currentLanguage;
  final Function(String?) onChanged;

  const _LanguageOptionTile({
    required this.title,
    required this.flagCode,
    required this.languageCode,
    required this.currentLanguage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
}
