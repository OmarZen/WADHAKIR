import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:wadhakir/core/design/design_tokens.dart';

import '../../../cubit/tasbih_cubit.dart';
import '../../painters/progress_ring_painter.dart';
import '../../tasbih_look.dart';
import '../../tasbih_strings.dart';
import '../round_hold.dart';
import '../tasbih_count_display.dart';

/// النقر: the count, and under it one large button ringed by the round's
/// progress.
///
/// On a short screen (a small phone at a large text size) there is not room
/// for both at a size worth tapping, so the count moves inside the button
/// rather than shrinking everything to a thumbnail.
class TapModeBody extends StatelessWidget {
  const TapModeBody({super.key, required this.look});

  final TasbihLook look;

  /// The smallest button that still reads as the thing to press.
  static const double minButton = 168;

  @override
  Widget build(BuildContext context) {
    final (count, target) = context.select<TasbihCubit, (int, int)>(
      (c) => (c.state.selected.count, c.state.selected.target),
    );
    final progress = target == 0 ? 0.0 : count / target;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = math.min(constraints.maxWidth * 0.62, 280.0);
        final room =
            constraints.maxHeight -
            TasbihCountDisplay.heightFor(context) -
            Spacing.lg;

        // FittedBox in both: anything that still does not fit is scaled down
        // as one piece rather than overflowing.
        if (room >= minButton) {
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
                ),
                const SizedBox(height: Spacing.lg),
                _TapButton(
                  diameter: math.min(wide, room),
                  progress: progress,
                  look: look,
                ),
              ],
            ),
          );
        }
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: _TapButton(
            diameter: math.min(
              wide,
              math.max(constraints.maxHeight, minButton),
            ),
            progress: progress,
            look: look,
            center: TasbihCountDisplay(
              count: count,
              target: target,
              color: look.ink,
              mutedColor: look.muted,
              fontSize: 56,
            ),
          ),
        );
      },
    );
  }
}

class _TapButton extends StatefulWidget {
  const _TapButton({
    required this.diameter,
    required this.progress,
    required this.look,
    this.center,
  });

  final double diameter;
  final double progress;
  final TasbihLook look;

  /// In place of the icon and «اضغط للعدّ»: the compact layout's count.
  final Widget? center;

  @override
  State<_TapButton> createState() => _TapButtonState();
}

class _TapButtonState extends State<_TapButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.look;
    final cubit = context.read<TasbihCubit>();
    final reduce = MediaQuery.disableAnimationsOf(context);
    final label = TasbihStrings.tr(context, 'tasbih.tap_button');
    const ringStroke = 8.0;
    final inner = widget.diameter - 2 * (ringStroke + 18);

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.diameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: RoundHold(
                builder: (context, glow) => CustomPaint(
                  painter: ProgressRingPainter(
                    progress: glow > 0 ? 1 : widget.progress,
                    trackColor: look.neutral.withValues(alpha: 0.08),
                    arcColor: look.accent,
                    strokeWidth: ringStroke,
                    glow: glow,
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: label,
              onTap: cubit.increment,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _setPressed(true),
                onTapUp: (_) => _setPressed(false),
                onTapCancel: () => _setPressed(false),
                onTap: cubit.increment,
                child: AnimatedScale(
                  scale: _pressed ? 0.96 : 1,
                  duration: reduce ? Duration.zero : Motion.fast,
                  curve: Motion.standard,
                  child: Container(
                    width: inner,
                    height: inner,
                    decoration: BoxDecoration(
                      color: look.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: look.neutral.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: widget.center != null
                        ? Padding(
                            padding: const EdgeInsets.all(Spacing.lg),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: widget.center,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedTasbih,
                                color: look.accent,
                                size: inner * 0.26,
                              ),
                              const SizedBox(height: Spacing.sm),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontFamily: TasbihLook.uiFont,
                                      color: look.muted,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
