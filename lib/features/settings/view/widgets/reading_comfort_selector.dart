import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/reading/reading_comfort.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';

/// Roadmap #24 — line spacing and font choice, next to the text size that
/// shipped in R1.
///
/// Deliberately beside it and not merged into it. Size is one number with an
/// obvious direction; these are two choices with no better or worse, so they
/// get their own row and a live sample rather than a slider.
class ReadingComfortSelector extends StatelessWidget {
  const ReadingComfortSelector({
    super.key,
    required this.settings,
    required this.cubit,
  });

  final AppSettingsModel settings;
  final SettingsCubit cubit;

  static String _tr(AppLocalizations? l10n, String key, String fallback) {
    final value = l10n?.translate(key);
    return value == null || value == key ? fallback : value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final comfort = settings.readingComfort;

    String tr(String key, String fallback) => _tr(l10n, key, fallback);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            tr('settings.reading_comfort', 'راحة القراءة'),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          tr(
            'settings.reading_comfort_subtitle',
            'تباعد الأسطر ونوع الخط في شاشات القراءة',
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),

        // A live sample, not a preview pane. The whole decision is "is this
        // comfortable to read", and no label answers that.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            tr(
              'settings.reading_sample',
              'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: comfort.apply(
              theme.textTheme.bodyLarge?.copyWith(fontSize: 19),
            ),
          ),
        ),
        const SizedBox(height: 16),

        _label(theme, tr('settings.line_spacing', 'تباعد الأسطر')),
        const SizedBox(height: 8),
        _row([
          for (final spacing in ReadingSpacing.values)
            _chip(
              theme,
              label: tr(
                'settings.spacing.${spacing.id}',
                _spacingFallback(spacing),
              ),
              selected: comfort.spacing == spacing,
              onTap: () =>
                  cubit.setReadingComfort(comfort.copyWith(spacing: spacing)),
            ),
        ]),
        const SizedBox(height: 16),

        _label(theme, tr('settings.reading_font', 'نوع الخط')),
        const SizedBox(height: 8),
        _row([
          for (final font in ReadingFont.values)
            _chip(
              theme,
              label: tr('settings.font.${font.id}', _fontFallback(font)),
              selected: comfort.font == font,
              // Each chip renders in the face it offers — the only honest way
              // to choose a font is to see it.
              fontFamily: font.family,
              onTap: () =>
                  cubit.setReadingComfort(comfort.copyWith(font: font)),
            ),
        ]),
      ],
    );
  }

  static String _spacingFallback(ReadingSpacing spacing) => switch (spacing) {
    ReadingSpacing.compact => 'متقارب',
    ReadingSpacing.comfortable => 'مريح',
    ReadingSpacing.airy => 'متباعد',
  };

  static String _fontFallback(ReadingFont font) => switch (font) {
    ReadingFont.system => 'كما هو',
    ReadingFont.almarai => 'المراعي',
    ReadingFont.scheherazade => 'شهرزاد',
    ReadingFont.arefRuqaa => 'عارف رقعة',
  };

  Widget _label(ThemeData theme, String text) => Text(
    text,
    style: theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    ),
  );

  /// Wraps rather than scrolls: three chips fit at every text scale this app
  /// allows, and a row that scrolls hides the option on the end.
  Widget _row(List<Widget> children) =>
      Wrap(spacing: 8, runSpacing: 8, children: children);

  Widget _chip(
    ThemeData theme, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? fontFamily,
  }) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.55)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: fontFamily,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
