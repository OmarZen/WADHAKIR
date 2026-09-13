import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/features/home/views/widgets/hero_backdrop.dart';

/// R4's typographic hero.
///
/// The hero's ground used to be one of eleven photographs under a scrim that
/// reached 0.75 black so white type would read. The scrim was that heavy
/// because the ground was unpredictable. Drawing it in code makes every colour
/// a constant — which means the contrast is finally something a test can hold,
/// and R1 spent a whole release learning that this is the part of the hero that
/// regresses quietly.
///
/// WCAG AA is 4.5:1 for normal text; AAA is 7:1. Every foreground on this hero
/// is white.
const double _aa = 4.5;
const double _aaa = 7.0;

/// The lit region under a halo — the brightest point on the whole hero, and so
/// the only one that can fail.
Color _underHalo(Color base, double alpha) =>
    HeroBackdrop.over(HeroBackdrop.glow, base, alpha);

void main() {
  group('the gradient', () {
    test('its lightest end clears AAA against white', () {
      final ratio = HeroBackdrop.contrastWithWhite(HeroBackdrop.skyTop);
      expect(ratio, greaterThan(_aaa), reason: 'skyTop measured $ratio:1');
    });

    test('its darkest end is far clear of AAA', () {
      final ratio = HeroBackdrop.contrastWithWhite(HeroBackdrop.skyBottom);
      expect(ratio, greaterThan(15), reason: 'skyBottom measured $ratio:1');
    });

    test('it runs light to dark, not the other way', () {
      // The densest type — greeting, quote, countdown — sits in the lower
      // half, so that is the end that has to be darkest.
      expect(
        HeroBackdrop.contrastWithWhite(HeroBackdrop.skyBottom),
        greaterThan(HeroBackdrop.contrastWithWhite(HeroBackdrop.skyTop)),
      );
    });
  });

  group('the halos', () {
    test('the brightest point on the hero still clears AAA', () {
      // The worst case anywhere: the upper halo at full strength over the
      // lightest end of the gradient.
      final worst = _underHalo(HeroBackdrop.skyTop, HeroBackdrop.glowAlpha);
      final ratio = HeroBackdrop.contrastWithWhite(worst);

      expect(
        ratio,
        greaterThan(_aaa),
        reason: 'the lit region measured $ratio:1 — white type sits on it',
      );
    });

    test('the lower halo clears AAA too', () {
      final lit = _underHalo(
        HeroBackdrop.skyBottom,
        HeroBackdrop.glowAlphaLower,
      );
      expect(HeroBackdrop.contrastWithWhite(lit), greaterThan(_aaa));
    });

    test('the share card\'s own halo alpha would cost this hero its AAA', () {
      // Not a hypothetical. `ShareCard._DecorativeOrbs` draws these at 0.40,
      // which is right over a card carrying one line of type; copied onto the
      // surface the app opens to it measures 5.2:1 — still AA, no longer AAA.
      // This is the reason the constant is 0.15 and documented as load-bearing.
      final tooBright = _underHalo(HeroBackdrop.skyTop, 0.40);
      final ratio = HeroBackdrop.contrastWithWhite(tooBright);

      expect(ratio, lessThan(_aaa), reason: '0.40 measured $ratio:1');
      expect(ratio, greaterThan(_aa), reason: 'and it was never below AA');
    });

    test('the chosen alpha has real headroom over the failing one', () {
      expect(HeroBackdrop.glowAlpha, lessThan(0.40));
      expect(
        HeroBackdrop.glowAlphaLower,
        lessThanOrEqualTo(HeroBackdrop.glowAlpha),
      );
    });
  });

  group('the wordmark', () {
    test('stays a ground rather than a heading', () {
      expect(HeroBackdrop.wordmarkAlpha, lessThan(0.12));
    });

    test('clears AAA where it actually sits', () {
      // RTL bottomEnd is the bottom LEFT — the dark end of the gradient, under
      // the lower halo and the opposite corner from the bright one. That
      // placement is load-bearing, not decorative.
      final lit = _underHalo(
        HeroBackdrop.skyBottom,
        HeroBackdrop.glowAlphaLower,
      );
      final withMark = HeroBackdrop.over(
        Colors.white,
        lit,
        HeroBackdrop.wordmarkAlpha,
      );
      final ratio = HeroBackdrop.contrastWithWhite(withMark);

      expect(ratio, greaterThan(_aaa), reason: 'measured $ratio:1');
    });

    test('even over the bright halo it would still clear AA', () {
      // The pessimistic case: if the wordmark were ever moved under the bright
      // halo, or the hero got short enough for them to meet. AAA is not
      // reachable there with a visible wordmark — it would need ~0.037 — so AA
      // is the honest floor, and the layout is what buys the rest.
      final lit = _underHalo(HeroBackdrop.skyTop, HeroBackdrop.glowAlpha);
      final withMark = HeroBackdrop.over(
        Colors.white,
        lit,
        HeroBackdrop.wordmarkAlpha,
      );

      expect(HeroBackdrop.contrastWithWhite(withMark), greaterThan(_aa));
    });

    test('is the app\'s own name', () {
      expect(HeroBackdrop.wordmark, 'وَذَكِّرْ');
    });
  });

  group('the luminance maths', () {
    test('agrees with the known anchors', () {
      // Sanity on the formula itself, so a bad refactor of it cannot make
      // every contrast assertion above pass vacuously.
      expect(HeroBackdrop.relativeLuminance(Colors.white), closeTo(1.0, 0.001));
      expect(HeroBackdrop.relativeLuminance(Colors.black), closeTo(0.0, 0.001));
      expect(HeroBackdrop.contrastWithWhite(Colors.white), closeTo(1.0, 0.01));
      expect(HeroBackdrop.contrastWithWhite(Colors.black), closeTo(21.0, 0.1));
    });

    test('compositing at alpha 0 and 1 is the identity it should be', () {
      final base = HeroBackdrop.skyTop;
      expect(HeroBackdrop.over(Colors.white, base, 0).r, closeTo(base.r, 1e-6));
      expect(HeroBackdrop.over(Colors.white, base, 1).r, closeTo(1.0, 1e-6));
    });
  });

  group('the rendered hero', () {
    testWidgets('draws a ground with no image in it', (tester) async {
      // The whole point of the item: eleven 1080px decodes and a 300-second
      // Timer.periodic leave the app's most-visited surface.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(children: [HeroBackdrop(borderRadius: 32)]),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the wordmark ignores the text scale', (tester) async {
      // At 1.6 a scaled wordmark would grow past the hero and stop being a
      // ground — it is decoration, and decoration does not scale with the
      // reader's text-size preference.
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: Scaffold(
              body: Stack(children: [HeroBackdrop(borderRadius: 32)]),
            ),
          ),
        ),
      );
      await tester.pump();

      final text = tester.widget<Text>(find.text(HeroBackdrop.wordmark));
      expect(text.textScaler, TextScaler.noScaling);
    });
  });
}
