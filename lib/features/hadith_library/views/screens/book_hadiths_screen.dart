import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/widgets/loading_indicator.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/hadith_collection_metadata.dart';
import 'package:wadhakir/domain/usecases/get_books_list_usecase.dart';
import 'package:wadhakir/domain/usecases/get_hadith_book_usecase.dart';
import 'package:wadhakir/data/repositories/hadith_repository_impl.dart';
import 'package:wadhakir/data/repositories/bookmark_repository_impl.dart';
import 'package:wadhakir/features/hadith_library/cubit/hadith_library_cubit.dart';
import 'package:wadhakir/features/hadith_library/cubit/hadith_library_state.dart';
import 'package:wadhakir/features/hadith_library/views/widgets/hadith_preview_card.dart';

/// Screen showing all hadiths in a specific book
class BookHadithsScreen extends StatelessWidget {
  final HadithCollectionMetadata collection;
  final int bookNumber;
  final String bookName;

  const BookHadithsScreen({
    super.key,
    required this.collection,
    required this.bookNumber,
    required this.bookName,
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
        )..loadHadiths(collectionId: collection.id, bookNumber: bookNumber);
      },
      child: _BookHadithsView(
        collection: collection,
        bookNumber: bookNumber,
        bookName: bookName,
      ),
    );
  }
}

class _BookHadithsView extends StatefulWidget {
  final HadithCollectionMetadata collection;
  final int bookNumber;
  final String bookName;

  const _BookHadithsView({
    required this.collection,
    required this.bookNumber,
    required this.bookName,
  });

  @override
  State<_BookHadithsView> createState() => _BookHadithsViewState();
}

class _BookHadithsViewState extends State<_BookHadithsView> {
  bool _showTranslation = true;

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
          } else if (state is HadithsLoaded) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App Bar
                _buildAppBar(context, theme, size, l10n, state),

                SliverToBoxAdapter(child: SizedBox(height: size.height * 0.02)),

                // Hadiths List
                _buildHadithsList(context, state, theme, size),

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
    HadithsLoaded state,
  ) {
    return SliverAppBar(
      // expandedHeight: size.height * 0.15,
      pinned: true,
      backgroundColor: widget.collection.color,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      actions: [
        // Language Toggle
        IconButton(
          onPressed: () {
            setState(() {
              _showTranslation = !_showTranslation;
            });
          },
          icon: Icon(
            _showTranslation
                ? Icons.translate_rounded
                : Icons.g_translate_rounded,
            color: Colors.white,
          ),
          tooltip: _showTranslation
              ? (l10n?.translate('hadith_library.hide_translation') ??
                  'Hide Translation')
              : (l10n?.translate('hadith_library.show_translation') ??
                  'Show Translation'),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bookName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Almarai',
                fontSize: 16,
              ),
            ),
            Text(
              '${state.hadiths.length} حديث',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'Almarai',
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.collection.color,
                widget.collection.color.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHadithsList(
    BuildContext context,
    HadithsLoaded state,
    ThemeData theme,
    Size size,
  ) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final hadith = state.hadiths[index];
            return Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.015),
              child: HadithPreviewCard(
                hadith: hadith,
                collection: widget.collection,
                showTranslation: _showTranslation,
              ),
            );
          },
          childCount: state.hadiths.length,
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
              context.read<HadithLibraryCubit>().loadHadiths(
                  collectionId: widget.collection.id,
                  bookNumber: widget.bookNumber);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n?.translate('hadith_library.retry') ?? 'Retry'),
          ),
        ],
      ),
    );
  }
}
