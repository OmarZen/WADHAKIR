import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

import '../../data/moon_phase.dart';
import '../widgets/moon_islamic_context.dart';
import '../widgets/moon_painter.dart';
import '../widgets/moon_phase_labels.dart';
import 'moon_phase_detail_screen.dart';

/// Main entry screen for the moon phases feature. Layout follows the user's
/// reference screenshots: a hero panel at the top showing today's moon
/// (big, animated) + key stats, then a tappable monthly calendar grid
/// underneath. Tapping any day opens the full detail screen for that date.
class MoonPhasesCalendarScreen extends StatefulWidget {
  const MoonPhasesCalendarScreen({super.key});

  @override
  State<MoonPhasesCalendarScreen> createState() =>
      _MoonPhasesCalendarScreenState();
}

class _MoonPhasesCalendarScreenState extends State<MoonPhasesCalendarScreen>
    with TickerProviderStateMixin {
  DateTime _viewedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<MoonPhaseInfo>? _phases;
  late final AnimationController _enterController;

  @override
  void initState() {
    super.initState();
    _phases = MoonPhaseCalculator.forMonth(_viewedMonth);
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  void _stepMonth(int delta) {
    setState(() {
      _viewedMonth = DateTime(_viewedMonth.year, _viewedMonth.month + delta, 1);
      _phases = MoonPhaseCalculator.forMonth(_viewedMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final phases = _phases ?? const <MoonPhaseInfo>[];
    final today = MoonPhaseCalculator.forDate(DateTime.now());

    return Scaffold(
      // Brand-derived night-sky surface — matches the detail screen, the
      // floating dhikr settings and the onboarding dark surface.
      backgroundColor: const Color(0xFF0F1A2A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: false,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              l10n?.translate('moon_phases.title') ?? 'Moon phases',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Almarai',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Hero: today's moon + key stats above everything else.
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _enterController,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, -0.08),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _enterController,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: _TodayHero(
                  info: today,
                  l10n: l10n,
                  onMore: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MoonPhaseDetailScreen(initialDate: today.date),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Calendar header strip (month nav).
          SliverPersistentHeader(
            pinned: true,
            delegate: _CalendarMonthHeader(
              viewedMonth: _viewedMonth,
              l10n: l10n,
              onPrev: () => _stepMonth(-1),
              onNext: () => _stepMonth(1),
              theme: theme,
            ),
          ),
          SliverToBoxAdapter(child: _WeekdaysRow(l10n: l10n)),
          SliverToBoxAdapter(
            child: const Divider(color: Colors.white12, height: 1),
          ),
          // Calendar grid.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.sm,
              Spacing.sm,
              Spacing.sm,
              Spacing.lg,
            ),
            sliver: _calendarGrid(phases),
          ),
          // Decorative ornamental divider between the calendar and the
          // Islamic context. Reads as a section break without adding a
          // heavy header — keeps the page feeling like one continuous
          // surface rather than two stacked screens.
          const SliverToBoxAdapter(child: _SectionOrnament()),
          // Crescent sighting tips — only when today is new/waxing
          // crescent. Otherwise this whole block is skipped so the
          // verses come right after the ornament.
          if (shouldShowCrescentSighting(today.phase))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: Spacing.lg),
                child: CrescentSightingCard(info: today, l10n: l10n),
              ),
            ),
          // Quranic verses + lunar calendar importance card — the same
          // widget the detail screen uses, so the design stays consistent.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: Spacing.lg),
              child: MoonIslamicContext(l10n: l10n),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Spacing.xxl)),
        ],
      ),
    );
  }

  Widget _calendarGrid(List<MoonPhaseInfo> phases) {
    final firstWeekday = DateTime(
      _viewedMonth.year,
      _viewedMonth.month,
      1,
    ).weekday; // 1=Mon
    // Sunday-first to match the reference design and the rest of the app.
    final leadingBlanks = firstWeekday % 7;
    final cells = leadingBlanks + phases.length;
    final rows = (cells / 7).ceil();
    final itemCount = rows * 7;

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.78,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < leadingBlanks) return const SizedBox.shrink();
        final phaseIndex = index - leadingBlanks;
        if (phaseIndex >= phases.length) return const SizedBox.shrink();
        final info = phases[phaseIndex];
        return _MoonCell(
          info: info,
          isToday: _isSameDay(info.date, DateTime.now()),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MoonPhaseDetailScreen(initialDate: info.date),
              ),
            );
          },
        );
      }, childCount: itemCount),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Hero panel showing today's moon (big, animated) + key stats. Acts as
/// the "main view" of the moon screen — users can read it without paging
/// into the detail screen.
class _TodayHero extends StatelessWidget {
  final MoonPhaseInfo info;
  final AppLocalizations? l10n;
  final VoidCallback onMore;

  const _TodayHero({
    required this.info,
    required this.l10n,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phaseName = MoonPhaseLabels.phaseName(info.phase, l10n);
    final illum = formatPercent(info.illumination);

    return Container(
      margin: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.35),
            theme.colorScheme.primary.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n?.translate('moon_phases.today_label') ?? 'اليوم',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontFamily: 'Almarai',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat.yMMMMd().format(info.date),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big animated moon with a soft glow ring behind it.
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.30),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  MoonDisc(
                    size: 130,
                    phaseFraction: info.phaseFraction,
                    illumination: info.illumination,
                    showCraters: true,
                    animated: true,
                  ),
                ],
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phaseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Almarai',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$illum ${l10n?.translate('moon_phases.illuminated_short') ?? 'مضاء'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    _HeroStat(
                      icon: Icons.timeline_rounded,
                      label:
                          l10n?.translate('moon_phases.moon_age') ?? 'Moon age',
                      value: formatDays(info.ageDays),
                    ),
                    const SizedBox(height: 6),
                    _HeroStat(
                      icon: Icons.straighten_rounded,
                      label:
                          l10n?.translate('moon_phases.moon_distance') ??
                          'Distance',
                      value: formatKm(info.distanceKm),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Material(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(Radii.sm),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.sm),
              onTap: onMore,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n?.translate('moon_phases.more_details') ??
                          'تفاصيل أكثر',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Almarai',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CalendarMonthHeader extends SliverPersistentHeaderDelegate {
  final DateTime viewedMonth;
  final AppLocalizations? l10n;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ThemeData theme;

  _CalendarMonthHeader({
    required this.viewedMonth,
    required this.l10n,
    required this.onPrev,
    required this.onNext,
    required this.theme,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF0B1024),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          _RoundIconButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
          Expanded(
            child: Center(
              child: Text(
                _formatMonth(viewedMonth, l10n),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Almarai',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _RoundIconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }

  String _formatMonth(DateTime d, AppLocalizations? l10n) {
    final lang = l10n?.translate('global.locale_code') ?? 'en';
    try {
      return DateFormat.yMMMM(lang == 'ar' ? 'ar' : 'en').format(d);
    } catch (_) {
      return DateFormat.yMMMM().format(d);
    }
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant _CalendarMonthHeader old) =>
      old.viewedMonth != viewedMonth;
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _WeekdaysRow extends StatelessWidget {
  final AppLocalizations? l10n;
  const _WeekdaysRow({required this.l10n});

  @override
  Widget build(BuildContext context) {
    const keys = [
      'global.sunday',
      'global.monday',
      'global.tuesday',
      'global.wednesday',
      'global.thursday',
      'global.friday',
      'global.saturday',
    ];
    const fallbacks = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: List.generate(7, (i) {
          final label = l10n?.translate(keys[i]) ?? fallbacks[i];
          final isFriday = i == 5;
          return Expanded(
            child: Center(
              child: Text(
                _shortLabel(label),
                style: TextStyle(
                  color: isFriday
                      ? Colors.amber.shade300
                      : Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _shortLabel(String full) {
    if (full.length <= 4) return full;
    return full.substring(0, 3);
  }
}

class _MoonCell extends StatelessWidget {
  final MoonPhaseInfo info;
  final bool isToday;
  final VoidCallback onTap;

  const _MoonCell({
    required this.info,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = isToday
        ? Border.all(color: theme.colorScheme.primary, width: 1.5)
        : Border.all(color: Colors.white.withValues(alpha: 0.06));

    return Material(
      color: Colors.white.withValues(alpha: 0.025),
      borderRadius: BorderRadius.circular(Radii.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.sm),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.sm),
            border: border,
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.topStart,
                child: Text(
                  '${info.date.day}',
                  style: TextStyle(
                    color: isToday ? theme.colorScheme.primary : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final dim = constraints.maxWidth < constraints.maxHeight
                        ? constraints.maxWidth
                        : constraints.maxHeight;
                    return Center(
                      child: MoonDisc(
                        size: dim * 0.85,
                        phaseFraction: info.phaseFraction,
                        illumination: info.illumination,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatPercent(info.illumination),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quiet visual break between the calendar grid and the Islamic-content
/// block underneath. Two soft glowing dashes flanking a small crescent
/// glyph — reads as an ornament, not as a UI control.
class _SectionOrnament extends StatelessWidget {
  const _SectionOrnament();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xxl,
        Spacing.lg,
        Spacing.xxl,
        Spacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _gradientLine(toLeft: true)),
          const SizedBox(width: Spacing.md),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3A6BA8).withValues(alpha: 0.18),
              border: Border.all(
                color: const Color(0xFF7BA7D9).withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.nightlight_round,
              size: 14,
              color: Color(0xFF7BA7D9),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(child: _gradientLine(toLeft: false)),
        ],
      ),
    );
  }

  Widget _gradientLine({required bool toLeft}) {
    final colors = [
      Colors.white.withValues(alpha: 0),
      const Color(0xFF7BA7D9).withValues(alpha: 0.45),
    ];
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: toLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: toLeft ? Alignment.centerLeft : Alignment.centerRight,
          colors: colors,
        ),
      ),
    );
  }
}
