import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/widgets/titled_section.dart';
import 'package:wadhakir/data/models/fasting/islamic_fasting_day_model.dart';
import 'package:wadhakir/features/fasting_reminders/cubit/fasting_reminders_cubit.dart';
import 'package:wadhakir/features/fasting_reminders/cubit/fasting_reminders_state.dart';
import 'package:wadhakir/features/fasting_reminders/views/screens/fasting_calendar_screen.dart';

/// "مناسبات دينية" — a horizontal strip of the upcoming notable Islamic days
/// (Ashura, Arafah, white days, etc.), reusing the data already computed by
/// [FastingRemindersCubit]. Tapping opens the fasting calendar.
class ReligiousOccasionsStrip extends StatelessWidget {
  const ReligiousOccasionsStrip({super.key});

  void _openCalendar(BuildContext context) {
    final cubit = context.read<FastingRemindersCubit>();
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const FastingCalendarScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<FastingRemindersCubit, FastingRemindersState>(
      builder: (context, state) {
        if (state is! FastingRemindersLoaded) {
          return const SizedBox.shrink();
        }
        final days = state.upcomingFastingDays.take(8).toList();
        if (days.isEmpty) return const SizedBox.shrink();

        return TitledSection(
          title: l10n?.translate('home.religious_occasions') ?? 'مناسبات دينية',
          icon: Icons.event_rounded,
          actionLabel: l10n?.translate('home.view_all') ?? 'عرض الكل',
          onAction: () => _openCalendar(context),
          child: SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _OccasionCard(
                day: days[i],
                onTap: () => _openCalendar(context),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OccasionCard extends StatelessWidget {
  final IslamicFastingDay day;
  final VoidCallback onTap;

  const _OccasionCard({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FTappable(
      onPress: onTap,
      child: SizedBox(
        width: 220,
        child: FCard.raw(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.brightness_3_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        day.nameAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    day.descriptionAr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                  ),
                ),
                if (day.rewardLevel > 0)
                  Row(
                    children: List.generate(
                      day.rewardLevel.clamp(0, 5),
                      (_) =>
                          Icon(Icons.star_rounded, size: 13, color: cs.primary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
