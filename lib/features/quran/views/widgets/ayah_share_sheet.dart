import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_library/quran_library.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/reading/reading_comfort.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';

/// Roadmap #22 — what a long-press on an ayah offers.
///
/// ## Why this is the highest-value item in R4
///
/// The Quran screen was a 122-line dead end: every pixel of it belongs to
/// `quran_library`, and sending an ayah to someone meant leaving the app,
/// finding the verse somewhere else, and copying it from there. Sending an ayah
/// is the single most common Islamic sharing behaviour in the Arab world, and
/// the app that owns the mushaf was the one place it could not be done.
///
/// The library has exposed `onAyahLongPress` the whole time. Nothing was using
/// it.
class AyahShareSheet extends StatelessWidget {
  const AyahShareSheet({super.key, required this.ayah});

  final AyahModel ayah;

  static Future<void> show(BuildContext context, AyahModel ayah) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => AyahShareSheet(ayah: ayah),
    );
  }

  /// «سورة الكهف — ١٠».
  ///
  /// Arabic-Indic numerals via [WirdFormat.toArabicDigits], the same formatter
  /// the rest of the app counts with — a verse reference in Western digits in
  /// the middle of an Arabic card reads as a foreign object.
  String get reference {
    final surah = ayah.arabicName?.trim();
    final number = WirdFormat.toArabicDigits(ayah.ayahNumber);
    if (surah == null || surah.isEmpty) return 'آية $number';
    // The library's names already carry the word «سورة» on some builds and not
    // on others; adding a second one is worse than adding none.
    final named = surah.startsWith('سورة') ? surah : 'سورة $surah';
    return '$named — $number';
  }

  /// The ayah as it should travel.
  ///
  /// `text` is the Uthmani script the mushaf renders. `ayaTextEmlaey` is the
  /// plain-script version, which is what a recipient's keyboard font can
  /// actually display — several Android and WhatsApp font stacks drop the
  /// Uthmani diacritics and render tofu. Prefer the Uthmani for the *card*,
  /// which this app rasterises itself, and fall back to plain script if the
  /// mushaf text is unexpectedly empty.
  String get ayahText {
    final uthmani = ayah.text.trim();
    if (uthmani.isNotEmpty) return uthmani;
    return ayah.ayaTextEmlaey.trim();
  }

  /// What goes on the clipboard and into a text-only share.
  ///
  /// Plain script here, deliberately, for the font reason above: a card is a
  /// picture and always renders, but pasted text has to survive whatever the
  /// receiving app decides to draw it with.
  String get plainForCopy {
    final plain = ayah.ayaTextEmlaey.trim();
    final body = plain.isNotEmpty ? plain : ayahText;
    return '﴿ $body ﴾\n$reference';
  }

  SharePayload get payload => SharePayload(
    headline: ayahText,
    reference: reference,
    // Long verses are common, and shrinking one to fit a fixed box is how an
    // ayah becomes unreadable. The passage layout grows instead, and R4's
    // 9:16 floor keeps a short one Status-shaped.
    variant: ShareCardVariant.passage,
    captionOverride:
        '$plainForCopy\n\n${AppConstants.appName}\n'
        '${AppConstants.playStoreUrl}',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    String tr(String key, String fallback) {
      final value = l10n?.translate(key);
      return value == null || value == key ? fallback : value;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              reference,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // A preview, capped: the sheet is a menu, not a reader. The mushaf
            // behind it is the reader.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Text(
                  ayahText,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: ReadingComfortScope.of(context).apply(
                    theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'ScheherazadeNew',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _action(
              context,
              icon: Icons.image_outlined,
              label: tr('quran.share_as_image', 'مشاركة كبطاقة'),
              primary: true,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(
                  context,
                ).pushNamed(AppConstants.shareRoute, arguments: payload);
              },
            ),
            const SizedBox(height: 8),
            _action(
              context,
              icon: Icons.text_snippet_outlined,
              label: tr('quran.share_as_text', 'مشاركة كنص'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(
                  AppConstants.shareRoute,
                  // Same payload; the share screen's own "text only" action is
                  // the text path, so there is one card definition rather than
                  // two that can drift.
                  arguments: payload,
                );
              },
            ),
            const SizedBox(height: 8),
            _action(
              context,
              icon: Icons.copy_rounded,
              label: tr('quran.copy_ayah', 'نسخ الآية'),
              onTap: () async {
                final copied = tr('azkar.text_copied', 'تم النسخ');
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: plainForCopy));
                if (!context.mounted) return;
                Navigator.of(context).pop();
                messenger.showSnackBar(SnackBar(content: Text(copied)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    final theme = Theme.of(context);
    return primary
        ? FilledButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          );
  }
}
