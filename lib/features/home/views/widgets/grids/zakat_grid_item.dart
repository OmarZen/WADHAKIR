import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/home/views/widgets/grids/feature_grid_card.dart';
import 'package:wadhakir/features/zakat/views/screens/zakat_screen.dart';

class ZakatGridItem extends StatelessWidget {
  const ZakatGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FeatureGridCard(
      iconBuilder: (color, size) => HugeIcon(
        icon: HugeIcons.strokeRoundedMoneyBag01,
        color: color,
        size: size,
      ),
      label: l10n?.translate('zakat.home_title') ?? 'حاسبة الزكاة',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ZakatScreen()),
      ),
    );
  }
}
