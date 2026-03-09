import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/fasting/islamic_fasting_day_model.dart';
import 'package:wadhakir/features/azkar/views/widgets/islamic_pattern_painter.dart';

/// Detailed information screen for a specific fasting day
class FastingInfoScreen extends StatefulWidget {
  final IslamicFastingDay fastingDay;
  final int daysUntil;

  const FastingInfoScreen({
    super.key,
    required this.fastingDay,
    required this.daysUntil,
  });

  @override
  State<FastingInfoScreen> createState() => _FastingInfoScreenState();
}

class _FastingInfoScreenState extends State<FastingInfoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;

    final fastingName = languageCode == 'ar'
        ? widget.fastingDay.nameAr
        : widget.fastingDay.nameEn;
    final fastingDescription = languageCode == 'ar'
        ? widget.fastingDay.descriptionAr
        : widget.fastingDay.descriptionEn;

    final cardColor = _getColorForType(widget.fastingDay.type, isDark, theme);

    return Scaffold(
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : theme.colorScheme.primary.withValues(alpha: 0.05),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero header
            SliverToBoxAdapter(
              child: _buildHeroHeader(
                theme,
                isDark,
                languageCode,
                l10n,
                fastingName,
                cardColor,
              ),
            ),

            // Description card
            SliverToBoxAdapter(
              child: _buildDescriptionCard(
                theme,
                isDark,
                languageCode,
                l10n,
                fastingDescription,
              ),
            ),

            // Virtues/Hadiths section
            SliverToBoxAdapter(
              child: _buildVirtuesSection(
                theme,
                isDark,
                languageCode,
                l10n,
              ),
            ),

            // Fasting guide
            SliverToBoxAdapter(
              child: _buildFastingGuide(
                theme,
                isDark,
                languageCode,
                l10n,
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(
    ThemeData theme,
    bool isDark,
    String languageCode,
    AppLocalizations? l10n,
    String fastingName,
    Color cardColor,
  ) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor,
            cardColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Islamic pattern background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: IslamicPatternPainter(
                    color: Colors.white,
                    gridSize: 60,
                  ),
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 16,
            left: languageCode == 'ar' ? null : 16,
            right: languageCode == 'ar' ? 16 : null,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                languageCode == 'ar'
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_back_rounded,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
              ),
            ),
          ),

          // Share button
          Positioned(
            top: 16,
            right: languageCode == 'ar' ? null : 16,
            left: languageCode == 'ar' ? 16 : null,
            child: IconButton(
              onPressed: () => _shareInfo(languageCode),
              icon: const Icon(Icons.share_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
              ),
            ),
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Fasting name
                  Text(
                    fastingName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Countdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar03,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getCountdownText(
                            widget.daysUntil,
                            languageCode,
                            l10n,
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stars
                  if (widget.fastingDay.rewardLevel > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.fastingDay.rewardLevel,
                        (index) => Icon(
                          Icons.star,
                          color: Colors.amber.shade200,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(
    ThemeData theme,
    bool isDark,
    String languageCode,
    AppLocalizations? l10n,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                l10n?.translate('fasting.about') ??
                    (languageCode == 'ar' ? 'عن هذا اليوم' : 'About This Day'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.8,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtuesSection(
    ThemeData theme,
    bool isDark,
    String languageCode,
    AppLocalizations? l10n,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                l10n?.translate('fasting.virtues') ??
                    (languageCode == 'ar' ? 'الفضائل' : 'Virtues'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.fastingDay.getVirtues(languageCode).map((virtue) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        virtue,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          fontFamily:
                              languageCode == 'ar' ? 'ScheherazadeNew' : null,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFastingGuide(
    ThemeData theme,
    bool isDark,
    String languageCode,
    AppLocalizations? l10n,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                l10n?.translate('fasting.guide') ??
                    (languageCode == 'ar' ? 'دليل الصيام' : 'Fasting Guide'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGuideItem(
            theme,
            Icons.wb_twilight,
            l10n?.translate('fasting.guide_suhoor') ??
                (languageCode == 'ar' ? 'السحور' : 'Pre-dawn meal (Suhoor)'),
            l10n?.translate('fasting.guide_suhoor_desc') ??
                (languageCode == 'ar'
                    ? 'يُستحب تأخير السحور قبل الفجر'
                    : 'Recommended to delay Suhoor before Fajr'),
          ),
          const SizedBox(height: 12),
          _buildGuideItem(
            theme,
            Icons.favorite_outline,
            l10n?.translate('fasting.guide_intention') ??
                (languageCode == 'ar' ? 'النية' : 'Intention (Niyyah)'),
            l10n?.translate('fasting.guide_intention_desc') ??
                (languageCode == 'ar'
                    ? 'تبييت النية من الليل للصيام المستحب'
                    : 'Make intention the night before'),
          ),
          const SizedBox(height: 12),
          _buildGuideItem(
            theme,
            Icons.restaurant,
            l10n?.translate('fasting.guide_iftar') ??
                (languageCode == 'ar' ? 'الإفطار' : 'Breaking fast (Iftar)'),
            l10n?.translate('fasting.guide_iftar_desc') ??
                (languageCode == 'ar'
                    ? 'يُستحب التعجيل بالفطر عند غروب الشمس'
                    : 'Break fast immediately at sunset'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
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
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(FastingDayType type, bool isDark, ThemeData theme) {
    switch (type) {
      case FastingDayType.ayyamAlBid:
        // White Days (Moon phases) - Use secondary/tertiary theme colors
        return isDark ? theme.colorScheme.secondary : theme.colorScheme.tertiary;
      case FastingDayType.ninthTenth:
        // 9th & 10th - Use primary theme color
        return isDark
            ? theme.colorScheme.primary.withValues(alpha: 0.8)
            : theme.colorScheme.primary;
      case FastingDayType.special:
        // Special days (Ashura, Arafah) - Use primary color (most important)
        return theme.colorScheme.primary;
      case FastingDayType.weeklyFasting:
        // Weekly fasting - Use tertiary/secondary theme colors
        return isDark ? theme.colorScheme.tertiary : theme.colorScheme.secondary;
    }
  }

  String _getCountdownText(
    int days,
    String languageCode,
    AppLocalizations? l10n,
  ) {
    if (days == 0) {
      return l10n?.translate('fasting.today') ??
          (languageCode == 'ar' ? 'اليوم' : 'Today');
    } else if (days == 1) {
      return l10n?.translate('fasting.tomorrow') ??
          (languageCode == 'ar' ? 'غداً' : 'Tomorrow');
    } else {
      return languageCode == 'ar' ? 'بعد $days أيام' : 'In $days days';
    }
  }

  void _shareInfo(String languageCode) {
    final fastingName = languageCode == 'ar'
        ? widget.fastingDay.nameAr
        : widget.fastingDay.nameEn;
    final fastingDescription = languageCode == 'ar'
        ? widget.fastingDay.descriptionAr
        : widget.fastingDay.descriptionEn;

    final shareText = '$fastingName\n\n$fastingDescription';
    SharePlus.instance.share(shareText as ShareParams);
  }
}
