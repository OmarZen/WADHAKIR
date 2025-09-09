import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/verse_model.dart';
import 'package:wadhakir/data/models/surah_model.dart';
import 'package:wadhakir/features/quran/cubit/quran_cubit.dart';
import 'package:wadhakir/features/quran/cubit/quran_state.dart';
import 'package:wadhakir/features/quran/views/widgets/verse_item.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';

// Color scheme for Quran details
const Color quranMeccanColor = Color(0xFF3498DB); // Blue for Meccan surahs
const Color quranMadinanColor = Color(0xFF27AE60); // Green for Medinan surahs

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;

  const SurahDetailScreen({super.key, required this.surahNumber});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  static const int _pageSize = 10;

  final Set<int> _bookmarkedVerses = <int>{};
  final ScrollController _scrollController = ScrollController();
  bool _showTranslation = true;

  // Pagination state
  List<VerseModel> _allVerses = [];
  List<VerseModel> _displayedVerses = [];
  bool _isLoading = false;
  int _currentPage = 0;
  bool _hasMoreItems = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    context.read<QuranCubit>().loadSurahDetails(widget.surahNumber);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMoreItems) {
      _loadMoreVerses();
    }
  }

  void _resetPagination() {
    _currentPage = 0;
    _displayedVerses = [];
    _hasMoreItems = true;
    _loadMoreVerses();
  }

  void _loadMoreVerses() {
    if (_isLoading || !_hasMoreItems) return;

    setState(() {
      _isLoading = true;
    });

    final state = context.read<QuranCubit>().state;
    if (state is SurahDetailsLoaded) {
      if (_allVerses.isEmpty) {
        _allVerses = state.verses;
      }

      final startIndex = _currentPage * _pageSize;
      if (startIndex >= _allVerses.length) {
        setState(() {
          _hasMoreItems = false;
          _isLoading = false;
        });
        return;
      }

      final endIndex = (startIndex + _pageSize < _allVerses.length)
          ? startIndex + _pageSize
          : _allVerses.length;

      final newItems = _allVerses.sublist(startIndex, endIndex);

      setState(() {
        _displayedVerses.addAll(newItems);
        _currentPage++;
        _hasMoreItems = endIndex < _allVerses.length;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<QuranCubit, QuranState>(
          builder: (context, state) {
            if (state is SurahDetailsLoaded) {
              return Text(
                state.surah.nameEnglish,
                style: const TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            return Text(
              l10n?.translate('surah') ?? 'Surah',
              style: const TextStyle(
                fontFamily: 'Almarai',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
                _showTranslation ? Icons.translate : Icons.translate_outlined),
            onPressed: () {
              setState(() {
                _showTranslation = !_showTranslation;
              });
            },
            tooltip: _showTranslation
                ? l10n?.translate('hide_translation') ?? 'Hide Translation'
                : l10n?.translate('show_translation') ?? 'Show Translation',
          ),
        ],
      ),
      body: BlocConsumer<QuranCubit, QuranState>(
        listener: (context, state) {
          if (state is SurahDetailsLoaded) {
            _resetPagination();
          }
        },
        builder: (context, state) {
          if (state is QuranLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SurahDetailsLoaded) {
            return _buildSurahDetails(state);
          } else if (state is QuranError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<QuranCubit>()
                        .loadSurahDetails(widget.surahNumber),
                    child: Text(l10n?.translate('try_again') ?? 'Try Again'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSurahDetails(SurahDetailsLoaded state) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        double fontSize = 1.0;
        if (settingsState is SettingsLoaded) {
          fontSize = settingsState.settings.fontSize;
        }

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Surah header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSurahHeader(state),
              ),
            ),

            // Basmala if needed
            if (state.showBasmala)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    state.basmala,
                    style: TextStyle(
                      fontSize: 26 * fontSize,
                      fontFamily: 'ScheherazadeNew',
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),

            // Verses list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _displayedVerses.length) {
                    if (_hasMoreItems) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }

                  final verse = _displayedVerses[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: VerseItem(
                      verse: verse,
                      fontSize: fontSize,
                      showTranslation: _showTranslation,
                      isBookmarked: _bookmarkedVerses.contains(verse.number),
                      onBookmarkPressed: _handleBookmarkPressed,
                      onSharePressed: _handleSharePressed,
                      onCopyPressed: _handleCopyPressed,
                    ),
                  );
                },
                childCount: _displayedVerses.length + (_hasMoreItems ? 1 : 0),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSurahHeader(SurahDetailsLoaded state) {
    return _buildSurahInfo(context, state.surah);
  }

  void _handleBookmarkPressed(VerseModel verse) {
    final l10n = context.l10n;
    setState(() {
      if (_bookmarkedVerses.contains(verse.number)) {
        _bookmarkedVerses.remove(verse.number);
      } else {
        _bookmarkedVerses.add(verse.number);
      }
    });

    // Show snackbar
    final message = _bookmarkedVerses.contains(verse.number)
        ? '${l10n?.translate('verse') ?? 'Verse'} ${verse.number} ${l10n?.translate('bookmarked') ?? 'bookmarked'}'
        : '${l10n?.translate('bookmark') ?? 'Bookmark'} ${l10n?.translate('removed') ?? 'removed'}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );

    // TODO: Implement bookmark storage in repository
  }

  void _handleSharePressed(VerseModel verse) async {
    final l10n = context.l10n;
    final text =
        '${l10n?.translate('surah') ?? 'Surah'} ${widget.surahNumber}, ${l10n?.translate('verse') ?? 'Verse'} ${verse.number}:\n\n${verse.text}\n\n${verse.translation}';

    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.translate('verse_shared') ?? 'Verse shared'),
        duration: const Duration(seconds: 1),
      ),
    );

    Share.share(text, subject: 'Share Verse ${verse.number}');
  }

  Future<void> _handleCopyPressed(VerseModel verse) async {
    final l10n = context.l10n;
    final text =
        '${l10n?.translate('surah') ?? 'Surah'} ${widget.surahNumber}, ${l10n?.translate('verse') ?? 'Verse'} ${verse.number}:\n\n${verse.text}\n\n${verse.translation}';
    await Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.translate('verse_copied_to_clipboard') ??
            'Verse copied to clipboard'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildSurahInfo(BuildContext context, SurahModel surah) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // Determine color based on place of revelation
    final Color placeColor = surah.placeOfRevelation == 'Meccan'
        ? quranMeccanColor // Blue for Meccan surahs
        : quranMadinanColor; // Green for Medinan surahs

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: placeColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: placeColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            surah.nameArabic,
            style: const TextStyle(
              fontSize: 32,
              fontFamily: 'ScheherazadeNew',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            surah.nameEnglish,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            surah.nameTransliteration,
            style: TextStyle(
              fontSize: 16,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(
                icon: Icons.format_list_numbered,
                label:
                    '${surah.versesCount} ${l10n?.translate('ayahs') ?? 'آية'}',
                theme: theme,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.location_on,
                label: surah.placeOfRevelation == 'Meccan'
                    ? l10n?.translate('meccan') ?? 'مكية'
                    : l10n?.translate('medinan') ?? 'مدنية',
                theme: theme,
                color: placeColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
