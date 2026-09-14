import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'grids/feature_grid_card.dart';
import 'grids/moon_phases_grid_item.dart';
import 'grids/pray_azkar_grid_item.dart';
import 'grids/allah_names_grid_item.dart';
import 'grids/fasting_calendar_grid_item.dart';
import 'grids/nearest_mosque_grid_item.dart';
import 'grids/islamic_backgrounds_grid_item.dart';
import 'grids/wird_grid_item.dart';
import 'grids/zakat_grid_item.dart';
import 'grids/hadith_nawawi_grid_item.dart';
import 'grids/raqia_grid_item.dart';
import 'grids/tasbih_grid_item.dart';
import 'grids/electronic_tasbih_grid_item.dart';
import 'grids/azkar_reminders_grid_item.dart';
import 'grids/salah_tracker_grid_item.dart';
// Hadith library grid removed (hadith feature pruned)
// Islamic history grid removed in R3 along with the whole feature and its
// 12.6 MB history.json — it had been unreachable since launch. Recoverable
// from git history if it is ever wanted back.
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
            AzkarRemindersGridItem(),
            TasbihGridItem(),
            ElectronicTasbihGridItem(),
          ],
        ),
        _section(
          context,
          title: l10n?.translate('home.section_tools') ?? 'مواقيت وأدوات',
          icon: Icons.explore_rounded,
          items: const [
            SalahTrackerGridItem(),
            FastingCalendarGridItem(),
            MoonPhasesGridItem(),
            ZakatGridItem(),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;

          // The tile shape this grid has always had, derived from the cell
          // width exactly as `childAspectRatio: 0.92` did.
          final cellWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          final byShape = cellWidth / 0.92;

          // …used as a FLOOR rather than the answer. A ratio derives height
          // from width, and width does not change when the reader turns the
          // text up — so at the largest scales this app offers, the label grew
          // and the cell did not, and every tile in the directory overflowed by
          // the difference. Nothing moves at the default size; the row only
          // gets taller once the text genuinely needs it.
          final extent = math.max(
            byShape,
            FeatureGridCard.minExtentFor(context),
          );

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              mainAxisExtent: extent,
            ),
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, i) => items[i],
          );
        },
      ),
    );
  }
}
