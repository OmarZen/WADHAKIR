import 'dart:math' as math;
import 'dart:ui';

/// Which part of the string a bead is on.
enum BeadKind { counted, active, remaining }

class BeadSpot {
  const BeadSpot(this.center, this.radius, this.kind);

  final Offset center;
  final double radius;
  final BeadKind kind;
}

/// Where the beads hang, as plain geometry so it can be tested without
/// painting anything.
///
/// The string sags in a parabola across the width with its lowest point at
/// the bottom centre. The bead about to be counted sits there, larger. Beads
/// already counted sit on the *forward* side and the ones still to go on the
/// other; dragging forward moves the whole string along the curve.
///
/// Forward follows the reading direction: towards the left in Arabic, so a
/// counted bead moves the way the eye moves along an Arabic line — and the
/// same way a bead is pushed along a real misbaha held in the right hand.
class BeadsLayout {
  BeadsLayout({required this.size, required this.direction}) {
    _sample();
  }

  final Size size;
  final TextDirection direction;

  /// Each side shows at most this many beads; the rest are off the string.
  static const int maxPerSide = 12;

  /// The smallest drag that counts a bead, whatever the bead size: a smaller
  /// pitch lets an unsteady finger count two.
  static const double minPitch = 28;

  /// +1 when forward is screen-right (LTR), -1 when it is screen-left (RTL).
  int get forwardSign => direction == TextDirection.rtl ? -1 : 1;

  double get beadDiameter =>
      math.min(size.width / 14, size.height / 4.5).clamp(14.0, 30.0);

  double get activeDiameter => beadDiameter * 1.5;

  /// Centre-to-centre spacing between two ordinary beads.
  double get pitch => math.max(beadDiameter * 1.05, minPitch);

  /// Centre-to-centre from the active bead to its neighbours, which is also
  /// how far a finger drags to count one: the next bead travels exactly this
  /// far into the active spot.
  double get dragPitch =>
      math.max((activeDiameter + beadDiameter) / 2 + 2, minPitch);

  Offset get lowest =>
      Offset(size.width / 2, size.height - activeDiameter / 2 - 10);

  double get _top => beadDiameter / 2 + 2;

  /// The curve reaches past the edges so beads leave the screen instead of
  /// piling up at its ends.
  double get _halfSpan => size.width / 2 + beadDiameter * 2;

  late final List<double> _xs;
  late final List<double> _ys;
  late final List<double> _lengths;

  void _sample() {
    const n = 96;
    final depth = math.max(lowest.dy - _top, 0.0);
    _xs = List<double>.filled(n + 1, 0);
    _ys = List<double>.filled(n + 1, 0);
    _lengths = List<double>.filled(n + 1, 0);
    for (var i = 0; i <= n; i++) {
      final x = _halfSpan * i / n;
      final t = x / _halfSpan;
      _xs[i] = x;
      _ys[i] = lowest.dy - depth * t * t;
      if (i > 0) {
        _lengths[i] =
            _lengths[i - 1] +
            math.sqrt(
              math.pow(_xs[i] - _xs[i - 1], 2) +
                  math.pow(_ys[i] - _ys[i - 1], 2),
            );
      }
    }
  }

  /// The point at signed arc length [s] from the lowest point, positive on
  /// the forward side; null past the end of the string.
  Offset? pointAt(double s) {
    final a = s.abs();
    if (a > _lengths.last) return null;
    var i = 1;
    while (i < _lengths.length - 1 && _lengths[i] < a) {
      i++;
    }
    final l0 = _lengths[i - 1];
    final l1 = _lengths[i];
    final f = l1 == l0 ? 0.0 : (a - l0) / (l1 - l0);
    final x = _xs[i - 1] + (_xs[i] - _xs[i - 1]) * f;
    final y = _ys[i - 1] + (_ys[i] - _ys[i - 1]) * f;
    final side = (s >= 0 ? 1 : -1) * forwardSign;
    return Offset(lowest.dx + side * x, y);
  }

  /// The whole string as a polyline, back end to forward end.
  List<Offset> stringPoints() => [
    for (var i = _xs.length - 1; i > 0; i--)
      Offset(lowest.dx - forwardSign * _xs[i], _ys[i]),
    for (var i = 0; i < _xs.length; i++)
      Offset(lowest.dx + forwardSign * _xs[i], _ys[i]),
  ];

  /// Every visible bead.
  ///
  /// [counted] is the count into the current round and [remaining] the beads
  /// left AFTER the active one, so `counted + 1 + remaining == target`.
  /// [phase] (0..1) is how far an unfinished drag has carried the string.
  List<BeadSpot> beads({
    required int counted,
    required int remaining,
    double phase = 0,
  }) {
    final p = phase.clamp(0.0, 1.0);
    final shift = p * dragPitch;
    final small = beadDiameter / 2;
    final big = activeDiameter / 2;
    final spots = <BeadSpot>[];

    void add(double s, double radius, BeadKind kind) {
      final c = pointAt(s);
      if (c != null) spots.add(BeadSpot(c, radius, kind));
    }

    final shownCounted = math.min(math.max(counted, 0), maxPerSide);
    for (var j = shownCounted; j >= 1; j--) {
      add(shift + dragPitch + (j - 1) * pitch, small, BeadKind.counted);
    }
    final shownRemaining = math.min(math.max(remaining, 0), maxPerSide);
    for (var j = shownRemaining; j >= 1; j--) {
      // The first remaining bead grows as it is dragged into the active spot.
      final r = j == 1 ? small + (big - small) * p : small;
      add(shift - dragPitch - (j - 1) * pitch, r, BeadKind.remaining);
    }
    // Last, so it paints on top; it shrinks as it leaves the spot.
    add(shift, big - (big - small) * p, BeadKind.active);
    return spots;
  }
}

/// Turns horizontal drag distance into counted beads.
///
/// Distance is accumulated along the forward direction only. Dragging back
/// undoes an unfinished drag but never a counted bead — a tasbiha said is not
/// unsaid by a wobble of the finger.
class BeadDragTracker {
  BeadDragTracker({required this.pitch, required this.forwardSign});

  final double pitch;
  final int forwardSign;

  /// On release, a drag at least this far into the next bead finishes it.
  static const double releaseThreshold = 0.5;

  double _progress = 0;

  /// How far into the next bead the drag is, 0..1.
  double get phase => pitch <= 0 ? 0 : _progress / pitch;

  /// Feeds one drag update of [dx] screen pixels; returns how many beads it
  /// completed.
  int update(double dx) {
    _progress += dx * forwardSign;
    if (_progress < 0) _progress = 0;
    var counted = 0;
    // A small epsilon so a drag of exactly n pitches counts n, not n - 1,
    // after floating-point accumulation.
    while (_progress >= pitch - 1e-6) {
      _progress = math.max(0, _progress - pitch);
      counted++;
    }
    return counted;
  }

  /// The finger lifted: returns 1 if the unfinished bead is past
  /// [releaseThreshold], and starts over either way.
  int release() {
    final counted = phase >= releaseThreshold ? 1 : 0;
    _progress = 0;
    return counted;
  }

  void reset() => _progress = 0;
}
