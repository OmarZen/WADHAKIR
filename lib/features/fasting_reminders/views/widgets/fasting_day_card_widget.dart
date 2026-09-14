import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/fasting/islamic_fasting_day_model.dart';
import 'package:wadhakir/features/azkar/views/widgets/islamic_pattern_painter.dart';

/// A card widget displaying information about a fasting day
class FastingDayCardWidget extends StatelessWidget {
  final IslamicFastingDay fastingDay;
  final int daysUntil;
  final bool isUpcoming;
  final VoidCallback? onTap;

  const FastingDayCardWidget({
    super.key,
    required this.fastingDay,
    required this.daysUntil,
    this.isUpcoming = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;

    final fastingName = languageCode == 'ar'
        ? fastingDay.nameAr
        : fastingDay.nameEn;
    final fastingDescription = languageCode == 'ar'
        ? fastingDay.descriptionAr
        : fastingDay.descriptionEn;

    // Get color based on fasting day type
    final cardColor = _getColorForType(fastingDay.type, isDark, theme);
    final borderRadius = BorderRadius.circular(20);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isUpcoming
                ? cardColor.withValues(alpha: 0.98)
                : isDark
                ? theme.colorScheme.surface
                : Colors.white,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: isUpcoming
                    ? cardColor.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
            border: isUpcoming
                ? Border.all(color: cardColor, width: 2)
                : Border.all(
                    color: isDark
                        ? theme.colorScheme.outline.withValues(alpha: 0.2)
                        : Colors.grey.shade100,
                    width: 1,
                  ),
          ),
          child: Stack(
            children: [
              // Islamic pattern background
              if (isUpcoming)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: borderRadius,
                    child: Opacity(
                      opacity: 0.08,
                      child: CustomPaint(
                        painter: IslamicPatternPainter(
                          color: Colors.white,
                          gridSize: 40,
                        ),
                      ),
                    ),
                  ),
                ),

              // Upcoming badge
              if (isUpcoming)
                Positioned(
                  top: 12,
                  right: languageCode == 'ar' ? null : 12,
                  left: languageCode == 'ar' ? 12 : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.upcoming_rounded,
                          size: 14,
                          color: cardColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n?.translate('fasting.upcoming') ?? 'قريباً',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cardColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Special day star indicator
              if (fastingDay.isSpecialDay)
                Positioned(
                  top: 12,
                  left: languageCode == 'ar' ? null : 12,
                  right: languageCode == 'ar' ? 12 : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUpcoming
                          ? Colors.white.withValues(alpha: 0.9)
                          : cardColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.star_rounded, size: 20, color: cardColor),
                  ),
                ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fasting day name
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          color: isUpcoming
                              ? Colors.white
                              : theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fastingName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: isUpcoming
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      fastingDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isUpcoming
                            ? Colors.white.withValues(alpha: 0.9)
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 16),

                    // Footer with countdown and reward stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Countdown
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isUpcoming
                                ? Colors.white.withValues(alpha: 0.2)
                                : cardColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar03,
                                size: 16,
                                color: isUpcoming ? Colors.white : cardColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getCountdownText(
                                  daysUntil,
                                  languageCode,
                                  l10n,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isUpcoming ? Colors.white : cardColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Reward stars
                        Row(
                          children: List.generate(
                            fastingDay.rewardLevel,
                            (index) => Icon(
                              Icons.star,
                              size: 18,
                              color: isUpcoming
                                  ? Colors.amber.shade200
                                  : Colors.amber.shade600,
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
      ),
    );
  }

  Color _getColorForType(FastingDayType type, bool isDark, ThemeData theme) {
    switch (type) {
      case FastingDayType.ayyamAlBid:
        // White Days (Moon phases) - Use secondary/tertiary theme colors
        return isDark
            ? theme.colorScheme.secondary
            : theme.colorScheme.tertiary;
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
        return isDark
            ? theme.colorScheme.tertiary
            : theme.colorScheme.secondary;
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
}
