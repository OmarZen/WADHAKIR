import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/models/surah_model.dart';
import 'package:wadhakir/features/quran/cubit/quran_cubit.dart';
import 'package:wadhakir/features/quran/cubit/quran_state.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/quran/views/screens/surah_detail_screen.dart';
import 'package:wadhakir/features/azkar/views/widgets/islamic_pattern_painter.dart';

// Color scheme for Quran screen
const Color quranBaseColor =
    Color(0xFF20497D); // Primary blue (matches app theme)
const Color quranPrimaryColor = Color(0xFF3B82F6); // Secondary bright blue
const Color quranMeccanColor = Color(0xFF3498DB); // Blue for Meccan surahs
const Color quranMadinanColor = Color(0xFF27AE60); // Green for Medinan surahs
const Color quranAccentColor = Color(0xFFDAA520); // Gold for accents

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  List<SurahModel> _allSurahs = [];
  List<SurahModel> _filteredSurahs = [];
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    // Initial load of all surahs
    _loadAllSurahs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadAllSurahs() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
      context.read<QuranCubit>().loadSurahs();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterSurahs();
    });
  }

  void _filterSurahs() {
    if (_allSurahs.isEmpty) return;

    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredSurahs = List.from(_allSurahs);
      });
      return;
    }

    setState(() {
      _filteredSurahs = _allSurahs.where((surah) {
        final String placeTranslated = surah.placeOfRevelation.toLowerCase() ==
                'meccan'
            ? (context.l10n?.translate('quran.meccan') ?? 'مكية').toLowerCase()
            : (context.l10n?.translate('quran.medinan') ?? 'مدنية')
                .toLowerCase();

        return surah.nameEnglish.toLowerCase().contains(_searchQuery) ||
            surah.nameTransliteration.toLowerCase().contains(_searchQuery) ||
            surah.nameArabic.contains(_searchQuery) ||
            surah.number.toString().contains(_searchQuery) ||
            surah.placeOfRevelation.toLowerCase().contains(_searchQuery) ||
            placeTranslated.contains(_searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Islamic pattern background
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: quranBaseColor,
                  gridSize: 60,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(theme, l10n),

                // Content
                Expanded(
                  child: BlocConsumer<QuranCubit, QuranState>(
                    listener: (context, state) {
                      if (state is SurahsLoaded) {
                        setState(() {
                          _allSurahs = state.surahs.map((surah) {
                            // Ensure place of revelation is valid
                            if (!_isValidPlaceOfRevelation(
                                surah.placeOfRevelation)) {
                              // Log warning for debugging
                              debugPrint(
                                  'Invalid place of revelation for surah ${surah.number}: ${surah.placeOfRevelation}');

                              // Create a new surah model with corrected place of revelation
                              // Default to Meccan if invalid (could also be based on common knowledge)
                              return SurahModel(
                                number: surah.number,
                                nameArabic: surah.nameArabic,
                                nameEnglish: surah.nameEnglish,
                                nameTransliteration: surah.nameTransliteration,
                                placeOfRevelation: 'Meccan', // Default fallback
                                versesCount: surah.versesCount,
                              );
                            }
                            return surah;
                          }).toList();

                          _filterSurahs();
                          _isLoading = false;
                        });
                      }
                    },
                    builder: (context, state) {
                      if (state is QuranInitial) {
                        return _buildLoadingIndicator(theme);
                      } else if (state is QuranLoading && _allSurahs.isEmpty) {
                        return _buildLoadingIndicator(theme);
                      } else if (state is QuranError && _allSurahs.isEmpty) {
                        return _buildErrorState(state, theme, l10n);
                      } else {
                        return _buildSurahList(theme, l10n);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: theme.primaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n?.translate('quran.loading') ?? 'جاري تحميل القرآن...',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      QuranError state, ThemeData theme, AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 70,
              color: theme.colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAllSurahs,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              label: Text(l10n?.translate('quran.try_again') ?? 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with decorative elements
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.translate('quran.title') ?? 'القرآن الكريم',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    Text(
                      l10n?.translate('quran.subtitle') ?? 'اقرأ كلام الله',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Decorative icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 30,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Search bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    l10n?.translate('quran.search_surah') ?? 'البحث عن سورة...',
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.primaryColor,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(ThemeData theme, AppLocalizations? l10n) {
    if (_isLoading) {
      return _buildLoadingIndicator(theme);
    }

    if (_filteredSurahs.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 70,
              color: theme.hintColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.translate('quran.no_search_results') ??
                  'لا توجد نتائج للبحث',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                l10n?.translate('quran.try_different_search') ??
                    'حاول البحث بكلمات مختلفة',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        _loadAllSurahs();
        return Future.value();
      },
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _filteredSurahs.length,
        itemBuilder: (context, index) {
          final surah = _filteredSurahs[index];

          // Create staggered animation for each item
          final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                (index / (_filteredSurahs.length)) * 0.6,
                min(1.0, (index / (_filteredSurahs.length)) * 0.6 + 0.4),
                curve: Curves.easeOut,
              ),
            ),
          );

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  (1 - itemAnimation.value) * 50,
                ),
                child: Opacity(
                  opacity: itemAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSurahCard(context, surah, index),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSurahCard(BuildContext context, SurahModel surah, int index) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final size = MediaQuery.of(context).size;

    // Get color based on revelation type
    final Color cardColor = surah.placeOfRevelation == 'Meccan'
        ? quranMeccanColor // Blue for Meccan surahs
        : quranMadinanColor; // Green for Medinan surahs

    return InkWell(
      onTap: () => _navigateToSurahDetail(surah.number),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: cardColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Decorative surah number
            Positioned(
              right: -10,
              top: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.04,
                child: Text(
                  surah.number.toString(),
                  style: TextStyle(
                    fontSize: size.width * 0.1,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                ),
              ),
            ),

            // Islamic pattern decoration for the card
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Opacity(
                  opacity: 0.1,
                  child: CustomPaint(
                    painter: IslamicPatternPainter(
                      color: cardColor,
                      gridSize: 30, // Smaller grid for the card
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.04,
                vertical: size.height * 0.02,
              ),
              child: Row(
                children: [
                  // Surah number in a decorative circle
                  Container(
                    width: size.width * 0.15,
                    height: size.width * 0.15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cardColor.withValues(alpha: 0.2),
                          cardColor.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: cardColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        surah.number.toString(),
                        style: TextStyle(
                          fontSize: size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: cardColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.05),

                  // Surah information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surah.nameEnglish,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: size.width * 0.05,
                          ),
                        ),
                        SizedBox(height: size.height * 0.01),
                        Row(
                          children: [
                            Icon(
                              Icons.format_list_numbered,
                              size: size.width * 0.04,
                              color: theme.hintColor,
                            ),
                            SizedBox(width: size.width * 0.01),
                            Text(
                              '${surah.versesCount} ${l10n?.translate('quran.ayahs') ?? 'آية'}',
                              style: TextStyle(
                                fontSize: size.width * 0.04,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.001),
                        Text(
                          surah.nameTransliteration,
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            fontStyle: FontStyle.italic,
                            color: theme.hintColor,
                          ),
                        ),
                        SizedBox(width: size.height * 0.05),
                        _buildSurahTag(
                            theme,
                            surah.placeOfRevelation == 'Meccan'
                                ? l10n?.translate('quran.meccan') ?? 'مكية'
                                : l10n?.translate('quran.medinan') ?? 'مدنية',
                            cardColor),
                      ],
                    ),
                  ),

                  // Surah name in Arabic
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      surah.nameArabic,
                      style: TextStyle(
                        fontSize: size.width * 0.07,
                        fontFamily: 'ScheherazadeNew',
                        color: cardColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahTag(ThemeData theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _navigateToSurahDetail(int surahNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurahDetailScreen(surahNumber: surahNumber),
      ),
    ).then((_) {
      // Ensure animations play again when returning
      _animationController.reset();
      _animationController.forward();
    });
  }

  // Verify whether the place of revelation data is correct for the surah
  bool _isValidPlaceOfRevelation(String place) {
    return place == 'Meccan' || place == 'Medinan';
  }
}
