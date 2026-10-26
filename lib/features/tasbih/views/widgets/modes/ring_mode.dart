import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubit/tasbih_cubit.dart';
import '../../painters/dot_ring_painter.dart';
import '../../tasbih_look.dart';
import '../round_hold.dart';
import '../tasbih_count_display.dart';

/// الحلقة: a dot for each tasbiha around the count. Counting is a tap
/// anywhere on the surface, handled by the screen.
class RingModeBody extends StatelessWidget {
  const RingModeBody({super.key, required this.look});

  final TasbihLook look;

  @override
  Widget build(BuildContext context) {
    final (count, target) = context.select<TasbihCubit, (int, int)>(
      (c) => (c.state.selected.count, c.state.selected.target),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = math.min(constraints.maxWidth * 0.8, 320.0);
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox.square(
            dimension: diameter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: RoundHold(
                      builder: (context, glow) => CustomPaint(
                        painter: DotRingPainter(
                          count: count,
                          target: target,
                          // Dark surfaces swallow a translucent accent; lift it there.
                          countedColor: look.accent.withValues(
                            alpha: look.isDark ? 0.7 : 0.55,
                          ),
                          currentColor: look.accent,
                          restColor: look.neutral.withValues(alpha: 0.12),
                          holdingFull: glow > 0,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: diameter * 0.64,
                  height: diameter * 0.64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: look.isDark
                        ? look.accent.withValues(alpha: 0.08)
                        : look.primary.withValues(alpha: 0.06),
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: TasbihCountDisplay(
                      count: count,
                      target: target,
                      color: look.ink,
                      mutedColor: look.muted,
                      fontSize: 72,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
