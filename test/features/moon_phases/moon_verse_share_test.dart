import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';
import 'package:wadhakir/features/share/views/widgets/share_action_button.dart';
import 'package:wadhakir/features/moon_phases/views/widgets/moon_islamic_context.dart';

/// Roadmap #21 — sharing the āyāt on the moon detail screen.
///
/// These three verses were already correctly cited on screen. The risk in
/// giving them a share button is the citation getting left behind, which is the
/// exact failure `Occasion` documents: unsourced text forwarded at scale.

const _yunus =
    'هُوَ ٱلَّذِى جَعَلَ ٱلشَّمْسَ ضِيَآءًۭ وَٱلْقَمَرَ نُورًۭا '
    'وَقَدَّرَهُۥ مَنَازِلَ لِتَعْلَمُوا۟ عَدَدَ ٱلسِّنِينَ وَٱلْحِسَابَ';
const _yunusRef = 'سورة يونس · الآية 5';

SharePayload _payload({
  String verse = _yunus,
  String reference = _yunusRef,
  String categoryLabel = 'القمر في الإسلام',
}) => MoonIslamicContext.payloadFor(
  verse: verse,
  reference: reference,
  categoryLabel: categoryLabel,
);

void main() {
  group('the payload', () {
    test('carries the verse and its citation', () {
      final payload = _payload();
      expect(payload.headline, _yunus);
      expect(payload.reference, _yunusRef);
    });

    test('the citation is in the caption too', () {
      // The card and the text share are two separate paths to the same
      // recipient; a citation on only one of them is a citation missing half
      // the time.
      expect(_payload().captionOverride, contains(_yunusRef));
      expect(_payload().captionOverride, contains(_yunus));
    });

    test('appends the app name and store link', () {
      final caption = _payload().captionOverride!;
      expect(caption, contains(AppConstants.appName));
      expect(caption, contains(AppConstants.playStoreUrl));
    });

    test('is a passage card at the story ratio', () {
      // The Yunus āyah is ~90 characters. The compact card would shrink it to
      // fit, which is what the passage variant exists to avoid.
      final payload = _payload();
      expect(payload.variant, ShareCardVariant.passage);
      expect(payload.ratio, ShareCardRatio.story);
    });

    test('carries no commentary', () {
      // The commentary explains the screen to somebody already on it. What a
      // recipient gets is the āyah.
      final payload = _payload();
      expect(payload.secondaryText, isNull);
      expect(payload.captionOverride, isNot(contains('آية من آيات الله')));
    });

    test('a badge becomes the category when the verse has one', () {
      final payload = _payload(categoryLabel: 'انشقاق القمر');
      expect(payload.categoryLabel, 'انشقاق القمر');
    });
  });

  group('the screen', () {
    testWidgets('offers a share on every verse', (tester) async {
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: Color(0xFF0F1A2A),
              body: SingleChildScrollView(
                child: MoonIslamicContext(l10n: null),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Three verse cards, three buttons. A missing one is a verse the reader
      // can see but not send.
      expect(find.byType(ShareActionButton), findsNWidgets(3));
    });

    testWidgets('each button sends ITS OWN verse and citation', (tester) async {
      // The assertion that actually defends this feature. Every other test in
      // this file passes the verse and the reference in and asserts they come
      // back out, which cannot fail — `payloadFor` is a field shuffle. Swap two
      // `reference:` arguments in the widget and a reader forwards سورة يونس
      // cited as سورة القمر, correctly typeset, with no test complaining.
      //
      // So: build each payload the way the widget does, and check the pairing.
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: Color(0xFF0F1A2A),
              body: SingleChildScrollView(
                child: MoonIslamicContext(l10n: null),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Each verse and the surah its citation must name.
      const expected = {
        'وَقَدَّرَهُۥ مَنَازِلَ': 'يونس',
        'ٱقْتَرَبَتِ ٱلسَّاعَةُ': 'القمر',
        'يَسْـَٔلُونَكَ عَنِ ٱلْأَهِلَّةِ': 'البقرة',
      };

      final payloads = tester
          .widgetList<ShareActionButton>(find.byType(ShareActionButton))
          .map((b) => b.payloadBuilder())
          .toList();

      expect(payloads, hasLength(3));

      for (final entry in expected.entries) {
        final match = payloads.singleWhere(
          (p) => p!.headline.contains(entry.key),
          orElse: () => null,
        );
        expect(match, isNotNull, reason: 'no button carries ${entry.key}');
        expect(
          match!.reference,
          contains(entry.value),
          reason:
              '"${entry.key}" is cited as "${match.reference}" — '
              'it belongs to سورة ${entry.value}',
        );
      }
    });
  });
}
