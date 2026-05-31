import 'package:flutter/foundation.dart';

/// How the branded share card lays out its text.
///
/// - [compact]: fixed 4:5 card, single headline auto-shrunk to fit. Used by
///   azkar / short dhikr.
/// - [passage]: content-height card (grows with the text) showing the Arabic
///   headline plus an optional [SharePayload.secondaryText] (e.g. an English
///   translation) underneath. Used for long entries like the 40 Hadith so the
///   text stays readable instead of shrinking.
enum ShareCardVariant { compact, passage }

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

  /// Whether [headline] is right-to-left (Arabic). When true the passage card
  /// renders it RTL in ScheherazadeNew; when false, LTR in the body font.
  /// Lets a feature share a single-language card (e.g. Arabic-only or
  /// English-only hadith).
  final bool headlineRtl;

  const SharePayload({
    required this.headline,
    this.categoryLabel,
    this.repetitions,
    this.reference,
    this.captionOverride,
    this.secondaryText,
    this.variant = ShareCardVariant.compact,
    this.headlineRtl = true,
  });
}
