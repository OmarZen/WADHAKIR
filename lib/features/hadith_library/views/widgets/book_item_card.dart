import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/hadith_collection_metadata.dart';
import 'package:wadhakir/features/hadith_library/views/screens/book_hadiths_screen.dart';

/// Card for displaying a book in the collection
class BookItemCard extends StatelessWidget {
  final int bookNumber;
  final String bookName;
  final HadithCollectionMetadata collection;

  const BookItemCard({
    super.key,
    required this.bookNumber,
    required this.bookName,
    required this.collection,
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
            builder: (context) => BookHadithsScreen(
              collection: collection,
              bookNumber: bookNumber,
              bookName: bookName,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(size.width * 0.04),
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
        child: Row(
          children: [
            // Book Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    collection.color.withValues(alpha: 0.2),
                    collection.color.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.book_rounded,
                color: collection.color,
                size: 24,
              ),
            ),

            SizedBox(width: size.width * 0.03),
            // Book Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Almarai',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: size.height * 0.005),
                  Text(
                    collection.nameEnglish,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: collection.color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
