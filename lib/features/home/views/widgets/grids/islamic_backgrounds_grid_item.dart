import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/home/views/widgets/grids/feature_grid_card.dart';
import 'package:wadhakir/features/islamic_backgrounds/views/screens/islamic_backgrounds_screen.dart';

class IslamicBackgroundsGridItem extends StatelessWidget {
  const IslamicBackgroundsGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FeatureGridCard(
      icon: Icons.wallpaper_rounded,
      label:
          l10n?.translate('islamic_backgrounds.home_title') ??
          'الخلفيات الإسلامية',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const IslamicBackgroundsScreen(),
        ),
      ),
    );
  }
}
