import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/design_tokens.dart';

import '../tasbih_look.dart';
import '../tasbih_strings.dart';

/// The big number, with «من 33» under it.
///
/// Tabular figures, so the number does not shuffle sideways as digits change
/// under a fast thumb. It is already large, so the reader's text scale is
/// capped at 1.2 here; at 1.6 an 80 pt figure would push the counting surface
/// off a small phone.
class TasbihCountDisplay extends StatefulWidget {
  const TasbihCountDisplay({
    super.key,
    required this.count,
    required this.target,
    required this.color,
    required this.mutedColor,
    this.fontSize = 80,
    this.showOf = true,
  });

  final int count;
  final int target;
  final Color color;
  final Color mutedColor;
  final double fontSize;

  /// «من 33» under the number. Focus mode shows its own line instead.
  final bool showOf;

  /// The text scale this widget is drawn at: the reader's, capped at 1.2.
  static TextScaler scalerOf(BuildContext context) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2);

  /// A generous estimate of the height this display takes, for layouts that
  /// must decide what fits before laying it out.
  static double heightFor(
    BuildContext context, {
    double fontSize = 80,
    bool showOf = true,
  }) {
    final s = scalerOf(context);
    return s.scale(fontSize) * 1.1 + (showOf ? s.scale(16) * 1.6 : 0);
  }

  @override
  State<TasbihCountDisplay> createState() => _TasbihCountDisplayState();
}

class _TasbihCountDisplayState extends State<TasbihCountDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Motion.fast,
  );

  @override
  void didUpdateWidget(TasbihCountDisplay old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count && !MediaQuery.disableAnimationsOf(context)) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = Text(
      '${widget.count}',
      textDirection: TextDirection.ltr,
      style: theme.textTheme.displayLarge?.copyWith(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -1,
        color: widget.color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    return Semantics(
      container: true,
      label: TasbihStrings.tr(context, 'tasbih.count_of', {
        'count': widget.count,
        'n': widget.target,
      }),
      child: ExcludeSemantics(
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                // Up to 1.06 and back within one Motion.fast beat.
                builder: (context, child) => Transform.scale(
                  scale: 1 + 0.06 * (1 - (2 * _pulse.value - 1).abs()),
                  child: child,
                ),
                child: number,
              ),
              if (widget.showOf)
                Text(
                  TasbihStrings.tr(context, 'tasbih.of_n', {
                    'n': widget.target,
                  }),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: TasbihLook.uiFont,
                    color: widget.mutedColor,
                    fontWeight: FontWeight.w400,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
