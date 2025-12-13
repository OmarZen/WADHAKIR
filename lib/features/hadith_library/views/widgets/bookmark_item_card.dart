import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/bookmark_model.dart';
import 'package:wadhakir/data/models/hadith_collection_metadata.dart';

/// Card for displaying a bookmark with swipe actions
class BookmarkItemCard extends StatelessWidget {
  final BookmarkModel bookmark;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const BookmarkItemCard({
    super.key,
    required this.bookmark,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Extract collection from hadithId (format: "bukhari_1_1")
    final collectionId = bookmark.hadithId.split('_').first;
    final collection = HadithCollectionMetadata.getById(collectionId);

    if (collection == null) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key(bookmark.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: size.width * 0.04),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Bookmark'),
              content:
                  const Text('Are you sure you want to delete this bookmark?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        onDelete();
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.cardColor,
                theme.primaryColor.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04,
                  vertical: size.height * 0.015,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor.withValues(alpha: 0.08),
                      theme.primaryColor.withValues(alpha: 0.03),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        collection.icon,
                        color: theme.primaryColor,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: size.width * 0.02),
                    Expanded(
                      child: Text(
                        collection.nameArabic,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(size.width * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hadith Reference Info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor.withValues(alpha: 0.08),
                            theme.primaryColor.withValues(alpha: 0.03),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatHadithReference(bookmark.hadithId),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Almarai',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: size.height * 0.012),

                    // Hadith Preview Message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 16,
                            color: theme.primaryColor.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap to read the full hadith',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.primaryColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Note Section
                    if (bookmark.note != null && bookmark.note!.isNotEmpty) ...[
                      SizedBox(height: size.height * 0.015),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.note_outlined,
                              size: 16,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bookmark.note!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Saved Date
                    SizedBox(height: size.height * 0.01),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(bookmark.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }

  String _formatHadithReference(String hadithId) {
    // Parse hadithId format: "bukhari_1_1" (collection_bookNumber_ourHadithNumber)
    final parts = hadithId.split('_');
    if (parts.length >= 3) {
      final bookNumber = parts[1];
      final ourHadithNumber = parts[2];

      return 'Book $bookNumber • Hadith #$ourHadithNumber';
    }

    return hadithId;
  }
}
