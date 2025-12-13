import 'grids/raqia_grid_item.dart';
import 'grids/tasbih_grid_item.dart';
import 'package:flutter/material.dart';
import 'grids/pray_azkar_grid_item.dart';
import 'grids/allah_names_grid_item.dart';
import 'grids/nearest_mosque_grid_item.dart';
import 'grids/hadith_library_grid_item.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class MoreIslamicExcerptsWidget extends StatelessWidget {
  const MoreIslamicExcerptsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n?.translate('home.more_islamic_excerpts') ??
                    'مقتطفات إسلامية',
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
          SizedBox(
            height: size.height * 0.03,
          ),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
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
            ],
          ),
        ],
      ),
    );
  }
}
