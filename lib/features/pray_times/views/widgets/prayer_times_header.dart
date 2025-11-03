import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/views/widgets/prayer_settings_dialog.dart';

class PrayerTimesHeader extends StatelessWidget {
  final Size size;
  final PrayerTimesCubit cubit;

  const PrayerTimesHeader({
    super.key,
    required this.size,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        size.width * 0.04,
        size.height * 0.02,
        size.width * 0.04,
        size.height * 0.02,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.translate('prayer_times.title') ?? 'مواقيت الصلاة',
                  style: TextStyle(
                    fontSize: size.width * 0.06,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontFamily: 'Almarai',
                  ),
                ),
                Text(
                  l10n?.translate('prayer_times.daily_prayers') ??
                      'الصلوات اليومية',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            color: theme.colorScheme.primary,
            onPressed: () {
              PrayerSettingsDialog.show(context, cubit);
            },
          ),
        ],
      ),
    );
  }
}
