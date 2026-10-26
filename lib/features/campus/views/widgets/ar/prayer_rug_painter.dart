import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wadhakir/features/campus/ar/rug_projection.dart';

/// The virtual prayer rug: a plain rug with an inner border and a mihrab
/// arch at its qibla end, drawn in perspective on the camera picture.
///
/// Painted inside the same `FittedBox(cover)` child as the camera preview,
/// so [RugProjector]'s viewport is the preview frame and the rug lands on
/// the same pixels as the floor, whatever the screen's aspect ratio.
///
/// Not facing the qibla: an outline at the accent's 60% on an 8% wash, so
/// the floor stays visible through it. Facing it: filled at 85% with the
/// screen's one glow.
class PrayerRugPainter extends CustomPainter {
  final double pitchDegrees;
  final double rollDegrees;

  /// The qibla relative to the camera, positive clockwise; the rug turns
  /// by this much.
  final double yawDegrees;
  final bool aligned;
  final Color color;
  final RugGeometry geometry;

  const PrayerRugPainter({
    required this.pitchDegrees,
    required this.rollDegrees,
    required this.yawDegrees,
    required this.aligned,
    required this.color,
    this.geometry = const RugGeometry(),
  });

  /// How far the inner border sits inside the edge, metres.
  static const double _borderInset = 0.06;

  @override
  void paint(Canvas canvas, Size size) {
    final projector = RugProjector(
      viewport: size,
      pitchDegrees: pitchDegrees,
      yawDegrees: yawDegrees,
      rollDegrees: rollDegrees,
      geometry: geometry,
    );
    final outline = projector.outline;
    if (outline.length < 3) return;
    final rug = _closed(outline);

    if (aligned) {
      canvas.drawPath(
        rug,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }
    canvas.drawPath(
      rug,
      Paint()..color = color.withValues(alpha: aligned ? 0.85 : 0.08),
    );

    // A thin dark halo under every line keeps it readable on a pale floor.
    final halo = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeJoin = StrokeJoin.round;
    final line = Paint()
      ..color = aligned
          ? Colors.white.withValues(alpha: 0.8)
          : color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    final detail = Paint()
      ..color = aligned
          ? Colors.white.withValues(alpha: 0.6)
          : color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    if (!aligned) canvas.drawPath(rug, halo);
    canvas.drawPath(rug, line);

    final inner = projector.projectPolygon(_innerBorder());
    if (inner.length >= 3) canvas.drawPath(_closed(inner), detail);

    final arch = projector.projectPolygon(_mihrab());
    if (arch.length >= 3) canvas.drawPath(_closed(arch), detail);
  }

  Path _closed(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  List<Offset> _innerBorder() {
    final hw = geometry.widthM / 2 - _borderInset;
    final hl = geometry.lengthM / 2 - _borderInset;
    return [Offset(-hw, -hl), Offset(hw, -hl), Offset(hw, hl), Offset(-hw, hl)];
  }

  /// A pointed arch at the qibla end, in rug-local metres (+y toward the
  /// qibla), densified so it stays curved in perspective.
  List<Offset> _mihrab() {
    final top = geometry.lengthM / 2 - _borderInset - 0.06;
    final base = top - geometry.lengthM * 0.36;
    final hw = geometry.widthM / 2 - _borderInset - 0.08;
    final shoulder = base + (top - base) * 0.45;
    const steps = 14;
    final points = <Offset>[Offset(-hw, base), Offset(-hw, shoulder)];
    // A two-centred (pointed) arch: each side is an arc of radius 2·hw
    // centred on the opposite side, which meets its twin at 60° in a point.
    // The height is then scaled to fit the rug.
    const sweep = math.pi / 3;
    final rise = top - shoulder;
    Offset side(double theta, double sign) => Offset(
      sign * (hw - 2 * hw * math.cos(theta)),
      shoulder + rise * math.sin(theta) / math.sin(sweep),
    );
    for (var i = 1; i <= steps; i++) {
      points.add(side(i / steps * sweep, 1));
    }
    for (var i = steps - 1; i >= 0; i--) {
      points.add(side(i / steps * sweep, -1));
    }
    points.add(Offset(hw, base));
    return points;
  }

  @override
  bool shouldRepaint(PrayerRugPainter old) =>
      old.pitchDegrees != pitchDegrees ||
      old.rollDegrees != rollDegrees ||
      old.yawDegrees != yawDegrees ||
      old.aligned != aligned ||
      old.color != color ||
      old.geometry != geometry;
}

/// The curved "turn this way" arrow above the rug. [right] is PHYSICAL: it
/// is never mirrored for right-to-left text, because the user turns their
/// body, not the page.
class QiblaTurnArrowPainter extends CustomPainter {
  final bool right;
  final Color color;

  const QiblaTurnArrowPainter({required this.right, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final start = Offset(right ? w * 0.08 : w * 0.92, h * 0.85);
    final end = Offset(right ? w * 0.86 : w * 0.14, h * 0.45);
    final control = Offset(w * 0.5, -h * 0.25);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, shadow);
    canvas.drawPath(path, stroke);

    // Arrowhead along the curve's final tangent.
    final tangent = end - control;
    final angle = math.atan2(tangent.dy, tangent.dx);
    const headLength = 14.0;
    final head = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - headLength * math.cos(angle - 0.5),
        end.dy - headLength * math.sin(angle - 0.5),
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - headLength * math.cos(angle + 0.5),
        end.dy - headLength * math.sin(angle + 0.5),
      );
    canvas.drawPath(head, shadow);
    canvas.drawPath(head, stroke);
  }

  @override
  bool shouldRepaint(QiblaTurnArrowPainter old) =>
      old.right != right || old.color != color;
}
