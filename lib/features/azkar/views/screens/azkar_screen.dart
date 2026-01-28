import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();

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
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: BlocBuilder<AzkarCubit, AzkarState>(
            builder: (context, state) {
              if (state is AzkarLoading) {
                return const LoadingIndicator();
              } else if (state is AzkarCategoriesLoaded) {
                return _buildMainContent(context, state, theme);
              } else if (state is AzkarError) {
                return Center(
                  child: Text(
                    state.message,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              }
              return Center(
                child: Text(
                  context.l10n?.translate('azkar.no_data_available') ??
                      'No data available',
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    AzkarCategoriesLoaded state,
    ThemeData theme,
  ) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final filteredCategories = _searchQuery.isEmpty
        ? state.categories
        : state.categories
            .where(
              (c) =>
                  c
                      .getLocalizedTitle(languageCode)
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  c.title.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

    return Stack(
      children: [
        // Islamic pattern background
        Positioned.fill(
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(
              painter: IslamicPatternPainter(
                color: theme.colorScheme.primary,
                gridSize: 80,
              ),
            ),
          ),
        ),

        Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n?.translate('azkar.azkar') ?? 'أذكار',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          context.l10n?.translate('azkar.daily_remembrance') ??
                              'أذكار المسلم اليومية',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: context.l10n?.translate('azkar.search_azkar') ??
                      'البحث في الأذكار...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.primary,
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // Categories count
            if (filteredCategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      context.l10n?.translate('azkar.categories') ?? 'الفئات',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filteredCategories.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Categories list with animation
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  return _AnimatedCategoryCard(
                    category: filteredCategories[index],
                    index: index,
                    animation: _animationController,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnimatedCategoryCard extends StatefulWidget {
  final AzkarCategory category;
  final int index;
  final Animation<double> animation;

  const _AnimatedCategoryCard({
    required this.category,
    required this.index,
    required this.animation,
  });

  @override
  State<_AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

class _AnimatedCategoryCardState extends State<_AnimatedCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon() {
    final title = widget.category.title;
    final titleEn = widget.category.titleEn;
    if (title.contains('الصباح') || titleEn.contains('Morning')) {
      return Icons.wb_sunny_outlined;
    }
    if (title.contains('المساء') || titleEn.contains('Evening')) {
      return Icons.nights_stay_outlined;
    }
    if (title.contains('النوم') || titleEn.contains('Sleep')) {
      return Icons.bedtime_outlined;
    }
    if (title.contains('الاستيقاظ') || titleEn.contains('Waking')) {
      return Icons.light_mode_outlined;
    }
    if (title.contains('المسجد') ||
        title.contains('الصلاة') ||
        titleEn.contains('Mosque') ||
        titleEn.contains('Prayer')) {
      return Icons.mosque_outlined;
    }
    if (title.contains('أدعية') || titleEn.contains('Dua')) {
      return Icons.auto_awesome_outlined;
    }
    if (title.contains('قرآنية')) return Icons.menu_book_outlined;
    return Icons.auto_awesome_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animation,
        curve: Interval(
          (widget.index * 0.1).clamp(0.0, 1.0),
          ((widget.index * 0.1) + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: itemAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(itemAnimation),
            child: child,
          ),
        );
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: (_) => _scaleController.forward(),
          onTapUp: (_) {
            _scaleController.reverse();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AzkarCategoryDetailsScreen(category: widget.category),
              ),
            );
          },
          onTapCancel: () => _scaleController.reverse(),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(),
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                // Title and count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.getLocalizedTitle(
                          Localizations.localeOf(context).languageCode,
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.category.items.length} ${context.l10n?.translate('azkar.items') ?? 'أذكار'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
