import 'package:flutter/foundation.dart';

/// Data the branded share screen needs to render a card and assemble the
/// caption. Lives in `features/share` because it's the contract between
/// any feature that wants to share (azkar, fasting info, etc.) and the
/// shared share screen — neither side should know about the other.
///
/// Kept as a plain immutable model (no `freezed` etc.) to avoid pulling in
/// codegen for a 7-field value type.
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

  const SharePayload({
    required this.headline,
    this.categoryLabel,
    this.repetitions,
    this.reference,
    this.captionOverride,
  });
}
