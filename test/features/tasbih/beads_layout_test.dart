import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/features/tasbih/views/painters/beads_layout.dart';

/// The beads mode's geometry and drag arithmetic, without painting.

BeadsLayout _layout(TextDirection d, {Size size = const Size(400, 300)}) =>
    BeadsLayout(size: size, direction: d);

void main() {
  group('which side is forward', () {
    test('Arabic counts to the left', () {
      final layout = _layout(TextDirection.rtl);
      expect(layout.forwardSign, -1);
      final beads = layout.beads(counted: 5, remaining: 5);
      final cx = layout.lowest.dx;
      for (final b in beads.where((b) => b.kind == BeadKind.counted)) {
        expect(b.center.dx, lessThan(cx));
      }
      for (final b in beads.where((b) => b.kind == BeadKind.remaining)) {
        expect(b.center.dx, greaterThan(cx));
      }
    });

    test('English counts to the right', () {
      final layout = _layout(TextDirection.ltr);
      expect(layout.forwardSign, 1);
      final beads = layout.beads(counted: 5, remaining: 5);
      final cx = layout.lowest.dx;
      for (final b in beads.where((b) => b.kind == BeadKind.counted)) {
        expect(b.center.dx, greaterThan(cx));
      }
      for (final b in beads.where((b) => b.kind == BeadKind.remaining)) {
        expect(b.center.dx, lessThan(cx));
      }
    });

    test('the active bead hangs at the bottom centre, larger', () {
      final layout = _layout(TextDirection.rtl);
      final beads = layout.beads(counted: 3, remaining: 3);
      final active = beads.singleWhere((b) => b.kind == BeadKind.active);
      expect(active.center.dx, closeTo(layout.lowest.dx, 0.01));
      expect(active.center.dy, closeTo(layout.lowest.dy, 0.01));
      final small = beads.firstWhere((b) => b.kind == BeadKind.counted);
      expect(active.radius, greaterThan(small.radius));
      // Every other bead hangs higher than the lowest point.
      for (final b in beads.where((b) => b.kind != BeadKind.active)) {
        expect(b.center.dy, lessThan(active.center.dy));
      }
    });
  });

  group('how many beads show', () {
    test('each side is capped', () {
      final beads = _layout(
        TextDirection.rtl,
      ).beads(counted: 40, remaining: 60);
      expect(
        beads.where((b) => b.kind == BeadKind.counted),
        hasLength(BeadsLayout.maxPerSide),
      );
      expect(
        beads.where((b) => b.kind == BeadKind.remaining),
        hasLength(BeadsLayout.maxPerSide),
      );
    });

    test('the remaining side shortens near the end of a round', () {
      final beads = _layout(TextDirection.rtl).beads(counted: 30, remaining: 2);
      expect(beads.where((b) => b.kind == BeadKind.remaining), hasLength(2));
      expect(beads.where((b) => b.kind == BeadKind.active), hasLength(1));
    });

    test('a fresh round has nothing on the counted side', () {
      final beads = _layout(TextDirection.ltr).beads(counted: 0, remaining: 32);
      expect(beads.where((b) => b.kind == BeadKind.counted), isEmpty);
    });
  });

  group('pitch', () {
    test('is never under the minimum, however small the space', () {
      final layout = _layout(TextDirection.rtl, size: const Size(200, 60));
      expect(layout.pitch, greaterThanOrEqualTo(BeadsLayout.minPitch));
      expect(layout.dragPitch, greaterThanOrEqualTo(BeadsLayout.minPitch));
    });

    test('a full drag pitch carries the next bead into the active spot', () {
      final layout = _layout(TextDirection.rtl);
      final atRest = layout.beads(counted: 3, remaining: 3);
      final dragged = layout.beads(counted: 3, remaining: 3, phase: 1);
      final active = atRest.singleWhere((b) => b.kind == BeadKind.active);
      // The bead just before the active one — remaining, j == 1 — is the
      // last remaining spot listed.
      final next = dragged.lastWhere((b) => b.kind == BeadKind.remaining);
      expect(next.center.dx, closeTo(active.center.dx, 0.5));
      expect(next.center.dy, closeTo(active.center.dy, 0.5));
      expect(next.radius, closeTo(active.radius, 0.01));
    });
  });

  group('dragging', () {
    test('one pitch forward counts one', () {
      final t = BeadDragTracker(pitch: 30, forwardSign: 1);
      expect(t.update(30), 1);
      expect(t.phase, closeTo(0, 1e-9));
    });

    test('2.6 pitches count two and keep 0.6 in hand', () {
      final t = BeadDragTracker(pitch: 30, forwardSign: 1);
      var counted = 0;
      // In small steps, the way drag updates arrive.
      for (var i = 0; i < 78; i++) {
        counted += t.update(1);
      }
      expect(counted, 2);
      expect(t.phase, closeTo(0.6, 1e-6));
    });

    test('dragging backwards never counts and never goes negative', () {
      final t = BeadDragTracker(pitch: 30, forwardSign: 1);
      expect(t.update(-90), 0);
      expect(t.phase, 0);
      t.update(15);
      expect(t.update(-40), 0);
      expect(t.phase, 0);
    });

    test('in RTL, forward is a leftward (negative) drag', () {
      final t = BeadDragTracker(pitch: 30, forwardSign: -1);
      expect(t.update(-30), 1);
      expect(t.update(60), 0);
    });

    test('on release, half a pitch or more finishes the bead', () {
      final t = BeadDragTracker(pitch: 30, forwardSign: 1);
      t.update(15);
      expect(t.release(), 1);
      expect(t.phase, 0);

      t.update(14);
      expect(t.release(), 0, reason: 'short of half: springs back');
      expect(t.phase, 0);
    });
  });
}
