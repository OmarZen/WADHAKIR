import 'package:flutter/material.dart';
import '../../../../data/models/hadith_collection_metadata.dart';
import 'package:wadhakir/features/hadith_library/views/screens/collection_books_screen.dart';

/// Beautiful glassmorphic card for displaying hadith collection
class CollectionCard extends StatelessWidget {
  final HadithCollectionMetadata collection;

  const CollectionCard({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CollectionBooksScreen(collection: collection),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              collection.color.withValues(alpha: 0.15),
              collection.color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: collection.color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: collection.color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Islamic Pattern Background
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  collection.icon,
                  size: 100,
                  color: collection.color.withValues(alpha: 0.08),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(size.width * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: collection.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        collection.icon,
                        color: collection.color,
                        size: 28,
                      ),
                    ),

                    const Spacer(),

                    // Collection Name
                    Text(
                      collection.nameArabic,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ScheherazadeNew',
                        fontSize: 18,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: size.height * 0.005),

                    Text(
                      collection.nameEnglish,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: size.height * 0.01),

                    // Hadith Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: collection.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: collection.color.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${collection.totalHadiths} حديث',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: collection.color,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
