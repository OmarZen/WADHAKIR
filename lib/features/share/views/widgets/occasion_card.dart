import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/share/models/occasion.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';
import 'package:wadhakir/features/share/views/widgets/share_action_button.dart';

/// The card that appears on the home screen on an occasion, and nothing at all
/// on an ordinary day — roadmap #23.
///
/// ## Why it disappears
///
/// A permanent «شارك بطاقة» entry would be one more thing on a home screen
/// PRODUCT.md wants calm, and it would be wrong fifty weeks of the year. This
/// is a card that knows what day it is: present on a Friday and on six annual
/// occasions, absent otherwise, with no empty state and no placeholder.
class OccasionCard extends StatelessWidget {
  const OccasionCard({super.key, this.now, this.hijri});

  /// Injectable so a widget test can be Friday, or Eid, without waiting.
  final DateTime? now;
  final HijriDateTime? hijri;

  /// The occasion to render, or null on an ordinary day.
  Occasion? get occasion {
    final gregorian = now ?? DateTime.now();
    return OccasionCalendar.forDate(
      gregorian: gregorian,
      // `HijriDateTime.now()` reads the device clock, so it is resolved here
      // rather than defaulted in the calendar, which stays pure.
      hijri: hijri ?? HijriDateTime.now(),
    );
  }

  static SharePayload payloadFor(Occasion occasion) => SharePayload(
    headline: occasion.dua,
    categoryLabel: occasion.greeting,
    // The attribution is not decoration and is never optional. An unsourced
    // dua forwarded at scale is how fabrications enter circulation — which is
    // what the anonymous JPEGs this feature replaces are already doing.
    reference: occasion.attribution,
    variant: ShareCardVariant.passage,
    captionOverride:
        '${occasion.greeting}\n\n${occasion.dua}\n${occasion.attribution}',
  );

  @override
  Widget build(BuildContext context) {
    final today = occasion;
    if (today == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = context.l10n;
    String tr(String key, String fallback) {
      final value = l10n?.translate(key);
      return value == null || value == key ? fallback : value;
    }

    final greeting = tr('occasion.${today.id}', today.greeting);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            today.isWeekly ? Icons.brightness_low_rounded : Icons.star_rounded,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr('occasion.share_prompt', 'أرسل بطاقة لمن تحب'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ShareActionButton(
            icon: Icons.ios_share_rounded,
            size: 22,
            color: theme.colorScheme.primary,
            payloadBuilder: () {
              // Re-read at tap time, not captured: the home screen can sit open
              // across midnight, and a Thursday-night card that still sends
              // «جمعة مباركة» on Saturday morning is worse than none.
              final current = occasion;
              return current == null ? null : payloadFor(current);
            },
          ),
        ],
      ),
    );
  }
}
