import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

import '../../data/moon_phase.dart';
import '../widgets/moon_islamic_context.dart';
import '../widgets/moon_painter.dart';
import '../widgets/moon_phase_labels.dart';

/// Detail screen for a specific date's moon phase. Inspired by the reference
/// screenshots: a horizontally-scrolling 5-day strip at the top, a large
/// moon visualisation in the middle, and an info table at the bottom.
class MoonPhaseDetailScreen extends StatefulWidget {
  final DateTime initialDate;

  const MoonPhaseDetailScreen({super.key, required this.initialDate});

  @override
  State<MoonPhaseDetailScreen> createState() => _MoonPhaseDetailScreenState();
}

class _MoonPhaseDetailScreenState extends State<MoonPhaseDetailScreen> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected =
        DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final info = MoonPhaseCalculator.forDate(_selected);

    return Scaffold(
      // Brand-derived night-sky surface (same value used by the floating
      // dhikr settings + onboarding for dark mode) so all "dark"
      // surfaces in the app feel like one family.
      backgroundColor: const Color(0xFF0F1A2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          l10n?.translate('moon_phases.title') ?? 'Moon phases',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _DateStrip(
            selected: _selected,
            onSelect: (d) => setState(() => _selected = d),
          ),
          const SizedBox(height: Spacing.lg),
          _PhaseHeader(info: info, l10n: l10n),
          const SizedBox(height: Spacing.xl),
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow halo behind the moon — animated breathing pulse so
                  // the hero feels alive without being noisy.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 4),
                    curve: Curves.easeInOut,
                    onEnd: () {},
                    builder: (context, t, child) {
                      final pulse = (1 + 0.04 * t).clamp(1.0, 1.06);
                      return Transform.scale(
                        scale: pulse,
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.22),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Big animated moon (breathing + slow highlight rotation).
                  MoonDisc(
                    size: 200,
                    phaseFraction: info.phaseFraction,
                    illumination: info.illumination,
                    showCraters: true,
                    animated: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          _MoreInfo(info: info, l10n: l10n),
          const SizedBox(height: Spacing.xl),
          _NextCycleChart(info: info, l10n: l10n),
          // Hilāl sighting tips — only rendered for new-moon and waxing-
          // crescent phases, where the user might actually be trying to
          // sight the crescent. For other phases the section is skipped
          // entirely so the screen stays focused.
          if (shouldShowCrescentSighting(info.phase)) ...[
            const SizedBox(height: Spacing.xl),
            CrescentSightingCard(info: info, l10n: l10n),
          ],
          const SizedBox(height: Spacing.xl),
          MoonIslamicContext(l10n: l10n),
          const SizedBox(height: Spacing.xxl),
        ],
      ),
    );
  }
}

class _DateStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const _DateStrip({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    // 5-day strip centred on the selected date.
    final days = List<DateTime>.generate(
      5,
      (i) => selected.add(Duration(days: i - 2)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((d) {
          final isSelected = d.year == selected.year &&
              d.month == selected.month &&
              d.day == selected.day;
          return _DateChip(
            date: d,
            selected: isSelected,
            onTap: () => onSelect(d),
          );
        }).toList(),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weekday = DateFormat.E().format(date).toUpperCase();
    final day = DateFormat.MMMd().format(date);
    final color = selected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.55);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Text(
            weekday,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 28 : 0,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseHeader extends StatelessWidget {
  final MoonPhaseInfo info;
  final AppLocalizations? l10n;

  const _PhaseHeader({required this.info, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        children: [
          Text(
            '${MoonPhaseLabels.phaseName(info.phase, l10n)} '
            '(${formatPercent(info.illumination)})',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            _descriptionFor(info, l10n),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _descriptionFor(MoonPhaseInfo info, AppLocalizations? l10n) {
    final key = switch (info.phase) {
      MoonPhase.newMoon => 'moon_phases.desc_new_moon',
      MoonPhase.waxingCrescent => 'moon_phases.desc_waxing_crescent',
      MoonPhase.firstQuarter => 'moon_phases.desc_first_quarter',
      MoonPhase.waxingGibbous => 'moon_phases.desc_waxing_gibbous',
      MoonPhase.fullMoon => 'moon_phases.desc_full_moon',
      MoonPhase.waningGibbous => 'moon_phases.desc_waning_gibbous',
      MoonPhase.lastQuarter => 'moon_phases.desc_last_quarter',
      MoonPhase.waningCrescent => 'moon_phases.desc_waning_crescent',
    };
    final fallback = switch (info.phase) {
      MoonPhase.newMoon =>
        'The moon is not visible — Hilal sighting begins after sunset.',
      MoonPhase.waxingCrescent =>
        'A thin crescent appears in the western sky after sunset.',
      MoonPhase.firstQuarter =>
        'Half the moon is illuminated. Visible in the afternoon and evening.',
      MoonPhase.waxingGibbous =>
        'More than half lit — the moon rises before sunset.',
      MoonPhase.fullMoon =>
        'The full disc is illuminated and visible all night.',
      MoonPhase.waningGibbous =>
        'More than half lit but shrinking — the moon rises after sunset.',
      MoonPhase.lastQuarter =>
        'Half the moon is illuminated. Visible from midnight to morning.',
      MoonPhase.waningCrescent =>
        'A thin crescent in the eastern sky before sunrise.',
    };
    return l10n?.translate(key) ?? fallback;
  }
}

class _MoreInfo extends StatelessWidget {
  final MoonPhaseInfo info;
  final AppLocalizations? l10n;

  const _MoreInfo({required this.info, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n?.translate('moon_phases.more_info') ??
                'More information (at midnight)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Spacing.md),
          _InfoRow(
            label: l10n?.translate('moon_phases.moon_distance') ??
                'Moon distance',
            value: formatKm(info.distanceKm),
          ),
          _InfoRow(
            label: l10n?.translate('moon_phases.moon_age') ?? 'Moon age',
            value: formatDays(info.ageDays),
          ),
          _InfoRow(
            label: l10n?.translate('moon_phases.illumination') ?? 'Illumination',
            value: formatPercent(info.illumination),
          ),
          _InfoRow(
            label: l10n?.translate('moon_phases.ecliptic_longitude') ??
                'Ecliptic longitude',
            value: '${info.eclipticLongitude.toStringAsFixed(2)}°',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sparkline of illumination over the next full lunar cycle (~30 days).
/// Animated stroke + filled area give a calm "drawing in" feel matching
/// the rest of the screen's motion design.
class _NextCycleChart extends StatefulWidget {
  final MoonPhaseInfo info;
  final AppLocalizations? l10n;

  const _NextCycleChart({required this.info, required this.l10n});

  @override
  State<_NextCycleChart> createState() => _NextCycleChartState();
}

class _NextCycleChartState extends State<_NextCycleChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw;
  late List<double> _points;
  DateTime? _lastDate;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _points = _buildPoints(widget.info.date);
    _lastDate = widget.info.date;
    WidgetsBinding.instance.addPostFrameCallback((_) => _draw.forward());
  }

  @override
  void didUpdateWidget(covariant _NextCycleChart old) {
    super.didUpdateWidget(old);
    if (widget.info.date != _lastDate) {
      _points = _buildPoints(widget.info.date);
      _lastDate = widget.info.date;
      _draw
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  List<double> _buildPoints(DateTime from) {
    return List<double>.generate(30, (i) {
      final f = MoonPhaseCalculator.forDate(from.add(Duration(days: i)));
      return f.illumination;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        children: [
          Text(
            widget.l10n?.translate('moon_phases.next_cycle') ?? 'Next cycle',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Spacing.md),
          SizedBox(
            height: 140,
            child: AnimatedBuilder(
              animation: _draw,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size.fromHeight(140),
                  painter: _SparklinePainter(
                    points: _points,
                    progress: Curves.easeOutCubic.transform(_draw.value),
                    accent: theme.colorScheme.primary,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;

  /// 0..1 — how much of the line should be drawn. Drives the entrance
  /// animation when the screen first appears.
  final double progress;

  final Color accent;

  _SparklinePainter({
    required this.points,
    required this.progress,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Y-axis labels
    final textStyle = const TextStyle(color: Colors.white54, fontSize: 11);
    final tps = ['100%', '50%', '0%']
        .map((t) => TextPainter(
              text: TextSpan(text: t, style: textStyle),
              textDirection: ui.TextDirection.ltr,
            )
              ..layout())
        .toList();
    for (int i = 0; i < tps.length; i++) {
      final y = size.height * (i / 2);
      tps[i].paint(canvas, Offset(0, y - tps[i].height / 2));
    }

    final left = 44.0;
    final right = size.width;
    final top = 8.0;
    final bottom = size.height - 16;

    // Full geometry — we draw a partial portion based on `progress`.
    final totalCount = points.length;
    final shownCount = (1 + (totalCount - 1) * progress).clamp(1, totalCount);
    final shownInt = shownCount.floor();
    final remainder = shownCount - shownInt;

    final path = Path();
    Offset? lastOffset;
    for (int i = 0; i < shownInt; i++) {
      final x = left + (right - left) * (i / (totalCount - 1));
      final y = bottom - (bottom - top) * points[i];
      final p = Offset(x, y);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
      lastOffset = p;
    }
    // Partial segment to the next point (so animation looks smooth).
    if (shownInt > 0 && shownInt < totalCount && remainder > 0) {
      final i0 = shownInt - 1;
      final i1 = shownInt;
      final x0 = left + (right - left) * (i0 / (totalCount - 1));
      final y0 = bottom - (bottom - top) * points[i0];
      final x1 = left + (right - left) * (i1 / (totalCount - 1));
      final y1 = bottom - (bottom - top) * points[i1];
      final px = x0 + (x1 - x0) * remainder;
      final py = y0 + (y1 - y0) * remainder;
      path.lineTo(px, py);
      lastOffset = Offset(px, py);
    }

    // Fill under the line — soft gradient so the chart reads less as a
    // graph and more as a poetic representation of the lunar cycle.
    if (lastOffset != null && shownInt > 1) {
      final fillPath = Path.from(path)
        ..lineTo(lastOffset.dx, bottom)
        ..lineTo(left, bottom)
        ..close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.28),
            accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTRB(left, top, right, bottom));
      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Marker on today's position (always shown so the user has a reference).
    final firstX = left;
    final firstY = bottom - (bottom - top) * points.first;
    canvas.drawCircle(Offset(firstX, firstY), 5, Paint()..color = accent);
    canvas.drawCircle(
      Offset(firstX, firstY),
      5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.points != points ||
      old.progress != progress ||
      old.accent != accent;
}
