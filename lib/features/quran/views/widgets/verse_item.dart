import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/verse_model.dart';

class VerseItem extends StatelessWidget {
  final VerseModel verse;
  final double fontSize;
  final bool showTranslation;
  final bool isBookmarked;
  final Function(VerseModel) onBookmarkPressed;
  final Function(VerseModel) onSharePressed;
  final Function(VerseModel) onCopyPressed;

  const VerseItem({
    super.key,
    required this.verse,
    this.fontSize = 1.0,
    this.showTranslation = true,
    this.isBookmarked = false,
    required this.onBookmarkPressed,
    required this.onSharePressed,
    required this.onCopyPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultFontSize = theme.textTheme.bodyLarge?.fontSize ?? 16;
    final scaledFontSize = defaultFontSize * fontSize;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Verse header with number and actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Verse number
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                  child: Center(
                    child: Text(
                      verse.number.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Copy icon
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => onCopyPressed(verse),
                  tooltip: context.l10n?.translate('copy') ?? 'Copy',
                  iconSize: 20,
                ),
                // Bookmark icon
                // IconButton(
                //   icon: Icon(
                //     isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                //     color: isBookmarked ? theme.colorScheme.primary : null,
                //   ),
                //   onPressed: () => onBookmarkPressed(verse),
                //   tooltip: context.l10n?.translate('bookmark') ?? 'Bookmark',
                //   iconSize: 20,
                // ),
                // Share icon
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => onSharePressed(verse),
                  tooltip: context.l10n?.translate('share') ?? 'Share',
                  iconSize: 20,
                ),
              ],
            ),
          ),
          // Verse text in Arabic
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              verse.text,
              style: TextStyle(
                fontSize: scaledFontSize * 1.4,
                fontFamily: 'ScheherazadeNew',
                height: 1.5,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          // Verse translation if enabled
          if (showTranslation && verse.translation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                verse.translation,
                style: TextStyle(
                  fontSize: scaledFontSize * 0.9,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          // Sajdah indication if applicable
          if (verse.sajdah)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_downward,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sajdah verse',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
