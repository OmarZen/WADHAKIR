import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/features/share/models/occasion.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';
import 'package:wadhakir/features/share/views/widgets/occasion_card.dart';

/// Roadmap #23 — occasion cards.
///
/// Two things are being asserted, and the second matters more than the first.
/// The date rules are ordinary logic. The content rule — that every dua carries
/// a real attribution — is what separates this feature from the anonymous JPEG
/// it exists to replace.
HijriDateTime hijri(int month, int day) => HijriDateTime(1447, month, day);

Occasion? on(DateTime gregorian, HijriDateTime h) =>
    OccasionCalendar.forDate(gregorian: gregorian, hijri: h);

void main() {
  group('the date rules', () {
    test('an ordinary weekday is not an occasion', () {
      // No card, no empty state, no placeholder — the home screen is calm on
      // an ordinary day.
      expect(on(DateTime(2026, 9, 14), hijri(3, 12)), isNull);
    });

    test('Friday is Friday', () {
      final friday = DateTime(2026, 9, 18);
      expect(friday.weekday, DateTime.friday);
      expect(on(friday, hijri(3, 16)), Occasion.friday);
    });

    test('every annual occasion lands on its own Hijri date', () {
      final ordinaryTuesday = DateTime(2026, 9, 15);
      expect(ordinaryTuesday.weekday, isNot(DateTime.friday));

      expect(on(ordinaryTuesday, hijri(1, 10)), Occasion.ashura);
      expect(on(ordinaryTuesday, hijri(9, 1)), Occasion.ramadan);
      expect(on(ordinaryTuesday, hijri(9, 27)), Occasion.laylatAlQadr);
      expect(on(ordinaryTuesday, hijri(10, 1)), Occasion.eidAlFitr);
      expect(on(ordinaryTuesday, hijri(12, 9)), Occasion.arafah);
      expect(on(ordinaryTuesday, hijri(12, 10)), Occasion.eidAlAdha);
    });

    test('an annual occasion outranks Friday', () {
      // Eid falling on a Friday is Eid. A «جمعة مباركة» card that day is the
      // app failing to notice the more significant of two things.
      final friday = DateTime(2026, 9, 18);
      expect(on(friday, hijri(10, 1)), Occasion.eidAlFitr);
      expect(on(friday, hijri(12, 9)), Occasion.arafah);
    });

    test('the day before and after an occasion is ordinary', () {
      final tuesday = DateTime(2026, 9, 15);
      expect(on(tuesday, hijri(1, 9)), isNull);
      expect(on(tuesday, hijri(1, 11)), isNull);
      expect(on(tuesday, hijri(12, 11)), isNull);
      expect(on(tuesday, hijri(9, 26)), isNull);
      expect(on(tuesday, hijri(9, 28)), isNull);
    });

    test('only Friday is weekly', () {
      expect(Occasion.friday.isWeekly, isTrue);
      for (final other in Occasion.values.where((o) => o != Occasion.friday)) {
        expect(
          other.isWeekly,
          isFalse,
          reason:
              '${other.id} is annual; this feature earns its keep on the '
              'fifty-two Fridays, and the rest is a bonus',
        );
      }
    });
  });

  group('the content rule', () {
    test('every occasion has a non-empty dua AND attribution', () {
      // The attribution is the feature. An unsourced dua forwarded at scale is
      // how fabrications enter circulation, and doing that with better
      // typography makes the problem worse rather than better.
      for (final occasion in Occasion.values) {
        expect(occasion.greeting.trim(), isNotEmpty, reason: occasion.id);
        expect(occasion.dua.trim(), isNotEmpty, reason: occasion.id);
        expect(
          occasion.attribution.trim(),
          isNotEmpty,
          reason: '${occasion.id} has no source — it must not ship',
        );
      }
    });

    test('every attribution names a narrator or a collection', () {
      // Not just "non-empty": a placeholder like "—" would pass the test above
      // and fail the reader.
      const collections = [
        'رواه',
        'مسلم',
        'البخاري',
        'الترمذي',
        'أبو داود',
        'ابن ماجه',
        'النسائي',
        'أثر',
      ];
      for (final occasion in Occasion.values) {
        expect(
          collections.any(occasion.attribution.contains),
          isTrue,
          reason: '${occasion.id}: "${occasion.attribution}" names no source',
        );
      }
    });

    test('ids are stable and unique', () {
      final ids = Occasion.values.map((o) => o.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids, contains('friday'));
    });
  });

  group('the share payload', () {
    test('carries the attribution onto the card', () {
      final payload = OccasionCard.payloadFor(Occasion.friday);
      expect(payload.reference, Occasion.friday.attribution);
      expect(payload.headline, Occasion.friday.dua);
      expect(payload.categoryLabel, 'جمعة مباركة');
    });

    test('the caption carries greeting, dua and source', () {
      final caption = OccasionCard.payloadFor(Occasion.arafah).captionOverride!;
      expect(caption, contains('يوم عرفة'));
      expect(caption, contains('لَا إِلَهَ إِلَّا اللَّهُ'));
      expect(caption, contains('رواه الترمذي'));
    });

    test('every caption carries a way back to the app', () {
      // Setting captionOverride opts out of the default caption, which is what
      // normally appends these. Friday is the one surface in this app built to
      // be forwarded weekly, and it was travelling with no link home.
      for (final occasion in Occasion.values) {
        final caption = OccasionCard.payloadFor(occasion).captionOverride!;
        expect(
          caption,
          contains(AppConstants.playStoreUrl),
          reason: '${occasion.id} forwards with no way back',
        );
        expect(caption, contains(AppConstants.appName));
      }
    });

    test('uses the passage layout and the story ratio', () {
      final payload = OccasionCard.payloadFor(Occasion.eidAlFitr);
      expect(payload.variant, ShareCardVariant.passage);
      expect(payload.ratio, ShareCardRatio.story);
    });
  });

  group('the labels exist in both languages', () {
    test('every occasion id has a greeting in ar and en', () {
      for (final code in ['ar', 'en']) {
        final json =
            jsonDecode(File('assets/lang/$code.json').readAsStringSync())
                as Map<String, dynamic>;
        final block = json['occasion'] as Map<String, dynamic>;
        for (final occasion in Occasion.values) {
          expect(
            block.keys,
            contains(occasion.id),
            reason: '$code.json has no occasion.${occasion.id}',
          );
        }
        expect(block.keys, contains('share_prompt'));
      }
    });
  });
}
