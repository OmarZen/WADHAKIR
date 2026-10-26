import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Where things sit on a [size]-wide dial: degree labels on an outer band,
/// the face disk inside it, ticks and the qibla arc on the face's rim.
@immutable
class QiblaDialGeometry {
  final double size;

  /// Text scale for the dial's own labels, already clamped by the caller:
  /// the band they live in is fixed, so they can grow only a little.
  final double labelScale;

  const QiblaDialGeometry(this.size, this.labelScale);

  double get radius => size / 2;
  Offset get center => Offset(radius, radius);

  /// The band outside the face that holds "30°", "ش" …
  double get labelBand => 22 * labelScale;
  double get labelRadius => radius - labelBand / 2;
  double get faceRadius => radius - labelBand - 2;

  /// The qibla arc and the Kaaba chip ride on this ring, just inside the rim.
  double get rimRadius => faceRadius - 4;

  /// The Kaaba / sun / moon chips.
  double get chipSize => (size * 0.13).clamp(30.0, 40.0);

  @override
  bool operator ==(Object other) =>
      other is QiblaDialGeometry &&
      other.size == size &&
      other.labelScale == labelScale;

  @override
  int get hashCode => Object.hash(size, labelScale);
}

/// Unit vector for a bearing drawn clockwise from the top of the screen.
Offset _polar(double degrees, double r) {
  final a = degrees * math.pi / 180;
  return Offset(math.sin(a) * r, -math.cos(a) * r);
}

/// The face disk, which does not turn: surface fill, ambient shadow, a
/// hairline rim, and (compass only) the index mark at the top that says
/// "the phone points here".
class QiblaDialDiskPainter extends CustomPainter {
  final QiblaDialGeometry geometry;
  final Color fill;
  final Color rim;
  final Color shadow;
  final Color? indexColor;

  const QiblaDialDiskPainter({
    required this.geometry,
    required this.fill,
    required this.rim,
    required this.shadow,
    this.indexColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = geometry.center;
    final r = geometry.faceRadius;
    canvas.drawCircle(
      c.translate(0, 2),
      r,
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(c, r, Paint()..color = fill);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..color = rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final index = indexColor;
    if (index != null) {
      canvas.drawLine(
        c + _polar(0, r + 1),
        c + _polar(0, r - 14),
        Paint()
          ..color = index
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(QiblaDialDiskPainter old) =>
      old.geometry != geometry ||
      old.fill != fill ||
      old.rim != rim ||
      old.shadow != shadow ||
      old.indexColor != indexColor;
}

/// The compass card: ticks every 5°, degree labels every 30° and the four
/// cardinals, laid out with north at the top. It never repaints when the
/// heading changes; the dial turns it with a transform instead, so a live
/// compass costs a compositing step per sensor update, not a repaint of
/// twelve text layouts.
class QiblaDialFacePainter extends CustomPainter {
  final QiblaDialGeometry geometry;

  /// N, E, S, W in the UI language.
  final List<String> cardinals;
  final Color tick;
  final Color label;
  final Color cardinal;
  final Color north;

  const QiblaDialFacePainter({
    required this.geometry,
    required this.cardinals,
    required this.tick,
    required this.label,
    required this.cardinal,
    required this.north,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = geometry.center;
    final outer = geometry.faceRadius - 6;
    final minor = Paint()
      ..color = tick.withValues(alpha: tick.a * 0.6)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final major = Paint()
      ..color = tick
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final northTick = Paint()
      ..color = north
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (var d = 0; d < 360; d += 5) {
      final isThirty = d % 30 == 0;
      final isFifteen = d % 15 == 0;
      final length = isThirty ? 10.0 : (isFifteen ? 7.0 : 4.0);
      canvas.drawLine(
        c + _polar(d.toDouble(), outer),
        c + _polar(d.toDouble(), outer - length),
        d == 0 ? northTick : (isFifteen ? major : minor),
      );
    }

    for (var d = 0; d < 360; d += 30) {
      final isCardinal = d % 90 == 0;
      final text = isCardinal ? cardinals[d ~/ 90] : '$d°';
      final style = TextStyle(
        fontFamily: 'Almarai',
        fontSize: (isCardinal ? 13 : 10) * geometry.labelScale,
        fontWeight: isCardinal ? FontWeight.w700 : FontWeight.w400,
        color: d == 0 ? north : (isCardinal ? cardinal : label),
      );
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      // Tangential, top of the glyphs outward, the way a compass card is
      // printed; the card then turns as one piece.
      canvas.save();
      canvas.translate(
        c.dx + _polar(d.toDouble(), geometry.labelRadius).dx,
        c.dy + _polar(d.toDouble(), geometry.labelRadius).dy,
      );
      canvas.rotate(d * math.pi / 180);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(QiblaDialFacePainter old) =>
      old.geometry != geometry ||
      old.tick != tick ||
      old.label != label ||
      old.cardinal != cardinal ||
      old.north != north ||
      !_sameList(old.cardinals, cardinals);

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The arc from the top of the dial (where the phone, the shadow or the sun
/// is) round to the qibla: how far there is to turn, at a glance.
class QiblaDialArcPainter extends CustomPainter {
  final QiblaDialGeometry geometry;

  /// Signed degrees from the top to the qibla, positive clockwise.
  final double delta;
  final Color color;

  const QiblaDialArcPainter({
    required this.geometry,
    required this.delta,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (delta.abs() < 0.5) return;
    final rect = Rect.fromCircle(
      center: geometry.center,
      radius: geometry.rimRadius,
    );
    // Canvas arcs start at 3 o'clock; the top is −90°.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      delta * math.pi / 180,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(QiblaDialArcPainter old) =>
      old.geometry != geometry || old.delta != delta || old.color != color;
}

/// The Shadow tab's fixed "shadow needle": a thin line from the stick at the
/// centre to the top, which the user lines up with the real shadow.
class QiblaDialNeedlePainter extends CustomPainter {
  final QiblaDialGeometry geometry;
  final Color color;

  const QiblaDialNeedlePainter({required this.geometry, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = geometry.center;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, c + _polar(0, geometry.faceRadius - 18), paint);
    final tip = c + _polar(0, geometry.faceRadius - 18);
    final head = Path()
      ..moveTo(tip.dx, tip.dy - 8)
      ..lineTo(tip.dx - 5, tip.dy + 2)
      ..lineTo(tip.dx + 5, tip.dy + 2)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
    canvas.drawCircle(c, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(QiblaDialNeedlePainter old) =>
      old.geometry != geometry || old.color != color;
}

/// The centre arrow, pointing straight up; the dial turns it to the qibla.
///
/// Two tones (one half a little darker) give it depth without a gradient.
/// [glow] is the One Glow Rule's single glow, only when the user is facing
/// the qibla.
class QiblaDialArrowPainter extends CustomPainter {
  final QiblaDialGeometry geometry;
  final Color color;
  final Color? glow;

  const QiblaDialArrowPainter({
    required this.geometry,
    required this.color,
    this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = geometry.center;
    final length = geometry.faceRadius * 0.56;
    final halfWidth = length * 0.42;
    final tip = c + Offset(0, -length);
    final notch = c + Offset(0, length * 0.18);
    final left = c + Offset(-halfWidth, length * 0.42);
    final right = c + Offset(halfWidth, length * 0.42);

    final whole = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(notch.dx, notch.dy)
      ..lineTo(left.dx, left.dy)
      ..close();

    final glowColor = glow;
    if (glowColor != null) {
      canvas.drawPath(
        whole,
        Paint()
          ..color = glowColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    final leftHalf = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(notch.dx, notch.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    final rightHalf = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(notch.dx, notch.dy)
      ..close();
    canvas.drawPath(rightHalf, Paint()..color = color);
    canvas.drawPath(
      leftHalf,
      Paint()..color = Color.lerp(color, Colors.black, 0.18)!,
    );
  }

  @override
  bool shouldRepaint(QiblaDialArrowPainter old) =>
      old.geometry != geometry || old.color != color || old.glow != glow;
}
