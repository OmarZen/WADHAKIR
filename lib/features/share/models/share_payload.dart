import 'package:flutter/foundation.dart';
import 'package:wadhakir/features/share/models/share_background.dart';

/// How the branded share card lays out its text.
///
/// - [compact]: fixed 4:5 card, single headline auto-shrunk to fit. Used by
///   azkar / short dhikr.
/// - [passage]: content-height card (grows with the text) showing the Arabic
///   headline plus an optional [SharePayload.secondaryText] (e.g. an English
///   translation) underneath. Used for long entries like the 40 Hadith so the
///   text stays readable instead of shrinking.
enum ShareCardVariant { compact, passage }

/// The shape of the exported card.
///
/// ## Why 9:16 is the default
///
/// WhatsApp Status is the dominant broadcast surface in this app's market, and
/// it is **strictly 9:16**. A 4:5 card posted there gets letterboxed with grey
/// bars, which is ugly enough that people screenshot the app instead of using
/// the share button that was built for them — the feature failing quietly, in a
/// way no error ever reports.
///
/// [post] is kept because 4:5 is still right for a feed — Instagram's own
/// portrait ratio, and what every card this app has shipped so far was drawn
/// at. Neither is a fallback for the other; they are two different places to
/// put a card, and the user picks.
enum ShareCardRatio {
  /// 9:16 — WhatsApp Status, Instagram Stories, anything full-screen portrait.
  story(9 / 16),

  /// 4:5 — Instagram and Facebook feed posts.
  post(4 / 5);

  final double value;
  const ShareCardRatio(this.value);
}

/// Data the branded share screen needs to render a card and assemble the
/// caption. Lives in `features/share` because it's the contract between
/// any feature that wants to share (azkar, fasting info, etc.) and the
/// shared share screen — neither side should know about the other.
///
/// Kept as a plain immutable model (no `freezed` etc.) to avoid pulling in
/// codegen for a value type.
@immutable
class SharePayload {
  /// The body of the card — typically Arabic dhikr / hadith / fasting day
  /// description. Rendered RTL in `ScheherazadeNew`.
  final String headline;

  /// Small label rendered under the headline ("أذكار الصباح", "صيام
  /// الإثنين"). Optional.
  final String? categoryLabel;

  /// Repetition count rendered as a small chip ("×100"). Optional.
  final int? repetitions;

  /// Source / reference shown as a faded footnote. Optional.
  final String? reference;

  /// The system-share caption that accompanies the PNG. The screen
  /// prepends the headline and appends app-link metadata, so callers
  /// don't need to repeat the dhikr text here.
  ///
  /// If null, the screen uses `headline + categoryLabel` automatically.
  final String? captionOverride;

  /// Optional secondary block rendered under the headline in the [
  /// ShareCardVariant.passage] layout — e.g. an English translation. Ignored
  /// by the compact variant.
  final String? secondaryText;

  /// Card layout. Defaults to [ShareCardVariant.compact].
  final ShareCardVariant variant;

  /// Exported shape. Defaults to [ShareCardRatio.story] — see that enum.
  ///
  /// Per-session, like [background]: the share screen lets the user switch, and
  /// the choice is not stored. Nothing persists a ratio, so there is no stored
  /// state to migrate and no way for an old value to go stale.
  final ShareCardRatio ratio;

  /// Whether [headline] is right-to-left (Arabic). When true the passage card
  /// renders it RTL in ScheherazadeNew; when false, LTR in the body font.
  /// Lets a feature share a single-language card (e.g. Arabic-only or
  /// English-only hadith).
  final bool headlineRtl;

  /// Card background. Null falls back to the brand gradient. The share screen
  /// lets the user swap this for a gradient preset, solid color, mosque photo
  /// or one of their own photos.
  final ShareBackground? background;

  const SharePayload({
    required this.headline,
    this.categoryLabel,
    this.repetitions,
    this.reference,
    this.captionOverride,
    this.secondaryText,
    this.variant = ShareCardVariant.compact,
    this.headlineRtl = true,
    this.background,
    this.ratio = ShareCardRatio.story,
  });

  /// Copy with a different [background] or [ratio] — the two fields the share
  /// screen's editor mutates.
  SharePayload copyWith({
    ShareBackground? background,
    ShareCardRatio? ratio,
    bool clearBackground = false,
  }) => SharePayload(
    headline: headline,
    categoryLabel: categoryLabel,
    repetitions: repetitions,
    reference: reference,
    captionOverride: captionOverride,
    secondaryText: secondaryText,
    variant: variant,
    headlineRtl: headlineRtl,
    // An explicit flag rather than "null means clear", because null is also
    // what "leave it alone" looks like — the same `_undefined`-sentinel problem
    // `WirdPlanModel.copyWith` solves, in the smallest form it takes.
    background: clearBackground ? null : (background ?? this.background),
    ratio: ratio ?? this.ratio,
  );

  /// Copy with a different [background].
  SharePayload withBackground(ShareBackground? background) =>
      copyWith(background: background, clearBackground: background == null);
}
