import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/home/views/widgets/grids/feature_grid_card.dart';
import 'package:wadhakir/features/wird/views/screens/wird_screen.dart';

class WirdGridItem extends StatelessWidget {
  const WirdGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FeatureGridCard(
      icon: Icons.menu_book_rounded,
      label: l10n?.translate('wird.home_title') ?? 'الورد اليومي',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WirdScreen()),
      ),
    );
  }
}
