import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/features/campus/ar/rug_projection.dart';

void main() {
  const viewport = Size(400, 800);
  const cx = 200.0;
  const cy = 400.0;

  RugProjector at({double pitch = 45, double yaw = 0, double roll = 0}) =>
      RugProjector(
        viewport: viewport,
        pitchDegrees: pitch,
        yawDegrees: yaw,
        rollDegrees: roll,
      );

  group('facing the qibla (yaw 0)', () {
    final outline = at().outline;
    final nearLeft = outline[0];
    final nearRight = outline[1];
    final farRight = outline[2];
    final farLeft = outline[3];

    test('is a trapezoid symmetric about the centre line', () {
      expect(outline, hasLength(4));
      expect(nearLeft.dx + nearRight.dx, closeTo(2 * cx, 1e-6));
      expect(farLeft.dx + farRight.dx, closeTo(2 * cx, 1e-6));
      expect(nearLeft.dy, closeTo(nearRight.dy, 1e-6));
      expect(farLeft.dy, closeTo(farRight.dy, 1e-6));
    });

    test('has its far edge narrower and higher, as perspective demands', () {
      expect(farRight.dx - farLeft.dx, lessThan(nearRight.dx - nearLeft.dx));
      expect(farLeft.dy, lessThan(nearLeft.dy));
    });

    test('sits where the camera axis meets the floor', () {
      // At 45° and 1.3 m the axis meets the floor 1.3 m ahead, inside the
      // clamp, so the rug centre is the screen centre.
      final center = at().rugCenter!;
      expect(center.dx, closeTo(cx, 1e-6));
      expect(center.dy, closeTo(cy, 1e-6));
    });
  });

  group('yaw', () {
    test('qibla 90° to the right puts the far end right of centre', () {
      // The sign that is easiest to get backwards. The rug's far (qibla) end
      // must be on the side the user has to turn toward.
      expect(at(yaw: 90).farEdgeCenter!.dx, greaterThan(cx));
      expect(at(yaw: 90).nearEdgeCenter!.dx, lessThan(cx));
    });

    test('qibla 90° to the left puts the far end left of centre', () {
      expect(at(yaw: -90).farEdgeCenter!.dx, lessThan(cx));
    });

    test('at 90° the long axis runs across the screen', () {
      final p = at(yaw: 90);
      expect(p.farEdgeCenter!.dy, closeTo(p.nearEdgeCenter!.dy, 1e-6));
    });

    test('a small right turn tilts the far end slightly right', () {
      final far = at(yaw: 10).farEdgeCenter!;
      expect(far.dx, greaterThan(cx));
      expect(far.dx, lessThan(cx + 100));
    });
  });

  group('roll', () {
    test('turning the phone clockwise swings the floor to the right', () {
      final level = at().nearEdgeCenter!;
      expect(level.dx, closeTo(cx, 1e-6));
      expect(level.dy, greaterThan(cy));

      final rolled = at(roll: 90).nearEdgeCenter!;
      expect(rolled.dx, greaterThan(cx));
      expect(rolled.dy, closeTo(cy, 1e-6));
    });
  });

  group('near plane', () {
    test('a rug partly behind the camera is clipped, not dropped', () {
      // Looking 60° UP: the rug parks 3 m out and its near corners fall
      // behind the 0.1 m near plane while the far ones stay in view.
      final p = at(pitch: -60);
      final corners = p.geometry.corners;
      expect(p.projectPoint(corners[0]), isNull, reason: 'near-left');
      expect(p.projectPoint(corners[3]), isNotNull, reason: 'far-left');

      final outline = p.outline;
      expect(outline, hasLength(4), reason: '2 kept + 2 on the near plane');
      for (final point in outline) {
        expect(point.dx.isFinite && point.dy.isFinite, isTrue);
      }
    });

    test('a rug wholly behind the camera projects to nothing', () {
      expect(at(pitch: -89).outline, isEmpty);
    });

    test('looking level parks the rug at the far limit', () {
      final p = at(pitch: 0);
      expect(p.distanceM, p.geometry.maxDistanceM);
      expect(p.outline, hasLength(4));
    });

    test('looking straight down keeps the rug out from under the feet', () {
      expect(at(pitch: 89).distanceM, at(pitch: 89).geometry.minDistanceM);
    });
  });

  test('projectPolygon of nothing is nothing', () {
    expect(at().projectPolygon(const []), isEmpty);
  });
}
