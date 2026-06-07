import 'package:flutter/material.dart';
import 'grids/moon_phases_grid_item.dart';
import 'grids/pray_azkar_grid_item.dart';
import 'grids/allah_names_grid_item.dart';
import 'grids/fasting_calendar_grid_item.dart';
import 'grids/nearest_mosque_grid_item.dart';
import 'grids/islamic_backgrounds_grid_item.dart';
import 'grids/wird_grid_item.dart';
import 'grids/hadith_nawawi_grid_item.dart';
import 'grids/raqia_grid_item.dart';
import 'grids/tasbih_grid_item.dart';
import 'grids/electronic_tasbih_grid_item.dart';
// Hadith library grid removed (hadith feature pruned)
// Islamic history grid removed (data retained in assets/json_data/history.json
// for future re-enable — see islamic_history feature, currently unreferenced)
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/widgets/titled_section.dart';

/// The home feature directory, grouped into labelled sections of vertical
/// icon tiles so users can discover every feature at a glance.
class MoreIslamicExcerptsWidget extends StatelessWidget {
  const MoreIslamicExcerptsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(
          context,
          title: l10n?.translate('home.section_read') ?? 'اقرأ وتدبّر',
          icon: Icons.auto_stories_rounded,
          items: const [
            WirdGridItem(),
            HadithNawawiGridItem(),
            AllahNamesGridItem(),
            RaqiaGridItem(),
          ],
        ),
        _section(
          context,
          title: l10n?.translate('home.section_adhkar') ?? 'أذكار وتسبيح',
          icon: Icons.favorite_rounded,
          items: const [
            PrayAzkarGridItem(),
            TasbihGridItem(),
            ElectronicTasbihGridItem(),
          ],
        ),
        _section(
          context,
          title: l10n?.translate('home.section_tools') ?? 'مواقيت وأدوات',
          icon: Icons.explore_rounded,
          items: const [
            FastingCalendarGridItem(),
            MoonPhasesGridItem(),
            NearestMosqueGridItem(),
            IslamicBackgroundsGridItem(),
          ],
        ),
      ],
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = PlatformUtils.isDesktop;
    final columns = !isDesktop
        ? 3
        : (width >= 1200 ? 5 : (width >= 900 ? 4 : 3));

    return TitledSection(
      title: title,
      icon: icon,
      child: GridView.count(
        crossAxisCount: columns,
        childAspectRatio: 0.92,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: items,
      ),
    );
  }
}
