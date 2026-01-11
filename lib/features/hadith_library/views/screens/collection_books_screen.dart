import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/core/widgets/loading_indicator.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/domain/usecases/get_books_list_usecase.dart';
import 'package:wadhakir/data/models/hadith_collection_metadata.dart';
import 'package:wadhakir/domain/usecases/get_hadith_book_usecase.dart';
import 'package:wadhakir/data/repositories/hadith_repository_impl.dart';
import 'package:wadhakir/data/repositories/bookmark_repository_impl.dart';
import 'package:wadhakir/features/hadith_library/cubit/hadith_library_cubit.dart';
import 'package:wadhakir/features/hadith_library/cubit/hadith_library_state.dart';
import 'package:wadhakir/features/hadith_library/views/widgets/book_item_card.dart';

/// Screen showing all books in a collection
class CollectionBooksScreen extends StatelessWidget {
  final HadithCollectionMetadata collection;

  const CollectionBooksScreen({
    super.key,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final hadithRepo = HadithRepositoryImpl();
        final bookmarkRepo = BookmarkRepositoryImpl();

        return HadithLibraryCubit(
          getHadithBookUseCase: GetHadithBookUseCase(hadithRepo),
          getBooksListUseCase: GetBooksListUseCase(hadithRepo),
          bookmarkRepository: bookmarkRepo,
        )..loadBooks(collection.id);
      },
      child: _CollectionBooksView(collection: collection),
    );
  }
}

class _CollectionBooksView extends StatelessWidget {
  final HadithCollectionMetadata collection;

  const _CollectionBooksView({required this.collection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<HadithLibraryCubit, HadithLibraryState>(
        builder: (context, state) {
          if (state is HadithLibraryLoading) {
            return const LoadingIndicator();
          } else if (state is HadithBooksLoaded) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App Bar with collection info
                _buildAppBar(context, theme, size, l10n),

                SliverToBoxAdapter(
                  child: SizedBox(height: size.height * 0.02),
                ),

                // Collection Description
                SliverToBoxAdapter(
                  child: _buildDescription(context, theme, size, l10n),
                ),

                SliverToBoxAdapter(child: SizedBox(height: size.height * 0.02)),

                // Books List
                _buildBooksList(context, state, theme, size),

                SliverToBoxAdapter(child: SizedBox(height: size.height * 0.02)),
              ],
            );
          } else if (state is HadithLibraryError) {
            return _buildError(context, state, theme, l10n);
          }

          return const LoadingIndicator();
        },
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    Size size,
    AppLocalizations? l10n,
  ) {
    return SliverAppBar(
      // expandedHeight: size.height * 0.1,
      pinned: true,
      stretch: true,
      backgroundColor: collection.color,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          collection.nameArabic,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'ScheherazadeNew',
            fontSize: 20,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    collection.color,
                    collection.color.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: Icon(
                collection.icon,
                size: 200,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(
    BuildContext context,
    ThemeData theme,
    Size size,
    AppLocalizations? l10n,
  ) {
    final isDesktop = PlatformUtils.isDesktop;
    final horizontalPadding = isDesktop ? 24.0 : size.width * 0.04;
    final maxWidth = isDesktop ? 1400.0 : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
          padding: EdgeInsets.all(size.width * 0.04),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                collection.color.withValues(alpha: 0.1),
                collection.color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: collection.color.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: collection.color,
                    size: 20,
                  ),
                  SizedBox(width: size.width * 0.02),
                  Text(
                    l10n?.translate('hadith_library.about_collection') ??
                        'About Collection',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: collection.color,
                      fontFamily: 'Almarai',
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.01),
              Text(
                collection.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontFamily: 'Almarai',
                ),
              ),
              SizedBox(height: size.height * 0.015),
              Wrap(
                spacing: size.width * 0.02,
                runSpacing: size.height * 0.01,
                children: [
                  _buildInfoChip(
                    context,
                    Icons.menu_book_rounded,
                    '${collection.totalHadiths} حديث',
                    theme,
                  ),
                  _buildInfoChip(
                    context,
                    Icons.category_rounded,
                    collection.nameEnglish,
                    theme,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: collection.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: collection.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: collection.color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: collection.color,
              fontWeight: FontWeight.bold,
              fontFamily: 'Almarai',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList(
    BuildContext context,
    HadithBooksLoaded state,
    ThemeData theme,
    Size size,
  ) {
    // state.books is Map<int, String> - bookNumber: bookName
    final bookEntries = state.books.entries.toList();
    final isDesktop = PlatformUtils.isDesktop;
    final width = size.width;
    final horizontalPadding = isDesktop ? 24.0 : size.width * 0.04;
    final maxWidth = isDesktop ? 1400.0 : double.infinity;

    // Determine grid columns for desktop
    int crossAxisCount = 1;
    if (isDesktop) {
      if (width >= 1400) {
        crossAxisCount = 3;
      } else if (width >= 900) {
        crossAxisCount = 2;
      }
    }

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: isDesktop && crossAxisCount > 1
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 4.0,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: bookEntries.length,
                    itemBuilder: (context, index) {
                      final entry = bookEntries[index];
                      return BookItemCard(
                        bookNumber: entry.key,
                        bookName: entry.value,
                        collection: collection,
                      );
                    },
                  )
                : Column(
                    children: bookEntries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: size.height * 0.015),
                        child: BookItemCard(
                          bookNumber: entry.key,
                          bookName: entry.value,
                          collection: collection,
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    HadithLibraryError state,
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
              context.read<HadithLibraryCubit>().loadBooks(collection.id);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n?.translate('hadith_library.retry') ?? 'Retry'),
          ),
        ],
      ),
    );
  }
}
