import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/home/views/widgets/grids/feature_grid_card.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_cubit.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_state.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';

/// Home quick-access card for the Salah tracker. Shows a small trailing badge
/// with today's prayed-count once any prayer is logged.
class SalahTrackerGridItem extends StatelessWidget {
  const SalahTrackerGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureGridCard(
      icon: Icons.checklist_rounded,
      label:
          context.l10n?.translate('salah_tracker.home_title') ?? 'سجل الصلاة',
      onTap: () =>
          Navigator.of(context).pushNamed(AppConstants.salahTrackerRoute),
      trailing: const _TodayBadge(),
    );
  }
}

class _TodayBadge extends StatelessWidget {
  const _TodayBadge();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalahTrackerCubit, SalahTrackerState>(
      buildWhen: (a, b) => a != b,
      builder: (context, state) {
        if (state is! SalahTrackerLoaded || state.todayPrayedCount == 0) {
          return const SizedBox.shrink();
        }
        final cs = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${WirdFormat.toArabicDigits(state.todayPrayedCount)}/${WirdFormat.toArabicDigits(5)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
