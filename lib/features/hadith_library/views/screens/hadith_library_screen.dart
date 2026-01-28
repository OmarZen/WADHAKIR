import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/core/widgets/loading_indicator.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/domain/usecases/get_books_list_usecase.dart';
import 'package:wadhakir/domain/usecases/get_hadith_book_usecase.dart';
import 'package:wadhakir/data/repositories/hadith_repository_impl.dart';
import 'package:wadhakir/data/repositories/bookmark_repository_impl.dart';
import 'package:wadhakir/features/hadith_library/cubit/hadith_library_cubit.dart';
import 'package:wadhakir/features/hadith_library/cubit/hadith_library_state.dart';
import 'package:wadhakir/features/hadith_library/views/screens/collection_books_screen.dart';
import 'package:wadhakir/features/hadith_library/views/widgets/bookmarks_quick_access_card.dart';

/// Main Hadith Library screen showing all collections
class HadithLibraryScreen extends StatelessWidget {
  const HadithLibraryScreen({super.key});

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
        )..loadCollections();
      },
      child: const _HadithLibraryView(),
    );
  }
}

class _HadithLibraryView extends StatefulWidget {
  const _HadithLibraryView();

  @override
  State<_HadithLibraryView> createState() => _HadithLibraryViewState();
}

class _HadithLibraryViewState extends State<_HadithLibraryView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        child: BlocBuilder<HadithLibraryCubit, HadithLibraryState>(
          builder: (context, state) {
            if (state is HadithLibraryLoading) {
              return const LoadingIndicator();
            } else if (state is HadithCollectionsLoaded) {
              return _buildMainContent(context, state, theme, size, l10n);
            } else if (state is HadithLibraryError) {
              return _buildError(context, state, theme, l10n);
            }

            return const LoadingIndicator();
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    HadithCollectionsLoaded state,
    ThemeData theme,
    Size size,
    AppLocalizations? l10n,
  ) {
    final filteredCollections = _getFilteredCollections(state.collections);
    final isDesktop = PlatformUtils.isDesktop;
    final horizontalPadding = isDesktop ? size.width * 0.04 : size.width * 0.04;
    final maxWidth = isDesktop ? 1400.0 : double.infinity;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // App Bar
        _buildAppBar(context, theme, size, l10n),

        // Bookmarks Quick Access
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: BookmarksQuickAccessCard(),
              ),
            ),
          ),
        ),

        // Collections Header
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: size.height * 0.015,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n?.translate('hadith_library.all_collections') ??
                          'All Collections',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Almarai',
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${filteredCollections.length}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Almarai',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Collections List/Grid
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: isDesktop
                  ? _buildCollectionsGrid(
                      context,
                      filteredCollections,
                      theme,
                      size,
                      horizontalPadding,
                    )
                  : _buildCollectionsList(
                      context,
                      filteredCollections,
                      theme,
                      size,
                      horizontalPadding,
                    ),
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: size.height * 0.03)),
      ],
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    Size size,
    AppLocalizations? l10n,
  ) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      expandedHeight: size.height * 0.15,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.height * 0.02,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.translate('hadith_library.title') ??
                              'Hadith Library',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Almarai',
                          ),
                        ),
                        Text(
                          l10n?.translate('hadith_library.subtitle') ??
                              '15 Authentic Collections',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BlocBuilder<HadithLibraryCubit, HadithLibraryState>(
                    builder: (context, state) {
                      return IconButton(
                        onPressed: () {
                          if (state is HadithCollectionsLoaded) {
                            _showSearchDialog(
                              context,
                              theme,
                              l10n,
                              state.collections,
                            );
                          }
                        },
                        icon: Icon(
                          Icons.search_rounded,
                          color: theme.primaryColor,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
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
              context.read<HadithLibraryCubit>().loadCollections();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n?.translate('hadith_library.retry') ?? 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCollectionCard(
    BuildContext context,
    dynamic collection,
    ThemeData theme,
    Size size,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CollectionBooksScreen(collection: collection),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and arrow
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.03,
                vertical: size.height * 0.01,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(collection.icon, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: size.width * 0.04),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arabic name
                      Text(
                        collection.nameArabic,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ScheherazadeNew',
                          fontSize: 22,
                          height: 1.4,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: size.height * 0.001),

                      // English name
                      Text(
                        collection.nameEnglish,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.6,
                          ),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(size.width * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      // Hadiths count
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${collection.totalHadiths}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Almarai',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: size.width * 0.02),

                      // Books count
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.library_books_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${collection.totalBooks}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Almarai',
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  List _getFilteredCollections(List collections) {
    if (_searchQuery.isEmpty) {
      return collections;
    }

    final query = _searchQuery.toLowerCase();
    return collections.where((collection) {
      return collection.nameArabic.toLowerCase().contains(query) ||
          collection.nameEnglish.toLowerCase().contains(query) ||
          collection.description.toLowerCase().contains(query);
    }).toList();
  }

  void _showSearchDialog(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
    List collections,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Search header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: theme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      l10n?.translate('hadith_library.search_collections') ??
                          'Search Collections',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    setModalState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: l10n?.translate('hadith_library.search_hint') ??
                        'Search by name or description...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: theme.primaryColor,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                              setModalState(() {});
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
                      borderSide: BorderSide(
                        color: theme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Results info
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${l10n?.translate('hadith_library.found') ?? 'Found'} ${_getFilteredCollections(collections).length} ${l10n?.translate('hadith_library.collections') ?? 'collections'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                      fontFamily: 'Almarai',
                    ),
                  ),
                ),

              const SizedBox(height: 8),
              const Divider(height: 1),

              // Filtered collections list
              Expanded(
                child: _searchQuery.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 64,
                              color: theme.disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n?.translate('hadith_library.search_hint') ??
                                  'Search by name or description...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.disabledColor,
                                fontFamily: 'Almarai',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _buildSearchResults(
                        collections,
                        theme,
                        MediaQuery.of(context).size,
                        l10n,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    List collections,
    ThemeData theme,
    Size size,
    AppLocalizations? l10n,
  ) {
    final filteredCollections = _getFilteredCollections(collections);

    if (filteredCollections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.translate('hadith_library.no_collections_found') ??
                  'No collections found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
                fontFamily: 'Almarai',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCollections.length,
      itemBuilder: (context, index) {
        final collection = filteredCollections[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              // Navigate to collection books screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CollectionBooksScreen(collection: collection),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: collection.color.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: collection.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(collection.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.nameArabic,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ScheherazadeNew',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          collection.nameEnglish,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: collection.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${collection.totalHadiths} ${l10n?.translate('hadith_library.hadiths') ?? 'hadiths'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: collection.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: collection.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: collection.color,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollectionsList(
    BuildContext context,
    List<dynamic> collections,
    ThemeData theme,
    Size size,
    double horizontalPadding,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: collections.map((collection) {
          return Padding(
            padding: EdgeInsets.only(bottom: size.height * 0.015),
            child: _buildModernCollectionCard(context, collection, theme, size),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCollectionsGrid(
    BuildContext context,
    List<dynamic> collections,
    ThemeData theme,
    Size size,
    double horizontalPadding,
  ) {
    final width = size.width;
    int crossAxisCount = 2;
    if (width >= 1400) {
      crossAxisCount = 4;
    } else if (width >= 900) {
      crossAxisCount = 3;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: size.width >= 1400
              ? 2.5
              : size.width >= 900
                  ? 2.4
                  : 2.3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: collections.length,
        itemBuilder: (context, index) {
          return _buildModernCollectionCard(
            context,
            collections[index],
            theme,
            size,
          );
        },
      ),
    );
  }
}
