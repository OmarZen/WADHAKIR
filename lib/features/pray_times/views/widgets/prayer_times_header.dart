import 'package:flutter/material.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/views/widgets/prayer_settings_dialog.dart';

class PrayerTimesHeader extends StatelessWidget {
  final Size size;
  final PrayerTimesCubit cubit;

  const PrayerTimesHeader({super.key, required this.size, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDesktop = PlatformUtils.isDesktop;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 16.0 : size.width * 0.02,
        isDesktop ? 20.0 : size.height * 0.02,
        isDesktop ? 24.0 : size.width * 0.04,
        isDesktop ? 20.0 : size.height * 0.02,
      ),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              color: theme.colorScheme.primary,
              onPressed: () {
                Navigator.of(context).pop();
              },
              tooltip: l10n?.translate('common.back') ?? 'رجوع',
            ),
          ),
          SizedBox(width: isDesktop ? 12.0 : size.width * 0.02),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.translate('prayer_times.title') ?? 'مواقيت الصلاة',
                  style: TextStyle(
                    fontSize: isDesktop ? 28.0 : size.width * 0.06,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontFamily: 'Almarai',
                  ),
                ),
                Text(
                  l10n?.translate('prayer_times.daily_prayers') ??
                      'الصلوات اليومية',
                  style: TextStyle(
                    fontSize: isDesktop ? 16.0 : size.width * 0.035,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.settings),
              color: theme.colorScheme.primary,
              onPressed: () {
                PrayerSettingsDialog.show(context, cubit);
              },
              tooltip: l10n?.translate('prayer_times.settings') ?? 'الإعدادات',
            ),
          ),
        ],
      ),
    );
  }
}
