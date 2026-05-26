import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/data/models/azkar_item.dart';
import 'package:wadhakir/data/models/azkar_category.dart';
import 'package:wadhakir/features/azkar/cubit/azkar_cubit.dart';
import 'package:wadhakir/features/azkar/cubit/azkar_state.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/repositories/azkar_repository_impl.dart';
import 'package:wadhakir/features/azkar/views/widgets/islamic_pattern_painter.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';

class AzkarCategoryDetailsScreen extends StatefulWidget {
  final AzkarCategory category;

  const AzkarCategoryDetailsScreen({super.key, required this.category});

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

  IconData get _categoryIcon {
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
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();

    _pageController.addListener(() {
      int page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
          _repeatCount = 0;
        });
        // Re-trigger animation for new page
        _animationController.forward(from: 0);
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
    final maxCount = item.count <= 1 ? 1 : item.count;

    if (_repeatCount < maxCount) {
      setState(() {
        _repeatCount++;
        HapticFeedback.mediumImpact();
      });

      if (_repeatCount >= maxCount) {
        HapticFeedback.heavyImpact();
        if (_autoAdvance) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _moveToNextPage();
          });
        }
      }
    }
  }

  void _moveToNextPage() {
    if (_currentPage < widget.category.items.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n?.translate('azkar.completed_all_azkar') ??
                'أكملت جميع الأذكار',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => AzkarCubit(azkarRepository: AzkarRepositoryImpl())
        ..selectCategory(widget.category),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return BlocBuilder<AzkarCubit, AzkarState>(
      builder: (context, state) {
        if (state is AzkarCategorySelected) {
          return _buildCategoryContent(context, state, theme);
        }
        return Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        );
      },
    );
  }

  Widget _buildCategoryContent(
    BuildContext context,
    AzkarCategorySelected state,
    ThemeData theme,
  ) {
    final size = MediaQuery.of(context).size;
    if (state.category.items.isEmpty) {
      return Center(
        child: Text(
          context.l10n?.translate('azkar.no_azkar_in_this_category') ??
              'لا توجد أذكار في هذه الفئة',
        ),
      );
    }

    return Stack(
      children: [
        // Islamic pattern background
        Positioned.fill(
          child: Opacity(
            opacity: 0.02,
            child: CustomPaint(
              painter: IslamicPatternPainter(
                color: theme.colorScheme.primary,
                gridSize: 100,
              ),
            ),
          ),
        ),

        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Custom Header with back button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _categoryIcon,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.category.getLocalizedTitle(
                                  Localizations.localeOf(context).languageCode,
                                ),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${state.category.items.length} ${context.l10n?.translate('azkar.items') ?? 'أذكار'}',
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

                  // Progress indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentPage + 1}/${state.category.items.length}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: ((_currentPage + 1) /
                                  state.category.items.length),
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              color: theme.colorScheme.primary,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Auto-advance toggle — controls whether finishing a
                        // dhikr's count jumps to the next one. Icon previously
                        // used play/pause which was confusing; "skip_next"
                        // matches the actual behaviour.
                        Tooltip(
                          message: context.l10n?.translate(
                                'azkar.auto_advance_tooltip',
                              ) ??
                              'ينتقل تلقائياً للذكر التالي عند الانتهاء من العدد',
                          waitDuration: const Duration(milliseconds: 250),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _autoAdvance = !_autoAdvance;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _autoAdvance
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _autoAdvance
                                        ? Icons.skip_next_rounded
                                        : Icons.last_page_rounded,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.l10n?.translate(
                                          'azkar.auto_advance_label',
                                        ) ??
                                        context.l10n?.translate(
                                          'azkar.auto_move',
                                        ) ??
                                        (_autoAdvance ? 'تلقائي' : 'يدوي'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: size.height * 0.02),

            // PageView for Azkar items - Touch anywhere to count
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (state.category.items.isNotEmpty &&
                      _currentPage < state.category.items.length) {
                    _incrementCounter(state.category.items[_currentPage]);
                  }
                },
                behavior: HitTestBehavior.translucent,
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
                          opacity: _animationController,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Curves.easeOut,
                              ),
                            ),
                            child: _buildAdhkarPage(context, item, theme),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Bottom panel
            _buildBottomPanel(context, state, theme),
          ],
        ),
      ],
    );
  }

  Widget _buildAdhkarPage(
    BuildContext context,
    AdhkarItem item,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Dua Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Main Dua Text
                Text(
                  item.text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 22,
                    height: 2.0,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),

                // Count badge
                if (item.count > 1) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${item.count} ${context.l10n?.translate('azkar.times') ?? 'مرات'}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Source / hadith reference (only when the data provides it)
                if (item.reference != null && item.reference!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _AdhkarSourceRow(reference: item.reference!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(
    BuildContext context,
    AzkarCategorySelected state,
    ThemeData theme,
  ) {
    final currentItem = state.category.items[_currentPage];
    final maxCount = currentItem.count > 0 ? currentItem.count : 1;
    final progress = _repeatCount / maxCount;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Counter circle — the primary tap target. The whole screen above
          // is also tappable for convenience, but new users need to see this
          // ring so the tap interaction is discoverable.
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 16),
            child: Tooltip(
              message: context.l10n?.translate('azkar.tap_to_count_tooltip') ??
                  'اضغط للعدّ — يمكنك أيضاً الضغط على أي مكان من الشاشة',
              waitDuration: const Duration(milliseconds: 250),
              child: GestureDetector(
                onTap: () => _incrementCounter(currentItem),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
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
                        width: 120,
                        height: 120,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return CircularProgressIndicator(
                              value: value,
                              strokeWidth: 8,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              color: theme.colorScheme.primary,
                            );
                          },
                        ),
                      ),

                      // Counter text
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_repeatCount',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (maxCount > 1)
                            Text(
                              '${context.l10n?.translate('azkar.from') ?? 'من'} $maxCount',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action buttons with bottom safe area padding
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context,
                    Icons.copy_rounded,
                    context.l10n?.translate('azkar.copy') ?? 'نسخ',
                    theme,
                    onTap: () => _copyTextToClipboard(context, state, theme),
                  ),
                  _buildActionButton(
                    context,
                    Icons.share_rounded,
                    context.l10n?.translate('azkar.share') ?? 'مشاركة',
                    theme,
                    onTap: () => _shareText(context, state),
                  ),
                ],
              ),
            ),
          ),
          // add more space
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    ThemeData theme, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyTextToClipboard(
    BuildContext context,
    AzkarCategorySelected state,
    ThemeData theme,
  ) async {
    final text = state.category.items[_currentPage].text;
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n?.translate('azkar.text_copied') ?? 'تم النسخ',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: theme.colorScheme.primary,
        ),
      );
    }
  }

  /// Open the branded share screen for the current dhikr. The screen
  /// renders a 4:5 card, lets the user share it as a PNG (or fall back to
  /// text), and handles the share-plus call itself. We just hand it a
  /// `SharePayload` and let it own the flow.
  void _shareText(BuildContext context, AzkarCategorySelected state) {
    final item = state.category.items[_currentPage];
    final category = state.category.getLocalizedTitle(
      Localizations.localeOf(context).languageCode,
    );
    Navigator.of(context).pushNamed(
      AppConstants.shareRoute,
      arguments: SharePayload(
        headline: item.text,
        categoryLabel: category,
        repetitions: item.count > 1 ? item.count : null,
        reference: item.reference,
      ),
    );
  }
}

/// Collapsible "Source" row shown under each dhikr that has a hadith / Quran
/// reference. Defaults to collapsed (just a chevron + label) so the dhikr
/// text remains the focus.
class _AdhkarSourceRow extends StatefulWidget {
  final String reference;

  const _AdhkarSourceRow({required this.reference});

  @override
  State<_AdhkarSourceRow> createState() => _AdhkarSourceRowState();
}

class _AdhkarSourceRowState extends State<_AdhkarSourceRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final muted = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75) ??
        Colors.grey;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 16, color: muted),
                  const SizedBox(width: 6),
                  Text(
                    l10n?.translate('azkar.source_label') ?? 'المصدر',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: muted,
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8, right: 22),
                        child: Text(
                          widget.reference,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                            height: 1.55,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
