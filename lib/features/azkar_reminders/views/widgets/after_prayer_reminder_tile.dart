import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/azkar_reminders/cubit/azkar_reminders_cubit.dart';
import 'package:wadhakir/features/azkar_reminders/cubit/azkar_reminders_state.dart';
import 'package:wadhakir/features/azkar_reminders/views/widgets/azkar_reminder_toggle_card.dart';

/// After-each-prayer azkar reminder toggle (with a delay stepper). Self-contained
/// so it can live on both the azkar settings page and the prayer-times page.
class AfterPrayerReminderTile extends StatelessWidget {
  const AfterPrayerReminderTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<AzkarRemindersCubit, AzkarRemindersState>(
      builder: (context, state) {
        final s = state.settings;
        final cubit = context.read<AzkarRemindersCubit>();
        return AzkarReminderToggleCard(
          icon: Icons.mosque_outlined,
          title:
              l10n?.translate('azkar_reminders.after_prayer') ??
              'أذكار بعد الصلاة',
          subtitle:
              (l10n?.translate('azkar_reminders.after_prayer_subtitle') ??
                      'بعد كل صلاة بـ {min} دقيقة')
                  .replaceAll('{min}', '${s.afterPrayerDelayMinutes}'),
          value: s.afterPrayerEnabled,
          onToggle: (v) => requestAzkarEnable(
            context,
            enable: v,
            onGranted: () => cubit.setAfterPrayerEnabled(true),
            onDisable: () => cubit.setAfterPrayerEnabled(false),
          ),
          trailingAction: s.afterPrayerEnabled
              ? AzkarDelayStepper(
                  minutes: s.afterPrayerDelayMinutes,
                  onChanged: cubit.setAfterPrayerDelay,
                )
              : null,
        );
      },
    );
  }
}
