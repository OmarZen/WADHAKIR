import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/fasting_reminders/cubit/fasting_reminders_cubit.dart';
import 'package:wadhakir/features/fasting_reminders/views/screens/fasting_calendar_screen.dart';
import 'package:wadhakir/features/home/views/widgets/grids/feature_grid_card.dart';

class FastingCalendarGridItem extends StatelessWidget {
  const FastingCalendarGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FeatureGridCard(
      icon: Icons.calendar_month_rounded,
      label: l10n?.translate('fasting.calendar_title') ?? 'تقويم الصيام',
      onTap: () => _showFastingCalendar(context),
    );
  }

  Future<void> _showFastingCalendar(BuildContext context) async {
    final cubit = context.read<FastingRemindersCubit>();

    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const FastingCalendarScreen(),
      ),
    );
  }
}
