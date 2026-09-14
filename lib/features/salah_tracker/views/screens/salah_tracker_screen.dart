import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/widgets/branded_header.dart';
import 'package:wadhakir/core/widgets/celebration.dart';
import 'package:wadhakir/core/widgets/titled_section.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_cubit.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_state.dart';
import 'package:wadhakir/features/salah_tracker/views/widgets/salah_make_up_card.dart';
import 'package:wadhakir/features/salah_tracker/views/widgets/salah_month_heatmap.dart';
import 'package:wadhakir/features/salah_tracker/views/widgets/salah_streak_header.dart';
import 'package:wadhakir/features/salah_tracker/views/widgets/salah_today_card.dart';
import 'package:wadhakir/features/salah_tracker/views/widgets/salah_week_summary.dart';

/// Streak lengths that earn a bigger celebration.
bool _isStreakMilestone(int streak) =>
    streak == 7 || streak == 30 || streak == 100;

/// The Salah (prayer) tracker screen: streak hero, today's prayers, weekly &
/// monthly stats, and the qada (make-up) counters.
class SalahTrackerScreen extends StatelessWidget {
  const SalahTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Column(
        children: [
          BrandedHeader(
            title:
                l10n?.translate('salah_tracker.screen_title') ?? 'سجل الصلاة',
            subtitle:
                l10n?.translate('salah_tracker.screen_subtitle') ??
                'تابع صلواتك وحافظ على وردك اليومي',
            actions: const [_TrackerMenu()],
          ),
          Expanded(
            child: BlocConsumer<SalahTrackerCubit, SalahTrackerState>(
              // Celebrate only on a real transition: today's 5th prayer just
              // logged, or a streak that just reached 7/30/100. The first
              // observed state has no `previous`, so listenWhen is skipped on
              // screen entry — no celebration for an already-complete day.
              listenWhen: (prev, curr) {
                if (prev is! SalahTrackerLoaded ||
                    curr is! SalahTrackerLoaded) {
                  return false;
                }
                final becameFull =
                    prev.todayPrayedCount < 5 && curr.todayPrayedCount == 5;
                final milestone =
                    _isStreakMilestone(curr.currentStreak) &&
                    curr.currentStreak != prev.currentStreak;
                return becameFull || milestone;
              },
              listener: (context, state) {
                if (state is! SalahTrackerLoaded) return;
                final l10n = context.l10n;
                if (_isStreakMilestone(state.currentStreak)) {
                  // A 7/30/100-day streak is a rare, earned moment → big
                  // gold-star celebration with an achievement card.
                  Celebration.milestone(
                    context,
                    title:
                        (l10n?.translate('celebration.streak_milestone') ??
                                'سلسلة {n} يوم! ما شاء الله')
                            .replaceAll('{n}', '${state.currentStreak}'),
                    subtitle:
                        l10n?.translate(
                          'celebration.streak_milestone_subtitle',
                        ) ??
                        'حافظ على سلسلتك ولا تكسرها',
                  );
                } else {
                  Celebration.burst(
                    context,
                    message:
                        l10n?.translate('celebration.salah_full_day') ??
                        'أتممت صلوات اليوم الخمس، بارك الله فيك',
                  );
                }
              },
              builder: (context, state) {
                if (state is SalahTrackerError) {
                  final cs = Theme.of(context).colorScheme;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 48,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: Spacing.md),
                          Text(
                            l10n?.translate('salah_tracker.error') ??
                                'تعذّر تحميل سجل الصلاة',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: Spacing.lg),
                          ElevatedButton.icon(
                            onPressed: () =>
                                context.read<SalahTrackerCubit>().loadLog(),
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            label: Text(
                              l10n?.translate('common.retry') ??
                                  'إعادة المحاولة',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is! SalahTrackerLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _TrackerBody(state: state);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerBody extends StatelessWidget {
  final SalahTrackerLoaded state;

  const _TrackerBody({required this.state});

  PrayerTimesModel? _todayTimes(BuildContext context) {
    final prayerState = context.watch<PrayerTimesCubit>().state;
    if (prayerState is! PrayerTimesLoaded) return null;
    // state.today is already midnight-normalized; the map is keyed by DateTime.
    return prayerState.prayerTimes[state.today];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SalahTrackerCubit>();
    final todayTimes = _todayTimes(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: Spacing.xxl),
      children: [
        SalahStreakHeader(
          currentStreak: state.currentStreak,
          bestStreak: state.bestStreak,
          todayPrayed: state.todayPrayedCount,
          todayTotal: 5,
        ),
        TitledSection(
          title: l10n?.translate('salah_tracker.today') ?? 'اليوم',
          icon: Icons.today_rounded,
          child: SalahTodayCard(state: state, todayTimes: todayTimes),
        ),
        TitledSection(
          title: l10n?.translate('salah_tracker.this_week') ?? 'هذا الأسبوع',
          icon: Icons.bar_chart_rounded,
          child: SalahWeekSummary(
            log: state.log,
            today: state.today,
            stats: cubit.stats,
          ),
        ),
        TitledSection(
          title: l10n?.translate('salah_tracker.this_month') ?? 'هذا الشهر',
          icon: Icons.calendar_month_rounded,
          child: SalahMonthHeatmap(
            log: state.log,
            today: state.today,
            stats: cubit.stats,
          ),
        ),
        TitledSection(
          title: l10n?.translate('salah_tracker.make_up') ?? 'قضاء الفوائت',
          icon: Icons.history_rounded,
          child: SalahMakeUpCard(log: state.log),
        ),
      ],
    );
  }
}

class _TrackerMenu extends StatelessWidget {
  const _TrackerMenu();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SalahTrackerCubit>();
    final state = context.watch<SalahTrackerCubit>().state;
    final trackNawafil = state is SalahTrackerLoaded && state.log.trackNawafil;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      onSelected: (value) async {
        switch (value) {
          case 'nawafil':
            await cubit.setTrackNawafil(!trackNawafil);
          case 'reset':
            final ok = await _confirmReset(context);
            if (ok) await cubit.resetLog();
        }
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem<String>(
          value: 'nawafil',
          checked: trackNawafil,
          child: Text(
            l10n?.translate('salah_tracker.track_nawafil') ??
                'تتبّع السنن والوتر',
          ),
        ),
        PopupMenuItem<String>(
          value: 'reset',
          child: Text(l10n?.translate('salah_tracker.reset') ?? 'إعادة تعيين'),
        ),
      ],
    );
  }

  Future<bool> _confirmReset(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.translate('salah_tracker.reset') ?? 'إعادة تعيين'),
        content: Text(
          l10n?.translate('salah_tracker.reset_confirm') ??
              'هل تريد مسح كل سجل الصلاة؟ لا يمكن التراجع.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n?.translate('common.cancel') ?? 'إلغاء'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n?.translate('salah_tracker.reset') ?? 'إعادة تعيين',
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
