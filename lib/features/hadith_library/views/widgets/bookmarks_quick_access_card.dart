import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/domain/usecases/add_bookmark_usecase.dart';
import 'package:wadhakir/domain/usecases/remove_bookmark_usecase.dart';
import 'package:wadhakir/domain/usecases/get_all_bookmarks_usecase.dart';
import 'package:wadhakir/data/repositories/bookmark_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_all_collections_usecase.dart';
import 'package:wadhakir/features/hadith_library/cubit/bookmark_cubit.dart';
import 'package:wadhakir/features/hadith_library/cubit/bookmark_state.dart';
import 'package:wadhakir/features/hadith_library/views/screens/bookmarks_screen.dart';

/// Quick access card for bookmarks with stats
class BookmarksQuickAccessCard extends StatelessWidget {
  const BookmarksQuickAccessCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bookmarkRepo = BookmarkRepositoryImpl();
        return BookmarkCubit(
          addBookmarkUseCase: AddBookmarkUseCase(bookmarkRepo),
          removeBookmarkUseCase: RemoveBookmarkUseCase(bookmarkRepo),
          getAllBookmarksUseCase: GetAllBookmarksUseCase(bookmarkRepo),
          getAllCollectionsUseCase: GetAllCollectionsUseCase(bookmarkRepo),
          bookmarkRepository: bookmarkRepo,
        )..loadBookmarks();
      },
      child: const _BookmarksQuickAccessContent(),
    );
  }
}

class _BookmarksQuickAccessContent extends StatelessWidget {
  const _BookmarksQuickAccessContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<BookmarkCubit, BookmarkState>(
      builder: (context, state) {
        int bookmarkCount = 0;

        if (state is BookmarksLoaded) {
          bookmarkCount = state.bookmarks.length;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BookmarksScreen(),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(size.width * 0.04),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor.withValues(alpha: 0.1),
                  theme.primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bookmark_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                SizedBox(width: size.width * 0.04),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.translate('hadith_library.my_bookmarks') ??
                            'My Bookmarks',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                        ),
                      ),
                      SizedBox(height: size.height * 0.004),
                      Row(
                        children: [
                          Icon(
                            Icons.bookmark_outline_rounded,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                          SizedBox(width: size.width * 0.01),
                          Text(
                            '$bookmarkCount ${l10n?.translate('hadith_library.bookmarks') ?? 'bookmarks'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
