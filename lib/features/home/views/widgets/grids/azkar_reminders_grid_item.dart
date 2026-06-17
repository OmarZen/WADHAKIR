import 'package:flutter/material.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/home/views/widgets/grids/feature_grid_card.dart';

/// Home quick-access card for the daily azkar reminders settings.
class AzkarRemindersGridItem extends StatelessWidget {
  const AzkarRemindersGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureGridCard(
      icon: Icons.notifications_active_outlined,
      label:
          context.l10n?.translate('azkar_reminders.title') ?? 'تذكيرات الأذكار',
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppConstants.azkarRemindersSettingsRoute),
    );
  }
}
