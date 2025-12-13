import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/bookmark_model.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
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
        final l10n = AppLocalizations.of(context);
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(l10n?.translate('hadith_library.delete_bookmark') ??
                  'Delete Bookmark'),
              content: Text(
                  l10n?.translate('hadith_library.delete_bookmark_confirm') ??
                      'Are you sure you want to delete this bookmark?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n?.translate('common.cancel') ?? 'Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                      l10n?.translate('hadith_library.delete') ?? 'Delete'),
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
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: collection.color.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: collection.color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                  color: collection.color.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: collection.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        collection.icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: size.width * 0.03),
                    Expanded(
                      child: Text(
                        collection.nameArabic,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: collection.color,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ScheherazadeNew',
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: collection.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.bookmark_rounded,
                        color: collection.color,
                        size: 16,
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
                        color: collection.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: collection.color.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: collection.color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatHadithReference(
                                  bookmark.hadithId, context),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: collection.color,
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
                        color: collection.color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 16,
                            color: collection.color.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)?.translate(
                                      'hadith_library.tap_to_read') ??
                                  'Tap to read the full hadith',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: collection.color.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Almarai',
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
                          color: collection.color.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: collection.color.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.note_outlined,
                              size: 16,
                              color: collection.color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bookmark.note!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontFamily: 'Almarai',
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
                          _formatDate(bookmark.createdAt, context),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.5),
                            fontFamily: 'Almarai',
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

  String _formatDate(DateTime date, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return l10n?.translate('hadith_library.today') ?? 'Today';
    } else if (difference.inDays == 1) {
      return l10n?.translate('hadith_library.yesterday') ?? 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${l10n?.translate('hadith_library.days_ago') ?? 'days ago'}';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} ${l10n?.translate('hadith_library.weeks_ago') ?? 'weeks ago'}';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ${l10n?.translate('hadith_library.months_ago') ?? 'months ago'}';
    } else {
      return '${(difference.inDays / 365).floor()} ${l10n?.translate('hadith_library.years_ago') ?? 'years ago'}';
    }
  }

  String _formatHadithReference(String hadithId, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Parse hadithId format: "bukhari_1_1" (collection_bookNumber_ourHadithNumber)
    final parts = hadithId.split('_');
    if (parts.length >= 3) {
      final bookNumber = parts[1];
      final ourHadithNumber = parts[2];
      final bookLabel = l10n?.translate('hadith_library.book') ?? 'Book';
      final hadithLabel = l10n?.translate('hadith_library.hadith') ?? 'Hadith';

      return '$bookLabel $bookNumber • $hadithLabel #$ourHadithNumber';
    }

    return hadithId;
  }
}
