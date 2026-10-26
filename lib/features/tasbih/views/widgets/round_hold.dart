import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/tasbih_cubit.dart';
import '../../cubit/tasbih_state.dart';

/// How a finished round shows itself: the progress visual holds full, with a
/// soft glow that fades over [duration], then drops back to the new round.
///
/// This replaces the old blocking dialog and the confetti. A round is a
/// moment, not an event to dismiss — the next tasbiha should be one tap away,
/// and DESIGN.md keeps reward theatrics out of worship.
///
/// Skipped entirely under reduced motion: the count simply starts again.
class RoundHold extends StatefulWidget {
  const RoundHold({super.key, required this.builder});

  /// [glow] is 1 at the moment the round completes and falls to 0; while it
  /// is above 0 the visual should read as full.
  final Widget Function(BuildContext context, double glow) builder;

  static const Duration duration = Duration(milliseconds: 450);

  @override
  State<RoundHold> createState() => _RoundHoldState();
}

class _RoundHoldState extends State<RoundHold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RoundHold.duration,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TasbihCubit, TasbihState>(
      listenWhen: (a, b) => a.completionTick != b.completionTick,
      listener: (context, _) {
        if (MediaQuery.disableAnimationsOf(context)) return;
        _controller.forward(from: 0);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => widget.builder(
          context,
          _controller.isAnimating
              ? 1 - Curves.easeIn.transform(_controller.value)
              : 0,
        ),
      ),
    );
  }
}
