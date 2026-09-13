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
///
/// ## The sample is the control
///
/// Neither choice here has a right answer, and no label can supply one —
/// «متباعد» does not tell anybody whether their eyes will track the lines more
/// easily. So the sample is bound to be more than decoration: it is wrapped to
/// a fixed measure so it always breaks over several lines (a leading you cannot
/// see between two lines is not a preview of anything), and every chip carries
/// a picture of what it does — the spacing chips a stack of rules at their own
/// leading, the font chips their own face.
class ReadingComfortSelector extends StatelessWidget {
  const ReadingComfortSelector({
    super.key,
    required this.settings,
    required this.cubit,
  });

  final AppSettingsModel settings;
  final SettingsCubit cubit;

  /// The sample's measure.
  ///
  /// A cap, not a width: on a phone the card is already narrower than this and
  /// nothing changes. It earns its place on a tablet, where a full-width line
  /// of 19pt Arabic would run past a comfortable measure AND — the reason it is
  /// here — fit the whole sample on one line, leaving the line-spacing control
  /// with nothing to demonstrate.
  static const double _sampleMeasure = 320;

  static String _tr(AppLocalizations? l10n, String key, String fallback) {
    final value = l10n?.translate(key);
    return value == null || value == key ? fallback : value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    final comfort = settings.readingComfort;

    String tr(String key, String fallback) => _tr(l10n, key, fallback);

    return Container(
      // The chrome its neighbours wear. Before this it was a bare column under
      // the text-size card, which read as loose content that had fallen out of
      // the section rather than as the third control in it.
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            title: tr('settings.reading_comfort', 'راحة القراءة'),
            subtitle: tr(
              'settings.reading_comfort_subtitle',
              'تباعد الأسطر ونوع الخط في شاشات القراءة',
            ),
            summary: _summary(comfort, tr),
          ),
          const SizedBox(height: 14),

          _Sample(
            text: tr(
              'settings.reading_sample',
              'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً '
                  'وَقِنَا عَذَابَ النَّارِ',
            ),
            style: comfort.apply(
              theme.textTheme.bodyLarge?.copyWith(fontSize: 19),
            ),
            measure: _sampleMeasure,
          ),
          const SizedBox(height: 18),

          _label(theme, tr('settings.line_spacing', 'تباعد الأسطر')),
          const SizedBox(height: 10),
          _row([
            for (final spacing in ReadingSpacing.values)
              _Chip(
                label: tr(
                  'settings.spacing.${spacing.id}',
                  _spacingFallback(spacing),
                ),
                selected: comfort.spacing == spacing,
                // A stack of rules at this option's own leading. The word alone
                // asks the reader to imagine the difference; this shows it.
                spacingGlyph: spacing,
                onTap: () =>
                    cubit.setReadingComfort(comfort.copyWith(spacing: spacing)),
              ),
          ]),
          const SizedBox(height: 18),

          _label(theme, tr('settings.reading_font', 'نوع الخط')),
          const SizedBox(height: 10),
          _row([
            for (final font in ReadingFont.values)
              _Chip(
                label: tr('settings.font.${font.id}', _fontFallback(font)),
                selected: comfort.font == font,
                // Each chip renders in the face it offers — the only honest way
                // to choose a font is to see it.
                fontFamily: font.family,
                onTap: () =>
                    cubit.setReadingComfort(comfort.copyWith(font: font)),
              ),
          ]),

          // Shown only once there is something to undo. Two chip rows with no
          // "off" state are easy to wander into and hard to find the way back
          // from — every other chip looks equally chosen.
          if (!comfort.isDefault) ...[
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () =>
                    cubit.setReadingComfort(ReadingComfort.defaults),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(tr('settings.reading_reset', 'إعادة الضبط')),
                style: TextButton.styleFrom(
                  foregroundColor: cs.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The one-line "here is where you left it" for the header.
  ///
  /// [ReadingFont.system] is left out on purpose: it is the default and it
  /// means "unchanged", so naming it in a summary would make an untouched
  /// setting look like a decision.
  static String _summary(
    ReadingComfort comfort,
    String Function(String, String) tr,
  ) {
    final spacing = tr(
      'settings.spacing.${comfort.spacing.id}',
      _spacingFallback(comfort.spacing),
    );
    if (comfort.font == ReadingFont.system) return spacing;
    final font = tr(
      'settings.font.${comfort.font.id}',
      _fontFallback(comfort.font),
    );
    return '$spacing · $font';
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

  /// Wraps rather than scrolls: a row that scrolls hides the option on the end,
  /// and the font row is four chips wide at the largest text scale this app
  /// allows.
  Widget _row(List<Widget> children) =>
      Wrap(spacing: 8, runSpacing: 8, children: children);

  /// Gap between the rules in a spacing chip's glyph, for [spacing].
  ///
  /// Derived from the real leading so the picture cannot drift from the value
  /// it depicts: 1.7 → 1.5px, 2.0 → 3px, 2.4 → 5px. Public so a test can assert
  /// the ordering holds — a glyph that did not widen with the spacing would
  /// still look like a glyph.
  static double spacingGlyphGap(ReadingSpacing spacing) =>
      (spacing.height - 1.4) * 5.0;
}

/// Icon, title, subtitle and the current value — the header shape the text-size
/// card and the theme/language cards already use.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.summary,
  });

  final String title;
  final String subtitle;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.format_line_spacing_rounded,
              size: 20,
              color: cs.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                summary,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The live sample, held to a fixed measure so it always breaks over more than
/// one line — otherwise the line-spacing control has nothing to preview.
class _Sample extends StatelessWidget {
  const _Sample({
    required this.text,
    required this.style,
    required this.measure,
  });

  final String text;
  final TextStyle? style;
  final double measure;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.10)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: measure),
            child: Text(
              text,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}

/// Three rules stacked at the leading the option actually applies — a picture
/// of the value rather than an icon standing in for it.
class _SpacingGlyph extends StatelessWidget {
  const _SpacingGlyph({required this.spacing, required this.color});

  final ReadingSpacing spacing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final gap = ReadingComfortSelector.spacingGlyphGap(spacing);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) SizedBox(height: gap),
          Container(width: 13, height: 1.6, color: color),
        ],
      ],
    );
  }
}

/// One option. Carries whatever shows what it does — a glyph for spacing, its
/// own face for a font — beside the label.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.fontFamily,
    this.spacingGlyph,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? fontFamily;

  /// Draws this spacing beside the label. The glyph is built here rather than
  /// passed in so it can take the chip's own resolved ink and track selection.
  final ReadingSpacing? spacingGlyph;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ink = selected ? cs.primary : cs.onSurface;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.55)
                  : cs.onSurface.withValues(alpha: 0.18),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (spacingGlyph != null) ...[
                _SpacingGlyph(
                  spacing: spacingGlyph!,
                  color: ink.withValues(alpha: selected ? 0.9 : 0.55),
                ),
                const SizedBox(width: 9),
              ],
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: fontFamily,
                  color: ink,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
