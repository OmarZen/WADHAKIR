import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/home/views/widgets/grids/feature_grid_card.dart';
import 'package:wadhakir/features/hadith_nawawi/views/screens/hadith_nawawi_screen.dart';

class HadithNawawiGridItem extends StatelessWidget {
  const HadithNawawiGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FeatureGridCard(
      icon: Icons.auto_stories_rounded,
      label: l10n?.translate('hadith_nawawi.title') ?? 'الأربعون النووية',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HadithNawawiScreen()),
      ),
    );
  }
}
