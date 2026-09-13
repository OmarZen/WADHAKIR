import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/features/share/models/share_background.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';
import 'package:wadhakir/features/share/views/widgets/share_card.dart';

/// Roadmap #20 — the 9:16 story-card substrate.
///
/// The point of the item is distribution: WhatsApp Status is strictly 9:16 and
/// is the dominant broadcast surface in this app's market, so a 4:5 card gets
/// grey bars and people screenshot the app instead of using its share button.
/// That failure is silent — nothing errors, the share just stops happening —
/// which is exactly why the ratio is pinned by a test.
SharePayload payload({
  ShareCardRatio ratio = ShareCardRatio.story,
  ShareCardVariant variant = ShareCardVariant.compact,
  String headline = 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
}) => SharePayload(headline: headline, variant: variant, ratio: ratio);

/// Renders a card at a fixed width and reports the size it took.
///
/// The surface is widened deliberately. The default 800×600 test view is
/// SHORTER than a 9:16 card drawn at any sensible width, so every measurement
/// would come back clamped to 600 — and a clamped card reports whatever ratio
/// the viewport happens to have, which is exactly the letterboxing this item
/// exists to remove, measured as if it were the answer.
Future<Size> renderedSize(
  WidgetTester tester,
  SharePayload p, {
  double width = 360,
}) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: width,
            child: RepaintBoundary(
              key: key,
              child: ShareCard(payload: p),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.getSize(find.byKey(key));
}

void main() {
  group('the ratio', () {
    test('story is 9:16 and post is 4:5', () {
      expect(ShareCardRatio.story.value, closeTo(9 / 16, 1e-9));
      expect(ShareCardRatio.post.value, closeTo(4 / 5, 1e-9));
    });

    test('a payload defaults to story', () {
      // The default IS the feature. A payload built by any of the twenty-odd
      // share buttons across the app must land on 9:16 without each caller
      // having to remember.
      expect(
        const SharePayload(headline: 'x').ratio,
        ShareCardRatio.story,
        reason: 'every share surface inherits this; do not flip it casually',
      );
    });

    test('copyWith changes the ratio and keeps everything else', () {
      const original = SharePayload(
        headline: 'headline',
        categoryLabel: 'أذكار الصباح',
        repetitions: 3,
        reference: 'مسلم',
        variant: ShareCardVariant.passage,
        headlineRtl: false,
      );

      final wide = original.copyWith(ratio: ShareCardRatio.post);

      expect(wide.ratio, ShareCardRatio.post);
      expect(wide.headline, 'headline');
      expect(wide.categoryLabel, 'أذكار الصباح');
      expect(wide.repetitions, 3);
      expect(wide.reference, 'مسلم');
      expect(wide.variant, ShareCardVariant.passage);
      expect(wide.headlineRtl, isFalse);
    });

    test('withBackground(null) actually clears the background', () {
      // The `_undefined`-sentinel problem in its smallest form: null is both
      // "clear it" and "leave it alone", and the wrong reading here would make
      // the brand default unreachable once a user had picked a photo.
      final withPhoto = const SharePayload(
        headline: 'x',
      ).withBackground(ShareBackground.brand);
      expect(withPhoto.background, isNotNull);
      expect(withPhoto.withBackground(null).background, isNull);
    });

    test('copyWith leaves the background alone when none is passed', () {
      final withPhoto = const SharePayload(
        headline: 'x',
      ).withBackground(ShareBackground.brand);

      // The other half of the same trap: changing only the ratio must not
      // silently drop the background the user just chose.
      final reshaped = withPhoto.copyWith(ratio: ShareCardRatio.post);
      expect(reshaped.background, isNotNull);
      expect(reshaped.ratio, ShareCardRatio.post);
    });
  });

  group('the rendered card', () {
    testWidgets('a compact card is 9:16 by default', (tester) async {
      final size = await renderedSize(tester, payload());
      expect(size.width / size.height, closeTo(9 / 16, 0.01));
    });

    testWidgets('a compact card honours the post ratio', (tester) async {
      final size = await renderedSize(
        tester,
        payload(ratio: ShareCardRatio.post),
      );
      expect(size.width / size.height, closeTo(4 / 5, 0.01));
    });

    testWidgets('a SHORT passage is lifted to the 9:16 floor', (tester) async {
      // Without the floor a short passage renders content-height, which comes
      // out near-square — the same letterboxing problem arriving from the other
      // side.
      final size = await renderedSize(
        tester,
        payload(variant: ShareCardVariant.passage, headline: 'الحمد لله'),
      );

      expect(size.height, greaterThanOrEqualTo(size.width / (9 / 16) - 1));
    });

    testWidgets('a LONG passage still grows past the floor', (tester) async {
      // The whole reason the passage variant exists: a long entry stays
      // readable instead of being shrunk to fit a box. The floor is a minimum,
      // never a cap.
      final long = 'وَمَنْ يَتَّقِ اللَّهَ يَجْعَلْ لَهُ مَخْرَجًا ' * 30;
      final size = await renderedSize(
        tester,
        payload(variant: ShareCardVariant.passage, headline: long),
      );

      expect(
        size.height,
        greaterThan(size.width / (9 / 16)),
        reason: 'the floor must not clip a long passage',
      );
    });
  });
}
