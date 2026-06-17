import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';
import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_cubit.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_state.dart';
import 'package:wadhakir/features/salah_tracker/views/widgets/salah_status_sheet.dart';
import 'package:wadhakir/features/salah_tracker/views/widgets/salah_status_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Today's five fard rows. Each row shows the logged status (tap to choose) and,
/// when [SalahLogModel.trackNawafil] is on, an inline per-prayer Sunnah toggle.
/// A prayer whose time hasn't arrived yet is shown inactive (not loggable). A
/// single Witr row sits at the bottom.
class SalahTodayCard extends StatelessWidget {
  final SalahTrackerLoaded state;
  final PrayerTimesModel? todayTimes;

  const SalahTodayCard({super.key, required this.state, this.todayTimes});

  DateTime? _timeFor(PrayerSlot slot) {
    final t = todayTimes;
    if (t == null) return null;
    switch (slot) {
      case PrayerSlot.fajr:
        return t.fajr;
      case PrayerSlot.dhuhr:
        return t.dhuhr;
      case PrayerSlot.asr:
        return t.asr;
      case PrayerSlot.maghrib:
        return t.maghrib;
      case PrayerSlot.isha:
        return t.isha;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dayKey = SalahLogModel.dateKey(state.today);
    final now = DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: Radii.all(Radii.md),
        border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          for (final slot in PrayerSlot.values)
            _FardRow(
              slot: slot,
              status: state.todayStatuses[slot] ?? PrayerStatus.notLogged,
              time: _timeFor(slot),
              today: state.today,
              // Not active until its adhan time has entered (today only). When
              // the time is unknown (prayer times not loaded) allow logging.
              isDue: _isDue(_timeFor(slot), now),
              trackNawafil: state.log.trackNawafil,
              log: state.log,
              dayKey: dayKey,
            ),
          if (state.log.trackNawafil) ...[
            const Divider(height: 1),
            _WitrRow(done: state.log.witrDone(dayKey), today: state.today),
          ],
        ],
      ),
    );
  }

  static bool _isDue(DateTime? time, DateTime now) =>
      time == null ? true : !now.isBefore(time);
}

class _FardRow extends StatelessWidget {
  final PrayerSlot slot;
  final PrayerStatus status;
  final DateTime? time;
  final DateTime today;
  final bool isDue;
  final bool trackNawafil;
  final SalahLogModel log;
  final String dayKey;

  const _FardRow({
    required this.slot,
    required this.status,
    required this.time,
    required this.today,
    required this.isDue,
    required this.trackNawafil,
    required this.log,
    required this.dayKey,
  });

  Future<void> _onTap(BuildContext context) async {
    final cubit = context.read<SalahTrackerCubit>();
    final chosen = await showSalahStatusSheet(
      context,
      slot: slot,
      current: status,
    );
    if (chosen != null) {
      await cubit.logFard(today, slot, chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = isDue
        ? SalahStatusUi.color(context, status)
        : cs.onSurface.withValues(alpha: 0.3);
    final mutedText = cs.onSurface.withValues(alpha: 0.4);

    return Column(
      children: [
        InkWell(
          onTap: isDue ? () => _onTap(context) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  isDue
                      ? SalahStatusUi.icon(status)
                      : Icons.lock_clock_outlined,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SalahStatusUi.slotLabel(context, slot),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDue ? null : mutedText,
                        ),
                      ),
                      if (time != null)
                        Text(
                          _format(context, time!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isDue)
                  _StatusChip(status: status, color: color)
                else
                  Text(
                    context.l10n?.translate('salah_tracker.not_due') ??
                        'لم تحن بعد',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: mutedText,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // One row per actual rawatib unit for this prayer: Fajr → 2 qabliyyah;
        // Dhuhr → 4 qabliyyah + 2 baʿdiyyah; Maghrib/Isha → 2 baʿdiyyah; Asr →
        // none (no muʾakkadah rawatib), so nothing renders.
        if (trackNawafil)
          for (final unit in RawatibUnit.forSlot(slot))
            _RawatibSubRow(
              unit: unit,
              done: log.rawatibDone(dayKey, unit),
              today: today,
              enabled: isDue,
            ),
      ],
    );
  }

  String _format(BuildContext context, DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12
        ? (context.l10n?.translate('salah_tracker.am') ?? 'ص')
        : (context.l10n?.translate('salah_tracker.pm') ?? 'م');
    return '$h:$m $period';
  }
}

class _StatusChip extends StatelessWidget {
  final PrayerStatus status;
  final Color color;

  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Radii.pillBorder,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        SalahStatusUi.statusLabel(context, status),
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Thin indented toggle for a single Sunnah rawatib [unit] under its fard row.
/// Shows whether it's qabliyyah/baʿdiyyah, its rakʿah count, and an "آكدها"
/// badge on the most-emphasized rawatib (راتبة الفجر).
class _RawatibSubRow extends StatelessWidget {
  final RawatibUnit unit;
  final bool done;
  final DateTime today;
  final bool enabled;

  const _RawatibSubRow({
    required this.unit,
    required this.done,
    required this.today,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final activeColor = SalahStatusUi.color(context, PrayerStatus.onTime);
    final color = !enabled
        ? cs.onSurface.withValues(alpha: 0.3)
        : (done ? activeColor : cs.onSurface.withValues(alpha: 0.55));

    // Neutral tag foreground — kept above AA in light mode and deliberately NOT
    // cs.primary, since primary-blue is a load-bearing status token here (qada /
    // selected). The "آكد" badge reads as a quiet annotation, distinct from the
    // green done-state and the blue status vocabulary.
    final tagFg = cs.onSurface.withValues(alpha: enabled ? 0.7 : 0.3);

    return InkWell(
      onTap: enabled
          ? () => context.read<SalahTrackerCubit>().toggleRawatib(today, unit)
          : null,
      // Guarantee a 44px tap target — these thin sub-rows are real toggles
      // (incl. the single راتبة الفجر toggle), so they must meet the minimum.
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(
          Spacing.xxl,
          Spacing.xxs,
          Spacing.lg,
          Spacing.xxs,
        ),
        child: Row(
          children: [
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: Spacing.sm),
            Flexible(
              child: Text(
                SalahStatusUi.rawatibPositionLabel(context, unit),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            _RawatibTag(
              label: SalahStatusUi.rawatibRakatLabel(context, unit),
              color: tagFg,
              background: cs.onSurface.withValues(alpha: 0.06),
            ),
            if (unit.emphasized) ...[
              const SizedBox(width: Spacing.xs),
              _RawatibTag(
                label: SalahStatusUi.emphasizedLabel(context),
                color: tagFg,
                background: cs.onSurface.withValues(
                  alpha: enabled ? 0.10 : 0.06,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tiny pill used by [_RawatibSubRow] for the rakʿah count and the "آكدها"
/// badge.
class _RawatibTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _RawatibTag({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: Radii.pillBorder,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WitrRow extends StatelessWidget {
  final bool done;
  final DateTime today;

  const _WitrRow({required this.done, required this.today});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = done
        ? SalahStatusUi.color(context, PrayerStatus.onTime)
        : cs.onSurface.withValues(alpha: 0.4);

    return InkWell(
      onTap: () => context.read<SalahTrackerCubit>().toggleWitr(today),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        child: Row(
          children: [
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: color,
              size: 24,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                SalahStatusUi.witrLabel(context),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: done ? null : cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            Text(
              done
                  ? (context.l10n?.translate('salah_tracker.done') ?? 'تم')
                  : (context.l10n?.translate('salah_tracker.optional') ??
                        'اختياري'),
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
