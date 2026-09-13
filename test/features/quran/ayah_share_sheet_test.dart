import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/quran_library.dart';
import 'package:wadhakir/features/quran/views/widgets/ayah_share_sheet.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';

/// Roadmap #22 — what an ayah looks like on its way out of the app.
///
/// The reference and the text choice are the whole product decision here, and
/// both fail *quietly* when they are wrong: a verse labelled «سورة سورة الكهف»
/// or rendered as tofu in WhatsApp still shares successfully.
AyahModel ayah({
  String text = 'وَمَن يَتَّقِ ٱللَّهَ يَجْعَل لَّهُۥ مَخْرَجًا',
  String plain = 'ومن يتق الله يجعل له مخرجا',
  String? arabicName = 'الكهف',
  int number = 10,
}) => AyahModel(
  ayahUQNumber: 1,
  ayahNumber: number,
  text: text,
  ayaTextEmlaey: plain,
  juz: 1,
  page: 1,
)..arabicName = arabicName;

void main() {
  group('the reference', () {
    test('reads «سورة الكهف — ١٠» with Arabic-Indic numerals', () {
      // Western digits inside an Arabic card read as a foreign object.
      expect(AyahShareSheet(ayah: ayah()).reference, 'سورة الكهف — ١٠');
    });

    test('does not say «سورة» twice', () {
      // The library's surah names carry the word on some builds and not on
      // others, and a doubled one is the kind of mistake a reader notices
      // immediately and the app never reports.
      expect(
        AyahShareSheet(ayah: ayah(arabicName: 'سورة الكهف')).reference,
        'سورة الكهف — ١٠',
      );
    });

    test('multi-digit ayah numbers convert fully', () {
      expect(
        AyahShareSheet(ayah: ayah(number: 255)).reference,
        'سورة الكهف — ٢٥٥',
      );
    });

    test('a missing surah name still produces a usable reference', () {
      for (final missing in <String?>[null, '', '   ']) {
        expect(
          AyahShareSheet(ayah: ayah(arabicName: missing)).reference,
          'آية ١٠',
          reason: 'a blank name must not leave a dangling dash',
        );
      }
    });
  });

  group('which script travels', () {
    test('the CARD gets the Uthmani text', () {
      // The app rasterises the card itself with a bundled font, so it can
      // render the mushaf script faithfully.
      final sheet = AyahShareSheet(ayah: ayah());
      expect(sheet.payload.headline, contains('ٱللَّهَ'));
    });

    test('the CLIPBOARD gets the plain script', () {
      // Pasted text has to survive whatever font the receiving app draws it
      // with, and several Android and WhatsApp stacks drop Uthmani diacritics
      // and render tofu.
      final sheet = AyahShareSheet(ayah: ayah());
      expect(sheet.plainForCopy, contains('ومن يتق الله'));
      expect(sheet.plainForCopy, isNot(contains('ٱللَّهَ')));
    });

    test('the copy is wrapped in ayah brackets and carries the reference', () {
      final copied = AyahShareSheet(ayah: ayah()).plainForCopy;
      expect(copied, startsWith('﴿'));
      expect(copied, contains('﴾'));
      expect(copied, contains('سورة الكهف — ١٠'));
    });

    test('an empty mushaf text falls back to the plain script', () {
      final sheet = AyahShareSheet(ayah: ayah(text: '   '));
      expect(sheet.ayahText, 'ومن يتق الله يجعل له مخرجا');
      expect(sheet.payload.headline, isNotEmpty);
    });
  });

  group('the payload', () {
    test('uses the passage layout so a long verse is not shrunk', () {
      // The compact card scales text down to fit a fixed box. Doing that to an
      // ayah is how it becomes unreadable, which is the opposite of the point.
      expect(
        AyahShareSheet(ayah: ayah()).payload.variant,
        ShareCardVariant.passage,
      );
    });

    test('inherits the 9:16 story ratio', () {
      expect(
        AyahShareSheet(ayah: ayah()).payload.ratio,
        ShareCardRatio.story,
        reason: 'WhatsApp Status is where an ayah actually gets sent',
      );
    });

    test('the caption carries the plain script, not the Uthmani', () {
      // The caption is text in the share sheet, subject to the same font
      // problem as the clipboard.
      final caption = AyahShareSheet(ayah: ayah()).payload.captionOverride!;
      expect(caption, contains('ومن يتق الله'));
      expect(caption, contains('سورة الكهف — ١٠'));
    });
  });
}
