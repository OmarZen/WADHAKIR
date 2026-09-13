import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/data/models/wird/wird_enums.dart';
import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';

/// The card a finished khatma can send — roadmap #21.
///
/// ## What is on it, and what is deliberately not
///
/// The dedication, and never the progress. R1 added `intention` / `dedication`
/// to [WirdPlanModel] and gave them nowhere to go but a reminder body; this is
/// the distribution surface they were waiting for, and «إهداءً إلى روح والدي»
/// on a card is the emotional payload the research said group khatma was
/// chasing — reachable, it turns out, without a backend.
///
/// What never goes on it is the tally. A card saying day 14 of 30, or 47%, is
/// a scoreboard, and scorekeeping is what `PRODUCT.md` rules out and why the
/// tasbih gets no share button at all. The completed khatma is the news; how
/// fast it went is nobody's business.
///
/// ## Why the verse and not a dua
///
/// `Occasion` states this app's content rule plainly — nothing ships on a card
/// without a named narration, because an unsourced dua forwarded at scale is
/// how fabrications enter circulation. The khatm duas in wide circulation have
/// contested chains, so this card carries a verse instead: the citation is then
/// exact by construction, and a khatma ending on the Qur'an's own words is the
/// better card anyway.
class WirdShare {
  const WirdShare._();

  /// «الحمد لله الذي هدانا لهذا وما كنا لنهتدي لولا أن هدانا الله».
  ///
  /// Chosen because it fits every dedication this feature offers — for the
  /// dead, for the sick, in gratitude, or for nobody — without changing its
  /// meaning. Swap it freely; the citation below must move with it.
  static const String verse =
      'الْحَمْدُ لِلَّهِ الَّذِي هَدَانَا لِهَٰذَا وَمَا كُنَّا '
      'لِنَهْتَدِيَ لَوْلَا أَنْ هَدَانَا اللَّهُ';

  /// Ships on the card. Never optional — see [WirdShare]'s note on the rule.
  static const String verseSource = 'الأعراف: ٤٣';

  /// Whether [plan] has a dedication worth putting on a card.
  ///
  /// A whitespace-only dedication counts as none: it would otherwise render as
  /// «إهداءً إلى» followed by nothing.
  static String? dedicationOf(WirdPlanModel plan) {
    final text = plan.dedication?.trim();
    if (text == null || text.isEmpty) return null;
    if (plan.intention == WirdIntention.none) return null;
    return text;
  }

  /// Builds the card for a completed [plan].
  ///
  /// [khatmaLabel] is «تمت الختمة» and [dedicatedToLabel] «إهداءً إلى», both
  /// passed in already localised so this stays a pure function — no
  /// `BuildContext`, testable without pumping a widget.
  static SharePayload build({
    required WirdPlanModel plan,
    required String khatmaLabel,
    required String dedicatedToLabel,
  }) {
    final dedication = dedicationOf(plan);
    final headline = dedication == null
        ? verse
        : '$dedicatedToLabel $dedication\n\n$verse';

    return SharePayload(
      headline: headline,
      categoryLabel: khatmaLabel,
      reference: verseSource,
      variant: ShareCardVariant.passage,
      captionOverride: _caption(headline, khatmaLabel),
    );
  }

  /// What "share text only" and "copy" send.
  ///
  /// Setting an override opts out of the default caption, which is the thing
  /// that normally appends the app name and the store link — so they are added
  /// here.
  static String _caption(String headline, String khatmaLabel) => [
    khatmaLabel,
    '',
    headline,
    verseSource,
    '',
    AppConstants.appName,
    AppConstants.playStoreUrl,
  ].join('\n');
}
