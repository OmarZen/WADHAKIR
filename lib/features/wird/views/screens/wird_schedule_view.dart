import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/features/wird/cubit/wird_cubit.dart';
import 'package:wadhakir/features/wird/cubit/wird_state.dart';
import 'package:wadhakir/features/wird/services/wird_schedule_service.dart';
import 'package:wadhakir/features/wird/views/widgets/wird_day_tile.dart';
import 'package:wadhakir/features/wird/views/widgets/wird_header.dart';

/// Shared schedule list. Tappable circles when [onToggle] is provided.
class WirdScheduleList extends StatelessWidget {
  final List<WirdDay> schedule;
  final Set<int> completed;
  final int todayIndex;
  final ValueChanged<int>? onToggle;

  const WirdScheduleList({
    super.key,
    required this.schedule,
    required this.completed,
    required this.todayIndex,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: schedule.length,
      itemBuilder: (context, i) {
        final day = schedule[i];
        return WirdDayTile(
          day: day,
          completed: completed.contains(day.dayIndex),
          isToday: day.dayIndex == todayIndex,
          onToggle: onToggle == null ? null : () => onToggle!(day.dayIndex),
        );
      },
    );
  }
}

/// Read-only preview of a draft plan's schedule (from the setup screen).
class WirdSchedulePreviewScreen extends StatelessWidget {
  final WirdPlanModel plan;

  const WirdSchedulePreviewScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const service = WirdScheduleService();
    final schedule = service.buildSchedule(plan);

    return Scaffold(
      body: Column(
        children: [
          WirdHeader(
            title: l10n?.translate('wird.schedule_title') ?? 'جدول القراءة',
          ),
          Expanded(
            child: WirdScheduleList(
              schedule: schedule,
              completed: const <int>{},
              todayIndex: -1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Live schedule for the active plan — toggling persists via the cubit.
class WirdScheduleScreen extends StatelessWidget {
  const WirdScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Column(
        children: [
          WirdHeader(
            title: l10n?.translate('wird.schedule_title') ?? 'جدول القراءة',
          ),
          Expanded(
            child: BlocBuilder<WirdCubit, WirdState>(
              builder: (context, state) {
                if (state is! WirdLoaded || !state.plan.isActive) {
                  return const SizedBox.shrink();
                }
                return WirdScheduleList(
                  schedule: state.schedule,
                  completed: state.plan.completedDayIndices,
                  todayIndex: state.todayDayIndex,
                  onToggle: (index) =>
                      context.read<WirdCubit>().toggleDayComplete(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
