import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/models/azkar_item.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/data/models/azkar_category.dart';
import 'package:wadhakir/features/azkar/cubit/azkar_cubit.dart';
import 'package:wadhakir/features/azkar/cubit/azkar_state.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/repositories/azkar_repository_impl.dart';
import 'package:wadhakir/features/azkar/views/widgets/islamic_pattern_painter.dart';

class AzkarCategoryDetailsScreen extends StatefulWidget {
  final AzkarCategory category;

  const AzkarCategoryDetailsScreen({
    super.key,
    required this.category,
  });

  @override
  State<AzkarCategoryDetailsScreen> createState() =>
      _AzkarCategoryDetailsScreenState();
}

class _AzkarCategoryDetailsScreenState extends State<AzkarCategoryDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _repeatCount = 0;
  bool _autoAdvance = true;

  // Get the appropriate color based on category title
  Color get _categoryColor {
    final title = widget.category.title;
    if (title.contains('الصباح')) {
      return morningAzkarColor;
    } else if (title.contains('المساء')) {
      return eveningAzkarColor;
    } else if (title.contains('النوم')) {
      return sleepAzkarColor;
    } else if (title.contains('الاستيقاظ')) {
      return wakeupAzkarColor;
    } else if (title.contains('المسجد') || title.contains('الصلاة')) {
      return mosqueAzkarColor;
    } else if (title.contains('أدعية')) {
      return maathurDuaColor;
    } else if (title.contains('قرآنية')) {
      return quranDuaColor;
    } else {
      return prayerAzkarColor;
    }
  }

  // Get the appropriate icon based on category title
  IconData get _categoryIcon {
    final title = widget.category.title;
    if (title.contains('الصباح')) {
      return Icons.wb_sunny_outlined;
    } else if (title.contains('المساء')) {
      return Icons.nights_stay_outlined;
    } else if (title.contains('النوم')) {
      return Icons.bedtime_outlined;
    } else if (title.contains('الاستيقاظ')) {
      return Icons.light_mode_outlined;
    } else if (title.contains('المسجد') || title.contains('الصلاة')) {
      return Icons.mosque_outlined;
    } else if (title.contains('أدعية')) {
      return Icons.auto_awesome_outlined;
    } else if (title.contains('قرآنية')) {
      return Icons.menu_book_outlined;
    } else if (title.contains('اليومية')) {
      return Icons.calendar_month_outlined;
    } else if (title.contains('المغفرة') || title.contains('دعاء')) {
      return Icons.front_hand;
    } else {
      return Icons.auto_awesome_outlined;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();

    _pageController.addListener(() {
      int page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
          _repeatCount = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _incrementCounter(AdhkarItem item) {
    // For items with 0 or 1 repetition, just count once and move to the next
    final maxCount = item.count <= 1 ? 1 : item.count;

    if (_repeatCount < maxCount - 1) {
      setState(() {
        _repeatCount++;
        // Provide haptic feedback
        HapticFeedback.mediumImpact();
      });

      // If repetition is 1 or 0, automatically move to the next page
      if (maxCount == 1 && _repeatCount == maxCount - 1) {
        // Small delay to show the counter at 1 before moving
        Future.delayed(const Duration(milliseconds: 300), () {
          _moveToNextPage();
        });
      }
    } else {
      // Repetitions completed, but don't reset counter to 0
      // Instead, keep it at the max count to show completion
      setState(() {
        _repeatCount = maxCount; // Keep at max instead of resetting to 0
      });

      // Provide success feedback
      HapticFeedback.heavyImpact();

      // If auto advance is enabled, move to next
      if (_autoAdvance) {
        _moveToNextPage();
      }
    }
  }

  void _moveToNextPage() {
    // Auto-navigate to next item if not at the end
    if (_currentPage < widget.category.items.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // Show completion message when reaching the end
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n?.translate('azkar.completed_all_azkar') ??
                'You have completed all azkar in this category',
          ),
          backgroundColor: _categoryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AzkarCubit(
        azkarRepository: AzkarRepositoryImpl(),
      )..selectCategory(widget.category),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(widget.category.title),
          centerTitle: true,
          elevation: 0,
          backgroundColor: _categoryColor,
          leading: IconButton(
            icon: Icon(_categoryIcon, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<AzkarCubit, AzkarState>(
      builder: (context, state) {
        if (state is AzkarCategorySelected) {
          return _buildCategoryContent(context, state);
        }
        return Center(
          child: CircularProgressIndicator(
            color: _categoryColor,
          ),
        );
      },
    );
  }

  Widget _buildCategoryContent(
      BuildContext context, AzkarCategorySelected state) {
    if (state.category.items.isEmpty) {
      return Center(
          child: Text(
              context.l10n?.translate('azkar.no_azkar_in_this_category') ??
                  'No Azkar in this category'));
    }

    return Stack(
      children: [
        // Background pattern
        Positioned.fill(
          child: Opacity(
            opacity: 0.2,
            child: CustomPaint(
              painter: IslamicPatternPainter(
                color: _categoryColor,
                gridSize: 60,
              ),
            ),
          ),
        ),

        Column(
          children: [
            const SizedBox(height: kToolbarHeight + 50),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${_currentPage + 1}/${state.category.items.length}',
                        style: TextStyle(
                          color: _categoryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: ((_currentPage + 1) /
                                state.category.items.length),
                            backgroundColor:
                                _categoryColor.withValues(alpha: 0.1),
                            color: _categoryColor,
                            minHeight: 10,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Auto-advance toggle
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n?.translate('azkar.auto_move') ?? 'Auto move',
                          style: TextStyle(
                            fontSize: 14,
                            color: _categoryColor,
                          ),
                        ),
                        Switch(
                          value: _autoAdvance,
                          onChanged: (value) {
                            setState(() {
                              _autoAdvance = value;
                            });
                          },
                          activeThumbColor: _categoryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // PageView for Azkar items
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: state.category.items.length,
                itemBuilder: (context, index) {
                  final item = state.category.items[index];
                  return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.0, 0.5,
                                  curve: Curves.easeOut),
                            ),
                          ),
                          child: _buildAdhkarPage(context, item, index),
                        );
                      });
                },
              ),
            ),

            // Bottom actions and counter
            _buildBottomPanel(context, state),
          ],
        ),
      ],
    );
  }

  Widget _buildAdhkarPage(BuildContext context, AdhkarItem item, int index) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Bismillah at the top
          if (index == 0 || item.text.contains('بسم الله'))
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    context.l10n?.translate('azkar.bismillah') ??
                        'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيمِ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _categoryColor,
                      fontFamily: 'Almarai',
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                _buildIslamicDivider(),
                const SizedBox(height: 24),
              ],
            ),

          // Dua Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: _categoryColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Main Dua Text
                  Text(
                    item.text,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 2.0,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),

                  const SizedBox(height: 16),

                  // Source/footnote if it exists
                  if (item.text.contains('(رواه'))
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        // Extract the source text
                        item.text.substring(
                            item.text.indexOf('(') + 1, item.text.indexOf(')')),
                        style: TextStyle(
                          fontSize: 15,
                          color: _categoryColor,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),

                  if (item.count > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${context.l10n?.translate('azkar.repetition')}: ${item.count} ${context.l10n?.translate('azkar.times')}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _categoryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, AzkarCategorySelected state) {
    final currentItem = state.category.items[_currentPage];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Counter circle - ALWAYS show the counter
          GestureDetector(
            onTap: () => _incrementCounter(currentItem),
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: _categoryColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress indicator
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            // If count is 1 or 0, just set max to 1
                            end: currentItem.count > 0
                                ? (_repeatCount) / currentItem.count
                                : _repeatCount / 1,
                          ),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return CircularProgressIndicator(
                              value: value,
                              strokeWidth: 10,
                              backgroundColor:
                                  _categoryColor.withValues(alpha: 0.1),
                              color: _categoryColor,
                            );
                          }),
                    ),

                    // Counter text - Modified to handle count=1 case
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_repeatCount',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _categoryColor,
                          ),
                        ),
                        Text(
                          currentItem.count > 1
                              ? '${context.l10n?.translate('azkar.from')} ${currentItem.count}'
                              : context.l10n
                                      ?.translate('azkar.tap_to_continue') ??
                                  'Tap to continue',
                          style: TextStyle(
                            fontSize: 12,
                            color: _categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  Icons.copy_rounded,
                  context.l10n?.translate('azkar.copy') ?? 'Copy',
                  onTap: () => _copyTextToClipboard(context, state),
                ),
                _buildActionButton(
                  context,
                  Icons.share_rounded,
                  context.l10n?.translate('azkar.share') ?? 'Share',
                  onTap: () => _shareText(context, state),
                ),
                // _buildActionButton(
                //   context,
                //   Icons.favorite_border_rounded,
                //   context.l10n?.translate('favorite') ?? 'Favorite',
                //   onTap: () {},
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIslamicDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: _categoryColor.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(
            Icons.star,
            size: 16,
            color: _categoryColor,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: _categoryColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _categoryColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _categoryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyTextToClipboard(
      BuildContext context, AzkarCategorySelected state) async {
    final text = state.category.items[_currentPage].text;
    await Clipboard.setData(ClipboardData(text: text));

    // Show snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.l10n?.translate('azkar.text_copied') ?? 'Text copied'),
          duration: const Duration(seconds: 2),
          backgroundColor: _categoryColor,
        ),
      );
    }
  }

  void _shareText(BuildContext context, AzkarCategorySelected state) async {
    final text = state.category.items[_currentPage].text;
    final category = state.category.title;

    await Share.share(
      '$text\n\n${context.l10n?.translate('azkar.from')} $category - ${context.l10n?.translate('azkar.app_name')}',
      subject: category,
    );
  }
}
