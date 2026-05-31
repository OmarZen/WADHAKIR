import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/home/views/widgets/grids/feature_grid_card.dart';
import 'package:wadhakir/features/tasbih/views/screens/electronic_tasbih_screen.dart';

class ElectronicTasbihGridItem extends StatelessWidget {
  const ElectronicTasbihGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FeatureGridCard(
      icon: Icons.radio_button_checked_outlined,
      label: l10n?.translate('home.electronic_tasbih') ?? 'مسبحة إلكترونية',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ElectronicTasbihScreen(),
          ),
        );
      },
    );
  }
}
