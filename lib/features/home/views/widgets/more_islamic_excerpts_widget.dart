import 'grids/raqia_grid_item.dart';
import 'grids/tasbih_grid_item.dart';
import 'package:flutter/material.dart';
import 'grids/pray_azkar_grid_item.dart';
import 'grids/allah_names_grid_item.dart';
import 'grids/nearest_mosque_grid_item.dart';
import 'grids/hadith_library_grid_item.dart';
import 'grids/islamic_history_grid_item.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class MoreIslamicExcerptsWidget extends StatelessWidget {
  const MoreIslamicExcerptsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = PlatformUtils.isDesktop;

    // Responsive grid configuration
    final crossAxisCount = _getGridCrossAxisCount(size.width, isDesktop);
    final childAspectRatio = _getChildAspectRatio(size.width, isDesktop);
    final horizontalPadding = isDesktop ? 32.0 : 16.0;
    final verticalPadding = isDesktop ? 16.0 : 12.0;
    final gridSpacing = isDesktop ? 16.0 : 8.0;
    final iconPadding = isDesktop ? 10.0 : 8.0;
    final titleSpacing = isDesktop ? 12.0 : 8.0;

    return Center(
      child: Container(
        constraints:
            BoxConstraints(maxWidth: isDesktop ? 1400 : double.infinity),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: isDark
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                        : theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: isDesktop ? 28 : 20,
                    color: isDark
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: titleSpacing),
                Text(
                  l10n?.translate('home.more_islamic_excerpts') ??
                      'مقتطفات إسلامية',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: isDesktop ? 24 : null,
                  ),
                ),
              ],
            ),
            SizedBox(
                height: isDesktop ? size.height * 0.04 : size.height * 0.03),
            GridView.count(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: gridSpacing,
              mainAxisSpacing: gridSpacing,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                AllahNamesGridItem(),
                HadithLibraryGridItem(),
                PrayAzkarGridItem(),
                RaqiaGridItem(),
                TasbihGridItem(),
                NearestMosqueGridItem(),
                IslamicHistoryGridItem(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate grid columns based on screen width and platform
  int _getGridCrossAxisCount(double width, bool isDesktop) {
    if (!isDesktop) return 2; // Mobile: 2 columns

    // Desktop breakpoints
    if (width >= 1400) return 4; // Extra large: 4 columns
    if (width >= 1200) return 4; // Large: 4 columns
    if (width >= 900) return 3; // Medium: 3 columns
    return 2; // Small desktop: 2 columns
  }

  /// Calculate aspect ratio based on screen width and platform
  double _getChildAspectRatio(double width, bool isDesktop) {
    if (!isDesktop) return 2.4; // Mobile: wider cards

    // Desktop: adjust ratio based on column count
    if (width >= 1400) return 3.8; // 4 columns: slightly wider
    if (width >= 1200) return 3.5; // 4 columns: balanced
    if (width >= 900) return 3.0; // 3 columns: wider
    return 2.4; // 2 columns: same as mobile
  }
}
