import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/design/design_tokens.dart';

import '../../../cubit/tasbih_cubit.dart';
import '../../painters/beads_layout.dart';
import '../../painters/beads_painter.dart';
import '../../tasbih_look.dart';
import '../../tasbih_strings.dart';
import '../round_hold.dart';
import '../tasbih_count_display.dart';

/// الحبات: a string of beads to pull, one bead per tasbiha.
class BeadsModeBody extends StatelessWidget {
  const BeadsModeBody({super.key, required this.look, this.compact = false});

  final TasbihLook look;

  /// A short screen. The string hangs in a V from beyond both edges, so the
  /// top of the V is empty: the count moves in there, and the direction pill
  /// gives way to the subtitle (which then names the direction itself), so
  /// the string keeps room to hang.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (count, target) = context.select<TasbihCubit, (int, int)>(
      (c) => (c.state.selected.count, c.state.selected.target),
    );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final beads = BeadsArea(count: count, target: target, look: look);

    if (compact) {
      return LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(child: beads),
            Align(
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                child: SizedBox(
                  height: math.min(
                    TasbihCountDisplay.heightFor(context, fontSize: 56),
                    constraints.maxHeight * 0.6,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: TasbihCountDisplay(
                      count: count,
                      target: target,
                      color: look.ink,
                      mutedColor: look.muted,
                      fontSize: 56,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          SizedBox(
            height: math.min(
              TasbihCountDisplay.heightFor(context),
              constraints.maxHeight * 0.42,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: TasbihCountDisplay(
                count: count,
                target: target,
                color: look.ink,
                mutedColor: look.muted,
              ),
            ),
          ),
          Expanded(child: beads),
          const SizedBox(height: Spacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: _DirectionHint(rtl: rtl, look: look),
          ),
        ],
      ),
    );
  }
}

/// «اسحب الحبة لليسار للعدّ ←». The arrow is `arrow_forward_rounded`, which
/// mirrors itself, so it points left in Arabic without a special case.
class _DirectionHint extends StatelessWidget {
  const _DirectionHint({required this.rtl, required this.look});

  final bool rtl;
  final TasbihLook look;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: look.neutral.withValues(alpha: 0.06),
          borderRadius: Radii.pillBorder,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TasbihStrings.tr(
                  context,
                  rtl ? 'tasbih.drag_hint_rtl' : 'tasbih.drag_hint_ltr',
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: look.muted),
              ),
              const SizedBox(width: Spacing.sm),
              Icon(Icons.arrow_forward_rounded, size: 18, color: look.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// The string itself, and the gestures on it.
///
/// * A horizontal drag in the forward direction pulls beads: one per
///   [BeadsLayout.dragPitch], and on release a bead past half way finishes.
///   Dragging back undoes only an unfinished bead.
/// * A tap anywhere on the string also counts one, so nobody who cannot drag
///   is locked out of the mode.
/// * The gesture zone stops 24 dp short of either edge, where Android's
///   gesture navigation reads a horizontal swipe as Back.
/// * TalkBack gets a tap and an increase action, one tasbiha each, and no
///   scroll actions.
class BeadsArea extends StatefulWidget {
  const BeadsArea({
    super.key,
    required this.count,
    required this.target,
    required this.look,
  });

  final int count;
  final int target;
  final TasbihLook look;

  /// Kept clear of the screen edges; see the class comment.
  static const double edgeMargin = 24;

  @override
  State<BeadsArea> createState() => _BeadsAreaState();
}

class _BeadsAreaState extends State<BeadsArea>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _phase = ValueNotifier(0);
  late final AnimationController _spring = AnimationController(
    vsync: this,
    duration: Motion.base,
  )..addListener(_onSpring);
  double _springFrom = 0;
  BeadDragTracker? _tracker;

  @override
  void dispose() {
    _spring.dispose();
    _phase.dispose();
    super.dispose();
  }

  void _onSpring() {
    _phase.value = _springFrom * (1 - Motion.standard.transform(_spring.value));
  }

  void _count(int n) {
    final cubit = context.read<TasbihCubit>();
    for (var i = 0; i < n; i++) {
      cubit.increment();
    }
  }

  void _onDragStart(BeadsLayout layout) {
    _spring.stop();
    _tracker = BeadDragTracker(
      pitch: layout.dragPitch,
      forwardSign: layout.forwardSign,
    );
    _phase.value = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final tracker = _tracker;
    if (tracker == null) return;
    _count(tracker.update(details.delta.dx));
    _phase.value = tracker.phase;
  }

  void _onDragEnd() {
    final tracker = _tracker;
    _tracker = null;
    if (tracker == null) return;
    final finished = tracker.release();
    if (finished > 0) {
      // The bead is counted, and the new layout already shows it on the
      // counted side: no spring.
      _count(finished);
      _phase.value = 0;
      return;
    }
    if (MediaQuery.disableAnimationsOf(context) || _phase.value == 0) {
      _phase.value = 0;
      return;
    }
    _springFrom = _phase.value;
    _spring.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.look;
    final direction = Directionality.of(context);
    final cubit = context.read<TasbihCubit>();
    String countOf(int c) => TasbihStrings.tr(context, 'tasbih.count_of', {
      'count': c,
      'n': widget.target,
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = BeadsLayout(
          size: constraints.biggest,
          direction: direction,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: RoundHold(
                  builder: (context, glow) => CustomPaint(
                    painter: BeadsPainter(
                      phase: _phase,
                      direction: direction,
                      counted: widget.count,
                      remaining: math.max(widget.target - widget.count - 1, 0),
                      accent: look.accent,
                      neutral: look.neutral,
                      background: look.background,
                      countedAlpha: look.isDark ? 0.5 : 0.35,
                      holdingFull: glow > 0,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              left: BeadsArea.edgeMargin,
              right: BeadsArea.edgeMargin,
              child: Semantics(
                container: true,
                label: TasbihStrings.tr(context, 'tasbih.hint_drag'),
                value: countOf(widget.count),
                increasedValue: countOf((widget.count + 1) % widget.target),
                onTap: cubit.increment,
                onIncrease: cubit.increment,
                // The Semantics above already gives tap and increase. Left
                // to itself, the detector would lay a second, unlabelled
                // node over the string (its tap clashes with this one) with
                // scrollLeft/scrollRight for the drag, each performed as a
                // fake drag of 0.8 × the width: about seven beads at once.
                // That node is the one TalkBack's touch lands on, and
                // Android sends its scroll-forward gesture to scrollLeft.
                child: GestureDetector(
                  excludeFromSemantics: true,
                  behavior: HitTestBehavior.opaque,
                  onTap: cubit.increment,
                  onHorizontalDragStart: (_) => _onDragStart(layout),
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: (_) => _onDragEnd(),
                  onHorizontalDragCancel: _onDragEnd,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
