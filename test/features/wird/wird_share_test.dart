import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/data/models/wird/wird_enums.dart';
import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';
import 'package:wadhakir/features/wird/services/wird_share.dart';

/// Roadmap #21 — the khatma's card.
///
/// The interesting constraint here is not what goes on the card but what must
/// never reach it. `PRODUCT.md` rules out scorekeeping, which is why the tasbih
/// has no share button at all; the khatma earns one because it carries a
/// *dedication*, and that — not the tally — is the payload.

const _labels = (khatma: 'تمت الختمة', dedicatedTo: 'إهداءً إلى');

WirdPlanModel _plan({
  WirdIntention intention = WirdIntention.forDeceased,
  String? dedication = 'روح والدي',
  int completedDays = 30,
}) => WirdPlanModel(
  isActive: true,
  goalMode: WirdGoalMode.fixedDailyAmount,
  unit: WirdUnit.pages,
  amountPerDay: 20,
  startPage: 1,
  reminderTime: '20:00',
  reminderEnabled: true,
  completedDayIndices: {for (var i = 0; i < completedDays; i++) i},
  planStartDate: DateTime(2026, 8, 15),
  intention: intention,
  dedication: dedication,
);

SharePayload _payload(WirdPlanModel plan) => WirdShare.build(
  plan: plan,
  khatmaLabel: _labels.khatma,
  dedicatedToLabel: _labels.dedicatedTo,
);

void main() {
  group('what never reaches the card', () {
    test('no day count, no total, no percentage', () {
      // The whole reason the tasbih gets no share button: a card of someone's
      // progress is a scoreboard. A finished khatma is the news; how fast it
      // went is nobody else's business.
      final payload = _payload(_plan(completedDays: 30));
      final everything = [
        payload.headline,
        payload.categoryLabel ?? '',
        payload.reference ?? '',
        payload.captionOverride ?? '',
      ].join('\n');

      for (final leak in ['30', '٣٠', '20', '٢٠', '%', '100']) {
        expect(
          everything,
          isNot(contains(leak)),
          reason: 'the tally must not reach a card people broadcast',
        );
      }
    });

    test('a half-finished plan produces the same card as a finished one', () {
      // Nothing on the card may vary with progress, or the card is reporting
      // progress whether or not it prints a number.
      final half = _payload(_plan(completedDays: 15));
      final whole = _payload(_plan(completedDays: 30));

      expect(half.headline, whole.headline);
      expect(half.captionOverride, whole.captionOverride);
    });
  });

  group('the dedication', () {
    test('leads the card when there is one', () {
      final payload = _payload(_plan());
      expect(payload.headline, startsWith('إهداءً إلى روح والدي'));
      expect(payload.headline, contains(WirdShare.verse));
    });

    test('is absent when the intention is none, even with leftover text', () {
      // The setup screen writes both fields together, but a plan restored from
      // an older backup can carry text with WirdIntention.none. The intention
      // is the authority.
      final payload = _payload(
        _plan(intention: WirdIntention.none, dedication: 'روح والدي'),
      );

      expect(payload.headline, WirdShare.verse);
      expect(payload.headline, isNot(contains('والدي')));
    });

    test('whitespace-only counts as no dedication', () {
      // Otherwise the card reads «إهداءً إلى» followed by nothing.
      final payload = _payload(_plan(dedication: '   '));
      expect(payload.headline, WirdShare.verse);
      expect(payload.headline, isNot(contains('إهداءً إلى')));
    });

    test('null counts as no dedication', () {
      expect(_payload(_plan(dedication: null)).headline, WirdShare.verse);
    });

    test('every intention that carries text puts it on the card', () {
      for (final intention in WirdIntention.values) {
        if (intention == WirdIntention.none) continue;
        final payload = _payload(_plan(intention: intention));
        expect(
          payload.headline,
          contains('روح والدي'),
          reason: '$intention dropped its dedication',
        );
      }
    });
  });

  group('the verse', () {
    test('is always on the card, dedication or not', () {
      expect(_payload(_plan()).headline, contains(WirdShare.verse));
      expect(
        _payload(_plan(dedication: null)).headline,
        contains(WirdShare.verse),
      );
    });

    test('never travels without its citation', () {
      // `Occasion` states the rule this follows: nothing ships on a card
      // without a named source, because unsourced text forwarded at scale is
      // how mangled text enters circulation.
      final payload = _payload(_plan());
      expect(payload.reference, WirdShare.verseSource);
      expect(payload.captionOverride, contains(WirdShare.verseSource));
    });

    test('the citation names a surah and an ayah', () {
      expect(WirdShare.verseSource, contains('الأعراف'));
      expect(WirdShare.verseSource.trim(), isNotEmpty);
    });
  });

  group('the payload', () {
    test('is a passage card at the story ratio', () {
      final payload = _payload(_plan());
      expect(payload.variant, ShareCardVariant.passage);
      expect(payload.ratio, ShareCardRatio.story);
    });

    test('the caption carries the verse, the source and the store link', () {
      final caption = _payload(_plan()).captionOverride!;
      expect(caption, contains(WirdShare.verse));
      expect(caption, contains(WirdShare.verseSource));
      expect(caption, contains('روح والدي'));
      expect(caption, contains(AppConstants.appName));
      expect(caption, contains(AppConstants.playStoreUrl));
    });
  });

  group('dedicationOf', () {
    test('reads the plan the way the card does', () {
      expect(WirdShare.dedicationOf(_plan()), 'روح والدي');
      expect(
        WirdShare.dedicationOf(_plan(dedication: '  روح والدي  ')),
        'روح والدي',
      );
      expect(WirdShare.dedicationOf(_plan(dedication: '')), isNull);
      expect(
        WirdShare.dedicationOf(_plan(intention: WirdIntention.none)),
        isNull,
      );
    });
  });
}
