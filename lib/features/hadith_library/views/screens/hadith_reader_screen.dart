import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/models/hadith_model.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/domain/usecases/add_bookmark_usecase.dart';
import 'package:wadhakir/data/models/hadith_collection_metadata.dart';
import 'package:wadhakir/domain/usecases/remove_bookmark_usecase.dart';
import 'package:wadhakir/domain/usecases/get_all_bookmarks_usecase.dart';
import 'package:wadhakir/data/repositories/bookmark_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_all_collections_usecase.dart';
import 'package:wadhakir/features/hadith_library/cubit/bookmark_cubit.dart';
import 'package:wadhakir/features/hadith_library/cubit/bookmark_state.dart';

/// Immersive full-screen reader for hadith
class HadithReaderScreen extends StatelessWidget {
  final HadithModel hadith;
  final HadithCollectionMetadata collection;

  const HadithReaderScreen({
    super.key,
    required this.hadith,
    required this.collection,
  });

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
      child: _HadithReaderView(hadith: hadith, collection: collection),
    );
  }
}

class _HadithReaderView extends StatefulWidget {
  final HadithModel hadith;
  final HadithCollectionMetadata collection;

  const _HadithReaderView({required this.hadith, required this.collection});

  @override
  State<_HadithReaderView> createState() => _HadithReaderViewState();
}

class _HadithReaderViewState extends State<_HadithReaderView> {
  bool _showTranslation = true;
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    // Set status bar icon brightness for immersive experience
    // Note: statusBarColor is deprecated in Android 15 for edge-to-edge apps
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
    );
  }

  @override
  void dispose() {
    // Restore status bar icon brightness
    // Note: statusBarColor is deprecated in Android 15 for edge-to-edge apps
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.collection.color.withValues(alpha: 0.3),
                  Colors.black,
                  Colors.black,
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(context, theme, size),

                // Scrollable Content
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: PlatformUtils.isDesktop
                            ? 900.0
                            : double.infinity,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(
                          PlatformUtils.isDesktop ? 32.0 : size.width * 0.06,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: size.height * 0.02),

                            // Collection & Number Badge
                            _buildHeaderBadge(theme, size),

                            SizedBox(height: size.height * 0.04),

                            // Arabic Text
                            _buildArabicText(theme, size),

                            if (_showTranslation &&
                                (widget.hadith.hadithTextEnglish?.isNotEmpty ??
                                    false)) ...[
                              SizedBox(height: size.height * 0.04),
                              _buildTranslation(theme, size, l10n),
                            ],

                            if (widget.hadith.narrator?.isNotEmpty ??
                                false) ...[
                              SizedBox(height: size.height * 0.03),
                              _buildNarrator(theme, size),
                            ],

                            SizedBox(height: size.height * 0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Actions
                _buildBottomActions(context, theme, size, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ThemeData theme, Size size) {
    return Padding(
      padding: EdgeInsets.all(size.width * 0.04),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),

          const Spacer(),

          // Font Size Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_fontSize > 14) {
                      setState(() => _fontSize -= 2);
                    }
                  },
                  icon: const Icon(
                    Icons.text_decrease_rounded,
                    color: Colors.white,
                  ),
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {
                    if (_fontSize < 28) {
                      setState(() => _fontSize += 2);
                    }
                  },
                  icon: const Icon(
                    Icons.text_increase_rounded,
                    color: Colors.white,
                  ),
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Translation Toggle
          IconButton(
            onPressed: () {
              setState(() => _showTranslation = !_showTranslation);
            },
            icon: Icon(
              _showTranslation
                  ? Icons.translate_rounded
                  : Icons.g_translate_rounded,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(ThemeData theme, Size size) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.012,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.collection.color.withValues(alpha: 0.3),
              widget.collection.color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.collection.color.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.collection.icon, color: Colors.white, size: 16),
            SizedBox(width: size.width * 0.02),
            Text(
              '${widget.collection.nameArabic} • #${widget.hadith.ourHadithNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Almarai',
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArabicText(ThemeData theme, Size size) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Text(
        widget.hadith.hadithTextArabic,
        style: TextStyle(
          fontFamily: 'ScheherazadeNew',
          fontSize: _fontSize + 4,
          height: 2.0,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTranslation(ThemeData theme, Size size, AppLocalizations? l10n) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.translate_rounded,
                color: widget.collection.color.withValues(alpha: 0.7),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.translate('hadith_library.translation') ?? 'Translation',
                style: TextStyle(
                  color: widget.collection.color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'Almarai',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.hadith.hadithTextEnglish ?? '',
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.8,
              color: Colors.white.withValues(alpha: 0.85),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildNarrator(ThemeData theme, Size size) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: widget.collection.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.collection.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline_rounded,
            color: Colors.white.withValues(alpha: 0.9),
            size: 20,
          ),
          SizedBox(width: size.width * 0.02),
          Expanded(
            child: Text(
              widget.hadith.narrator ?? '',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
                fontSize: 14,
                fontFamily: 'Almarai',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    ThemeData theme,
    Size size,
    AppLocalizations? l10n,
  ) {
    return BlocBuilder<BookmarkCubit, BookmarkState>(
      builder: (context, state) {
        bool isBookmarked = false;

        if (state is BookmarksLoaded) {
          isBookmarked = state.bookmarks.any(
            (b) => b.hadithId == widget.hadith.id,
          );
        }

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.height * 0.02,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Bookmark Button
              _buildActionButton(
                context,
                icon: isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                label: l10n?.translate('hadith_library.bookmark') ?? 'Bookmark',
                onTap: () => _handleBookmark(context, isBookmarked),
                color: isBookmarked ? widget.collection.color : Colors.white,
              ),

              // Copy Button
              _buildActionButton(
                context,
                icon: Icons.copy_rounded,
                label: l10n?.translate('hadith_library.copy') ?? 'Copy',
                onTap: () => _handleCopy(context),
                color: Colors.white,
              ),

              // Share Button
              _buildActionButton(
                context,
                icon: Icons.share_rounded,
                label: l10n?.translate('hadith_library.share') ?? 'Share',
                onTap: () => _handleShare(),
                color: Colors.white,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBookmark(BuildContext context, bool isBookmarked) {
    final l10n = AppLocalizations.of(context);
    if (isBookmarked) {
      // Remove bookmark
      context.read<BookmarkCubit>().removeBookmark(widget.hadith.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.translate('hadith_library.bookmark_removed') ??
                'Bookmark removed',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Add bookmark
      context.read<BookmarkCubit>().addBookmark(hadithId: widget.hadith.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.translate('hadith_library.bookmark_added') ??
                'Bookmark added',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleCopy(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text =
        '''
${widget.hadith.hadithTextArabic}

${(widget.hadith.hadithTextEnglish?.isNotEmpty ?? false) ? widget.hadith.hadithTextEnglish! : ''}

${(widget.hadith.narrator?.isNotEmpty ?? false) ? 'الراوي: ${widget.hadith.narrator}' : ''}

${widget.collection.nameArabic} • الحديث رقم ${widget.hadith.ourHadithNumber}
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.translate('hadith_library.copied_to_clipboard') ??
              'Copied to clipboard',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleShare() {
    final text =
        '''
${widget.hadith.hadithTextArabic}

${(widget.hadith.hadithTextEnglish?.isNotEmpty ?? false) ? widget.hadith.hadithTextEnglish! : ''}

${(widget.hadith.narrator?.isNotEmpty ?? false) ? 'الراوي: ${widget.hadith.narrator}' : ''}

${widget.collection.nameArabic} • الحديث رقم ${widget.hadith.ourHadithNumber}
''';

    SharePlus.instance.share(
      ShareParams(text: text, subject: widget.collection.nameArabic),
    );
  }
}
