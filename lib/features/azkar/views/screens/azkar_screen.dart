import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/data/models/azkar_category.dart';
import 'package:wadhakir/core/widgets/loading_indicator.dart';
import 'package:wadhakir/features/azkar/cubit/azkar_cubit.dart';
import 'package:wadhakir/features/azkar/cubit/azkar_state.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/repositories/azkar_repository_impl.dart';
import 'package:wadhakir/features/azkar/views/widgets/islamic_pattern_painter.dart';
import 'package:wadhakir/features/azkar/views/screens/azkar_category_details_screen.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // For featured item
  int _featuredIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();

    // Pick a random featured azkar
    _featuredIndex = Random().nextInt(4); // Assuming at least 4 categories

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
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

    return BlocProvider(
      create: (context) =>
          AzkarCubit(azkarRepository: AzkarRepositoryImpl())..loadCategories(),
      child: Scaffold(
        body: Stack(
          children: [
            // Islamic Pattern Background
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: IslamicPatternPainter(
                    color: theme.primaryColor,
                    gridSize: 60,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: BlocBuilder<AzkarCubit, AzkarState>(
                builder: (context, state) {
                  if (state is AzkarLoading) {
                    return const LoadingIndicator();
                  } else if (state is AzkarCategoriesLoaded) {
                    return _buildMainContent(context, state);
                  } else if (state is AzkarError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return Center(
                    child: Text(context.l10n?.translate('azkar.no_data_available') ??
                        'No data available'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, AzkarCategoriesLoaded state) {
    final filteredCategories = _searchQuery.isEmpty
        ? state.categories
        : state.categories
            .where((c) =>
                c.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Custom App Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Header
                Text(
                  context.l10n?.translate('azkar.azkar') ?? 'أذكار',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Almarai',
                  ),
                ),
                Text(
                  context.l10n?.translate('azkar.daily_remembrance') ??
                      'أذكار المسلم اليومية',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).hintColor,
                  ),
                ),

                const SizedBox(height: 20),

                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: context.l10n?.translate('azkar.search_azkar') ??
                        'البحث في الأذكار...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Featured Azkar Section
        if (_searchQuery.isEmpty && state.categories.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildFeaturedAzkar(context, state),
          ),

        // Categories Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                Text(
                  context.l10n?.translate('azkar.categories') ?? 'الفئات',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Almarai',
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredCategories.length} ${context.l10n?.translate('azkar.categorie') ?? 'فئة'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Categories Grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Staggered animation for items
                final itemAnimation =
                    Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index / filteredCategories.length) * 0.7,
                      min(1.0, (index / filteredCategories.length) * 0.7 + 0.3),
                      curve: Curves.easeOut,
                    ),
                  ),
                );

                final category = filteredCategories[index];
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
                        child: _buildCategoryCard(context, category, index),
                      ),
                    );
                  },
                );
              },
              childCount: filteredCategories.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedAzkar(
      BuildContext context, AzkarCategoriesLoaded state) {
    if (state.categories.isEmpty) return const SizedBox.shrink();

    final featuredCategory =
        state.categories[_featuredIndex % state.categories.length];
    final cardData = _getCardData(featuredCategory.title, _featuredIndex);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n?.translate('azkar.featured') ?? 'مختارات',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Almarai',
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AzkarCategoryDetailsScreen(category: featuredCategory),
                ),
              );
            },
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cardData.color,
                    cardData.color.withValues(alpha: 0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: cardData.color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Decorative elements
                    Positioned(
                      right: -30,
                      bottom: -30,
                      child: Icon(
                        cardData.icon,
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  cardData.icon,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            featuredCategory.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Almarai',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${featuredCategory.items.length} ${context.l10n?.translate('azkar.item')}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, AzkarCategory category, int index) {
    final cardData = _getCardData(category.title, index);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AzkarCategoryDetailsScreen(category: category),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: cardData.color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: _IslamicPatternPainter(
                    color: cardData.color,
                  ),
                  size: const Size(double.infinity, double.infinity),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardData.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      cardData.icon,
                      size: 26,
                      color: cardData.color,
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        category.title,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Item count
                      Text(
                        '${category.items.length} ${context.l10n?.translate('azkar.items') ?? 'أذكار'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
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

  // Get card data (color and icon) based on category title or index
  CardData _getCardData(String title, int index) {
    // Match categories to specific colors and icons
    if (title.contains('الصباح')) {
      return CardData(morningAzkarColor, Icons.wb_sunny_rounded);
    } else if (title.contains('المساء')) {
      return CardData(eveningAzkarColor, Icons.nights_stay_rounded);
    } else if (title.contains('النوم')) {
      return CardData(sleepAzkarColor, Icons.bedtime_rounded);
    } else if (title.contains('الاستيقاظ')) {
      return CardData(wakeupAzkarColor, Icons.light_mode_rounded);
    } else if (title.contains('المسجد') || title.contains('الصلاة')) {
      return CardData(mosqueAzkarColor, Icons.mosque_rounded);
    } else if (title.contains('أدعية')) {
      return CardData(maathurDuaColor, Icons.auto_awesome_rounded);
    } else if (title.contains('قرآنية')) {
      return CardData(quranDuaColor, Icons.menu_book_rounded);
    } else {
      // For other categories, use a color based on index
      final colors = [
        morningAzkarColor,
        eveningAzkarColor,
        sleepAzkarColor,
        prayerAzkarColor,
        wakeupAzkarColor,
        mosqueAzkarColor,
        maathurDuaColor,
        quranDuaColor,
      ];

      final icons = [
        Icons.wb_sunny_rounded,
        Icons.nights_stay_rounded,
        Icons.bedtime_rounded,
        Icons.person_rounded,
        Icons.water_drop_rounded,
        Icons.favorite_rounded,
        Icons.auto_awesome_rounded,
        Icons.menu_book_rounded,
      ];

      final colorIndex = index % colors.length;
      return CardData(colors[colorIndex], icons[colorIndex]);
    }
  }
}

// Helper class for card data
class CardData {
  final Color color;
  final IconData icon;

  CardData(this.color, this.icon);
}

// Custom painter for Islamic pattern
class _IslamicPatternPainter extends CustomPainter {
  final Color color;

  _IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw a simple Islamic geometric pattern
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = min(size.width, size.height) * 0.4;

    // Draw octagon
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Draw inner star
    final innerPath = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4 + pi / 8;
      final x = centerX + radius * 0.6 * cos(angle);
      final y = centerY + radius * 0.6 * sin(angle);

      if (i == 0) {
        innerPath.moveTo(x, y);
      } else {
        innerPath.lineTo(x, y);
      }
    }
    innerPath.close();
    canvas.drawPath(innerPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
