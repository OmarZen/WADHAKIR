import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'beads_layout.dart';

/// Paints [BeadsLayout]. Repaints from [phase] directly, so a drag redraws
/// only this painter and never rebuilds a widget.
class BeadsPainter extends CustomPainter {
  BeadsPainter({
    required this.phase,
    required this.direction,
    required this.counted,
    required this.remaining,
    required this.accent,
    required this.neutral,
    required this.background,
    this.countedAlpha = 0.35,
    this.holdingFull = false,
  }) : super(repaint: phase);

  final ValueListenable<double> phase;
  final TextDirection direction;
  final int counted;
  final int remaining;
  final Color accent;
  final Color neutral;
  final Color background;

  /// How strongly a counted bead shows. Higher on dark surfaces, which
  /// swallow a translucent accent.
  final double countedAlpha;

  /// A finished round: every bead on the string lit for a moment.
  final bool holdingFull;

  BeadsLayout? _layout;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final layout = _layout?.size == size && _layout?.direction == direction
        ? _layout!
        : (_layout = BeadsLayout(size: size, direction: direction));

    final string = Path()..addPolygon(layout.stringPoints(), false);
    canvas.drawPath(
      string,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = neutral.withValues(alpha: 0.22),
    );

    final counted = Paint()..color = accent.withValues(alpha: countedAlpha);
    final rest = Paint()..color = neutral.withValues(alpha: 0.14);
    final full = Paint()..color = accent.withValues(alpha: 0.55);

    for (final bead in layout.beads(
      counted: holdingFull ? BeadsLayout.maxPerSide : this.counted,
      remaining: remaining,
      phase: phase.value,
    )) {
      switch (bead.kind) {
        case BeadKind.counted:
          canvas.drawCircle(
            bead.center,
            bead.radius,
            holdingFull ? full : counted,
          );
        case BeadKind.remaining:
          canvas.drawCircle(bead.center, bead.radius, rest);
        case BeadKind.active:
          // The One Glow element: the bead under the thumb.
          canvas.drawCircle(
            bead.center.translate(0, bead.radius * 0.25),
            bead.radius * 1.35,
            Paint()
              ..color = accent.withValues(alpha: 0.35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
          );
          canvas.drawCircle(bead.center, bead.radius, Paint()..color = accent);
          canvas.drawCircle(
            bead.center,
            bead.radius,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..color = background,
          );
      }
    }
  }

  @override
  bool shouldRepaint(BeadsPainter old) =>
      old.phase != phase ||
      old.direction != direction ||
      old.counted != counted ||
      old.remaining != remaining ||
      old.accent != accent ||
      old.neutral != neutral ||
      old.background != background ||
      old.countedAlpha != countedAlpha ||
      old.holdingFull != holdingFull;
}
