import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/reading/reading_comfort.dart';

/// Roadmap #24 — line spacing and font choice.
///
/// The rule that matters most is the one about doing nothing: this ships to
/// installs that never open the setting, and it must leave every reading
/// surface rendering exactly as it did.
void main() {
  group('the defaults change nothing', () {
    test('the default spacing is the height every surface hardcoded', () {
      // Each reading surface shipped `height: 2.0`. If this default ever
      // disagrees with that, every existing user is restyled on upgrade to fix
      // a problem none of them reported.
      expect(ReadingComfort.defaults.spacing.height, 2.0);
    });

    test('the default font leaves each surface alone', () {
      // Surfaces do not agree today — azkar detail is Almarai, the after-salam
      // adhkar and the mushaf are ScheherazadeNew — and those were per-surface
      // decisions for reasons that still hold.
      expect(ReadingComfort.defaults.font, ReadingFont.system);
      expect(ReadingFont.system.family, isNull);
    });

    test('applying the defaults preserves the family it was given', () {
      const base = TextStyle(fontFamily: 'ScheherazadeNew', fontSize: 19);
      final styled = ReadingComfort.defaults.apply(base);

      expect(styled.fontFamily, 'ScheherazadeNew');
      expect(styled.fontSize, 19);
      expect(styled.height, 2.0);
    });

    test('applying the defaults over a null family leaves it null', () {
      // So the surface's own theme still decides, rather than being pinned to
      // whatever this class would have guessed.
      final styled = ReadingComfort.defaults.apply(const TextStyle());
      expect(styled.fontFamily, isNull);
    });

    test('isDefault only holds for the untouched pair', () {
      expect(ReadingComfort.defaults.isDefault, isTrue);
      expect(
        ReadingComfort.defaults
            .copyWith(spacing: ReadingSpacing.airy)
            .isDefault,
        isFalse,
      );
      expect(
        ReadingComfort.defaults.copyWith(font: ReadingFont.almarai).isDefault,
        isFalse,
      );
    });
  });

  group('applying a choice', () {
    test('a chosen font overrides the surface family', () {
      const base = TextStyle(fontFamily: 'Almarai');
      final styled = const ReadingComfort(
        font: ReadingFont.arefRuqaa,
      ).apply(base);

      expect(styled.fontFamily, 'ArefRuqaa');
    });

    test('spacing maps to the documented heights', () {
      expect(ReadingSpacing.compact.height, 1.7);
      expect(ReadingSpacing.comfortable.height, 2.0);
      expect(ReadingSpacing.airy.height, 2.4);
    });

    test('nothing but height and family is touched', () {
      const base = TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Color(0xFF112233),
      );
      final styled = const ReadingComfort(
        spacing: ReadingSpacing.airy,
        font: ReadingFont.almarai,
      ).apply(base);

      expect(styled.fontSize, 22, reason: 'size is textScale, not this');
      expect(styled.fontWeight, FontWeight.w700);
      expect(styled.letterSpacing, 0.5);
      expect(styled.color, const Color(0xFF112233));
    });

    test('a null base still produces a usable style', () {
      final styled = const ReadingComfort(
        spacing: ReadingSpacing.compact,
      ).apply(null);
      expect(styled.height, 1.7);
    });
  });

  group('reading a stored value back', () {
    test('an unknown id falls back to the default, never to null', () {
      // A backup file written by a build that added a fourth face, or one
      // hand-edited. Degrading to the app's own look beats rendering nothing.
      expect(ReadingSpacing.fromId('nonsense'), ReadingSpacing.comfortable);
      expect(ReadingFont.fromId('nonsense'), ReadingFont.system);
      expect(ReadingSpacing.fromId(null), ReadingSpacing.comfortable);
      expect(ReadingFont.fromId(null), ReadingFont.system);
    });

    test('every id round-trips', () {
      for (final spacing in ReadingSpacing.values) {
        expect(ReadingSpacing.fromId(spacing.id), spacing);
      }
      for (final font in ReadingFont.values) {
        expect(ReadingFont.fromId(font.id), font);
      }
    });

    test('ids are stable strings, not enum indices', () {
      // They go into SharedPreferences and into backup files. An index would
      // silently remap everybody's choice the day a value is inserted.
      expect(ReadingSpacing.values.map((s) => s.id), [
        'compact',
        'comfortable',
        'airy',
      ]);
      expect(ReadingFont.values.map((f) => f.id), [
        'system',
        'almarai',
        'scheherazade',
        'aref_ruqaa',
      ]);
    });
  });

  group('the fonts it offers actually exist', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    test('every offered family is declared in pubspec', () {
      // A family name with a typo renders the default face silently — the user
      // picks "Aref Ruqaa", nothing changes, and no error is raised anywhere.
      for (final font in ReadingFont.values) {
        final family = font.family;
        if (family == null) continue;
        expect(
          pubspec,
          contains('family: $family'),
          reason: '$family is offered but not bundled',
        );
      }
    });

    test('Jomhuria is bundled but deliberately not offered', () {
      // It is a display face and unreadable at body size. This asserts the
      // omission is a decision rather than an oversight.
      expect(pubspec, contains('family: Jomhuria'));
      expect(
        ReadingFont.values.map((f) => f.family),
        isNot(contains('Jomhuria')),
      );
    });
  });

  group('the labels exist in both languages', () {
    Map<String, dynamic> lang(String code) =>
        jsonDecode(File('assets/lang/$code.json').readAsStringSync())
            as Map<String, dynamic>;

    test('every spacing and font id has a label in ar and en', () {
      for (final code in ['ar', 'en']) {
        final settings = lang(code)['settings'] as Map<String, dynamic>;
        final spacing = settings['spacing'] as Map<String, dynamic>;
        final fonts = settings['font'] as Map<String, dynamic>;

        for (final value in ReadingSpacing.values) {
          expect(
            spacing.keys,
            contains(value.id),
            reason: '$code.json has no settings.spacing.${value.id}',
          );
        }
        for (final value in ReadingFont.values) {
          expect(
            fonts.keys,
            contains(value.id),
            reason: '$code.json has no settings.font.${value.id}',
          );
        }
      }
    });
  });

  group('the scope', () {
    testWidgets('a surface outside any scope gets the defaults', (
      tester,
    ) async {
      late ReadingComfort seen;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            seen = ReadingComfortScope.of(context);
            return const SizedBox();
          },
        ),
      );
      expect(seen, ReadingComfort.defaults);
    });

    testWidgets('a surface inside a scope gets its comfort', (tester) async {
      late ReadingComfort seen;
      await tester.pumpWidget(
        ReadingComfortScope(
          comfort: const ReadingComfort(
            spacing: ReadingSpacing.airy,
            font: ReadingFont.arefRuqaa,
          ),
          child: Builder(
            builder: (context) {
              seen = ReadingComfortScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen.spacing, ReadingSpacing.airy);
      expect(seen.font, ReadingFont.arefRuqaa);
    });
  });
}
