import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/features/quran/views/screens/quran_screen.dart';
import 'package:wadhakir/features/wird/cubit/wird_cubit.dart';
import 'package:wadhakir/features/wird/cubit/wird_state.dart';
import 'package:wadhakir/features/wird/services/wird_schedule_service.dart';
import 'package:wadhakir/features/wird/views/widgets/wird_day_tile.dart';
import 'package:wadhakir/features/wird/views/widgets/wird_header.dart';

/// Shared schedule list. Tappable circles when [onToggle] is provided;
/// tappable card bodies (open the reader) when [onOpen] is provided.
class WirdScheduleList extends StatelessWidget {
  final List<WirdDay> schedule;
  final Set<int> completed;

  /// Index of the "current wird" (first incomplete). -1 in preview.
  final int currentIndex;
  final ValueChanged<int>? onToggle;
  final ValueChanged<int>? onOpen;

  const WirdScheduleList({
    super.key,
    required this.schedule,
    required this.completed,
    required this.currentIndex,
    this.onToggle,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: schedule.length,
      itemBuilder: (context, i) {
        final day = schedule[i];
        final isDone = completed.contains(day.dayIndex);
        final isOverdue = !isDone && day.date.isBefore(todayDate);
        return WirdDayTile(
          day: day,
          completed: isDone,
          isCurrent: day.dayIndex == currentIndex,
          isOverdue: isOverdue,
          onToggle: onToggle == null ? null : () => onToggle!(day.dayIndex),
          onOpen: onOpen == null ? null : () => onOpen!(day.dayIndex),
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
              currentIndex: -1,
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
                  currentIndex: state.currentDayIndex,
                  onToggle: (index) =>
                      context.read<WirdCubit>().toggleDayComplete(index),
                  onOpen: (index) {
                    final cubit = context.read<WirdCubit>();
                    final day = state.schedule[index];
                    final resume = index == state.currentDayIndex
                        ? cubit.resumePageForCurrentDay()
                        : day.startPage;
                    cubit.openReaderAtPage(resume);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QuranScreen()),
                    ).then((_) => cubit.saveReaderStopPage());
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
