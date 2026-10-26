import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/design/design_tokens.dart';

import '../../../cubit/tasbih_cubit.dart';
import '../../tasbih_look.dart';
import '../../tasbih_strings.dart';
import '../round_hold.dart';
import '../tasbih_count_display.dart';

/// التركيز: a dark, quiet screen with one large number and a thin bar, for
/// long counts with the phone set down. A tap anywhere counts (handled by the
/// screen), and the screen is held on whatever the setting says.
class FocusModeBody extends StatelessWidget {
  const FocusModeBody({super.key, required this.look});

  final TasbihLook look;

  @override
  Widget build(BuildContext context) {
    final (count, target) = context.select<TasbihCubit, (int, int)>(
      (c) => (c.state.selected.count, c.state.selected.target),
    );
    final progress = target == 0 ? 0.0 : (count / target).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = math.min(constraints.maxWidth * 0.62, 280.0);
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TasbihCountDisplay(
                count: count,
                target: target,
                color: look.ink,
                mutedColor: look.muted,
                fontSize: 150,
                showOf: false,
              ),
              const SizedBox(height: Spacing.xl),
              RoundHold(
                builder: (context, glow) => _Bar(
                  width: barWidth,
                  progress: glow > 0 ? 1 : progress,
                  look: look,
                ),
              ),
              const SizedBox(height: Spacing.md),
              // The number above already reads «21 من 33» to TalkBack.
              ExcludeSemantics(
                child: Text(
                  TasbihStrings.tr(context, 'tasbih.count_of', {
                    'count': count,
                    'n': target,
                  }),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: TasbihLook.uiFont,
                    color: look.muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.progress, required this.look});

  final double width;
  final double progress;
  final TasbihLook look;

  @override
  Widget build(BuildContext context) {
    // Fills from the reading start: right to left in Arabic, like a line of
    // text being read.
    return SizedBox(
      width: width,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: Radii.pillBorder,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: progress,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: look.accent,
                borderRadius: Radii.pillBorder,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
