import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_cubit.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_state.dart';
import 'package:wadhakir/features/salah_tracker/views/widgets/salah_status_ui.dart';

/// Compact logged-status chip shown inline on a prayer-times fard card.
/// Reflects today's [SalahTrackerCubit] status for [slot]; a faint outline
/// circle invites the user to log when nothing is recorded yet. When [due] is
/// false (the prayer's time hasn't arrived) it shows an inactive clock.
class SalahFardStatusBadge extends StatelessWidget {
  final PrayerSlot slot;
  final bool due;

  const SalahFardStatusBadge({super.key, required this.slot, this.due = true});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!due) {
      final muted = cs.onSurface.withValues(alpha: 0.3);
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: muted, width: 1.5),
        ),
        child: Icon(Icons.lock_clock_outlined, size: 16, color: muted),
      );
    }

    return BlocBuilder<SalahTrackerCubit, SalahTrackerState>(
      buildWhen: (a, b) => a != b,
      builder: (context, state) {
        final status = state is SalahTrackerLoaded
            ? (state.todayStatuses[slot] ?? PrayerStatus.notLogged)
            : PrayerStatus.notLogged;
        final color = SalahStatusUi.color(context, status);

        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: status == PrayerStatus.notLogged
                ? Colors.transparent
                : color.withValues(alpha: 0.14),
            border: Border.all(
              color: status == PrayerStatus.notLogged
                  ? color.withValues(alpha: 0.6)
                  : color,
              width: 1.5,
            ),
          ),
          child: Icon(SalahStatusUi.icon(status), size: 16, color: color),
        );
      },
    );
  }
}
