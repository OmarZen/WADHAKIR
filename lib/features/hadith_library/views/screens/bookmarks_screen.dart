import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/widgets/loading_indicator.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/domain/usecases/add_bookmark_usecase.dart';
import 'package:wadhakir/data/models/hadith_collection_metadata.dart';
import 'package:wadhakir/domain/usecases/remove_bookmark_usecase.dart';
import 'package:wadhakir/data/repositories/hadith_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_all_bookmarks_usecase.dart';
import 'package:wadhakir/data/repositories/bookmark_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_all_collections_usecase.dart';
import 'package:wadhakir/features/hadith_library/cubit/bookmark_cubit.dart';
import 'package:wadhakir/features/hadith_library/cubit/bookmark_state.dart';
import 'package:wadhakir/features/hadith_library/views/widgets/bookmark_item_card.dart';
import 'package:wadhakir/features/hadith_library/views/screens/hadith_reader_screen.dart';

/// Screen for managing all bookmarks
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

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
      child: const _BookmarksView(),
    );
  }
}

class _BookmarksView extends StatefulWidget {
  const _BookmarksView();

  @override
  State<_BookmarksView> createState() => _BookmarksViewState();
}

class _BookmarksViewState extends State<_BookmarksView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(context, theme, size, l10n),

            // Search Bar
            _buildSearchBar(theme, size, l10n),

            // Content
            Expanded(
              child: BlocBuilder<BookmarkCubit, BookmarkState>(
                builder: (context, state) {
                  if (state is BookmarkLoading) {
                    return const LoadingIndicator();
                  } else if (state is BookmarksLoaded) {
                    return _buildContent(context, state, theme, size, l10n);
                  } else if (state is BookmarkError) {
                    return _buildError(context, state, theme, l10n);
                  }

                  return const LoadingIndicator();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    Size size,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_rounded, color: theme.primaryColor),
          ),
          SizedBox(width: size.width * 0.02),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.translate('hadith_library.my_bookmarks') ??
                      'My Bookmarks',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Almarai',
                  ),
                ),
                BlocBuilder<BookmarkCubit, BookmarkState>(
                  builder: (context, state) {
                    if (state is BookmarksLoaded) {
                      return Text(
                        '${state.bookmarks.length} ${l10n?.translate('hadith_library.bookmarks') ?? 'bookmarks'}',
                        style: theme.textTheme.bodySmall,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, Size size, AppLocalizations? l10n) {
    return Padding(
      padding: EdgeInsets.all(size.width * 0.04),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
        decoration: InputDecoration(
          hintText:
              l10n?.translate('hadith_library.search_bookmarks') ?? 'Search...',
          prefixIcon: Icon(Icons.search_rounded, color: theme.primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.clear_rounded),
                )
              : null,
          filled: true,
          fillColor: theme.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BookmarksLoaded state,
    ThemeData theme,
    Size size,
    AppLocalizations? l10n,
  ) {
    // All Bookmarks
    return _buildBookmarksList(
      context,
      state.bookmarks
          .where((b) =>
              _searchQuery.isEmpty ||
              (b.note?.toLowerCase().contains(_searchQuery) ?? false))
          .toList(),
      theme,
      size,
      l10n,
    );
  }

  Widget _buildBookmarksList(
    BuildContext context,
    List bookmarks,
    ThemeData theme,
    Size size,
    AppLocalizations? l10n,
  ) {
    if (bookmarks.isEmpty) {
      return _buildEmptyState(theme, size, l10n);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];

        return Padding(
          padding: EdgeInsets.only(bottom: size.height * 0.015),
          child: BookmarkItemCard(
            bookmark: bookmark,
            onDelete: () {
              context.read<BookmarkCubit>().removeBookmark(bookmark.hadithId);
            },
            onTap: () async {
              // Extract collection from hadithId (format: "bukhari_1_1")
              final collectionId = bookmark.hadithId.split('_').first;
              final collection = HadithCollectionMetadata.getById(collectionId);

              if (collection == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n?.translate(
                            'hadith_library.collection_not_found') ??
                        'Collection not found'),
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                // Load the hadith from repository
                final hadithRepo = HadithRepositoryImpl();
                final hadith =
                    await hadithRepo.getHadithById(bookmark.hadithId);

                // Close loading dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }

                if (hadith == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n?.translate(
                                'hadith_library.hadith_not_found') ??
                            'Hadith not found'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                  return;
                }

                // Navigate to hadith reader
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HadithReaderScreen(
                        hadith: hadith,
                        collection: collection,
                      ),
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${l10n?.translate('hadith_library.error_loading_hadith') ?? 'Error loading hadith'}: $e'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    Size size,
    AppLocalizations? l10n,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 80,
            color: theme.disabledColor,
          ),
          SizedBox(height: size.height * 0.02),
          Text(
            l10n?.translate('hadith_library.no_bookmarks') ??
                'No bookmarks yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
              fontFamily: 'Almarai',
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            l10n?.translate('hadith_library.start_bookmarking') ??
                'Start bookmarking your favorite hadiths',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    BookmarkError state,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            state.message,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<BookmarkCubit>().loadBookmarks();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n?.translate('hadith_library.retry') ?? 'Retry'),
          ),
        ],
      ),
    );
  }
}
