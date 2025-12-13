import 'package:flutter/material.dart';
import '../../../../data/models/hadith_model.dart';
import '../../../../data/models/hadith_collection_metadata.dart';
import 'package:wadhakir/features/hadith_library/views/screens/hadith_reader_screen.dart';

/// Compact preview card for hadith in list view
class HadithPreviewCard extends StatelessWidget {
  final HadithModel hadith;
  final HadithCollectionMetadata collection;
  final bool showTranslation;

  const HadithPreviewCard({
    super.key,
    required this.hadith,
    required this.collection,
    this.showTranslation = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HadithReaderScreen(
              hadith: hadith,
              collection: collection,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: collection.color.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with number and collection
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.04,
                vertical: size.height * 0.015,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    collection.color.withValues(alpha: 0.1),
                    collection.color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: collection.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${hadith.ourHadithNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: collection.color,
                  ),
                ],
              ),
            ),

            // Arabic Text
            Padding(
              padding: EdgeInsets.all(size.width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    hadith.hadithTextArabic,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: 'ScheherazadeNew',
                      fontSize: 18,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showTranslation &&
                      (hadith.hadithTextEnglish?.isNotEmpty ?? false)) ...[
                    SizedBox(height: size.height * 0.015),
                    Container(
                      padding: EdgeInsets.all(size.width * 0.03),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hadith.hadithTextEnglish ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (hadith.narrator?.isNotEmpty ?? false) ...[
                    SizedBox(height: size.height * 0.01),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: collection.color,
                        ),
                        SizedBox(width: size.width * 0.01),
                        Expanded(
                          child: Text(
                            hadith.narrator ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: collection.color,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
