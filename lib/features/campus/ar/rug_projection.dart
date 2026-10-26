import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart';

/// The virtual prayer rug's real-world size and the camera it is seen from.
///
/// None of this is measured. There is no ARCore here, so the floor, the
/// phone's height and the lens are all assumed, and the screen says so
/// ("the rug is a guide drawn from the compass"). The numbers are picked so
/// that, held the way people hold a phone to look at the floor, the rug looks
/// about the size of a real one.
@immutable
class RugGeometry {
  /// Across the rug, metres.
  final double widthM;

  /// Along the rug, toward the qibla, metres.
  final double lengthM;

  /// Assumed height of the phone above the floor, metres.
  final double cameraHeightM;

  /// Assumed vertical field of view of the preview, degrees, in portrait.
  final double verticalFovDegrees;

  /// The rug centre sits where the camera's axis meets the floor, kept within
  /// these distances so it neither slides under the user's feet nor runs off
  /// to the horizon as the phone tilts up.
  final double minDistanceM;
  final double maxDistanceM;

  /// Anything nearer than this along the camera axis is clipped away; a point
  /// at or behind the lens has no screen position.
  final double nearPlaneM;

  const RugGeometry({
    this.widthM = 0.7,
    this.lengthM = 1.2,
    this.cameraHeightM = 1.3,
    this.verticalFovDegrees = 60,
    this.minDistanceM = 0.8,
    this.maxDistanceM = 3.0,
    this.nearPlaneM = 0.1,
  });

  /// The rug outline in rug-local metres: near-left, near-right, far-right,
  /// far-left. See [RugProjector] for the axes.
  List<Offset> get corners {
    final hw = widthM / 2;
    final hl = lengthM / 2;
    return [Offset(-hw, -hl), Offset(hw, -hl), Offset(hw, hl), Offset(-hw, hl)];
  }
}

/// Projects points on the virtual rug onto the camera preview.
///
/// ## Frames
/// * **Rug-local** (the input): metres in the floor plane, origin at the rug
///   centre. `dx` runs across the rug (positive is the worshipper's right when
///   facing the qibla), `dy` runs along it (positive is TOWARD the qibla, so
///   the far edge, where a mihrab arch goes, is `dy = +length/2`).
/// * **World**: X right, Y forward (the horizontal direction the camera
///   looks), Z up, camera at the origin, floor at `Z = -cameraHeight`.
/// * **Camera**: pitched down by [pitchDegrees] about X. Screen coordinates
///   are y-down with the principal point at the viewport centre.
///
/// The rug is turned by [yawDegrees], the qibla's signed offset from the
/// heading (`QiblaGeodesy.signedDelta(qibla, heading)`), positive clockwise.
/// The rotation is written out as `(sin δ, cos δ)` on purpose: with the qibla
/// 90° to the right the rug's far end must land to the RIGHT of the centre,
/// and a test pins that, because the sign is the easiest thing here to get
/// backwards and nothing else would notice.
///
/// Paint the result in the same coordinate frame as the camera preview (the
/// same `FittedBox(cover)` child), or the rug and the floor drift apart on
/// any screen whose aspect differs from the camera's.
class RugProjector {
  final Size viewport;

  /// Camera depression below the horizon, degrees: 0 looks straight ahead,
  /// 90 straight down. From the accelerometer as
  /// `atan2(az, hypot(ax, ay))`.
  final double pitchDegrees;

  /// Device roll about the camera axis, degrees, positive when the phone is
  /// turned clockwise as its user sees it (top edge to the right). From the
  /// accelerometer as `atan2(-ax, ay)`.
  final double rollDegrees;

  /// The qibla relative to where the camera faces, degrees, positive
  /// clockwise.
  final double yawDegrees;

  final RugGeometry geometry;

  late final double _sinPitch;
  late final double _cosPitch;
  late final double _sinYaw;
  late final double _cosYaw;
  late final double _sinRoll;
  late final double _cosRoll;

  /// Focal length in pixels for [viewport]'s height and the assumed FOV.
  late final double focalPx;

  /// Distance along the floor from the user to the rug centre, metres.
  late final double distanceM;

  RugProjector({
    required this.viewport,
    required this.pitchDegrees,
    required this.yawDegrees,
    this.rollDegrees = 0,
    this.geometry = const RugGeometry(),
  }) {
    final pitch = pitchDegrees * math.pi / 180;
    final yaw = yawDegrees * math.pi / 180;
    final roll = rollDegrees * math.pi / 180;
    _sinPitch = math.sin(pitch);
    _cosPitch = math.cos(pitch);
    _sinYaw = math.sin(yaw);
    _cosYaw = math.cos(yaw);
    _sinRoll = math.sin(roll);
    _cosRoll = math.cos(roll);
    final halfFov = geometry.verticalFovDegrees * math.pi / 360;
    focalPx = (viewport.height / 2) / math.tan(halfFov);
    // Looking level or upward the axis never meets the floor; park the rug
    // at the far limit instead of dividing by a zero or negative tangent.
    final reach = pitchDegrees <= 1
        ? geometry.maxDistanceM
        : geometry.cameraHeightM / math.tan(pitch);
    distanceM = reach.clamp(geometry.minDistanceM, geometry.maxDistanceM);
  }

  Offset get _center => Offset(viewport.width / 2, viewport.height / 2);

  /// Camera-frame coordinates `(x right, y up, z forward along the axis)` of a
  /// rug-local point.
  _Vec3 _toCamera(Offset local) {
    // Rug-local -> world. Along-axis (toward the qibla) is (sin δ, cos δ);
    // across-axis (the worshipper's right) is (cos δ, -sin δ).
    final wx = local.dx * _cosYaw + local.dy * _sinYaw;
    final wy = distanceM - local.dx * _sinYaw + local.dy * _cosYaw;
    final wz = -geometry.cameraHeightM;
    // World -> camera, pitched down: right (1,0,0), up (0, sinφ, cosφ),
    // forward (0, cosφ, -sinφ).
    return _Vec3(
      wx,
      wy * _sinPitch + wz * _cosPitch,
      wy * _cosPitch - wz * _sinPitch,
    );
  }

  Offset _toScreen(_Vec3 c) {
    final dx = focalPx * c.x / c.z;
    final dy = -focalPx * c.y / c.z;
    // Rolling the phone clockwise turns the picture anticlockwise on screen;
    // in y-down coordinates that is this rotation.
    final center = _center;
    return Offset(
      center.dx + dx * _cosRoll + dy * _sinRoll,
      center.dy - dx * _sinRoll + dy * _cosRoll,
    );
  }

  /// Screen position of one rug-local point, or null when it is behind the
  /// near plane.
  Offset? projectPoint(Offset local) {
    final c = _toCamera(local);
    if (c.z < geometry.nearPlaneM) return null;
    return _toScreen(c);
  }

  /// Projects a closed polygon given in rug-local metres, clipped against the
  /// near plane (Sutherland–Hodgman), so a rug partly behind the camera keeps
  /// the visible part of its shape instead of losing whole corners.
  ///
  /// Empty when nothing is in front of the camera. Densify long curved edges
  /// (the mihrab arch) before passing them in: projection is exact per
  /// vertex, but the straight edges between vertices stay straight.
  List<Offset> projectPolygon(List<Offset> local) {
    if (local.isEmpty) return const [];
    final near = geometry.nearPlaneM;
    final input = [for (final p in local) _toCamera(p)];
    final clipped = <_Vec3>[];
    for (var i = 0; i < input.length; i++) {
      final current = input[i];
      final previous = input[(i + input.length - 1) % input.length];
      final currentIn = current.z >= near;
      final previousIn = previous.z >= near;
      if (currentIn != previousIn) {
        final t = (near - previous.z) / (current.z - previous.z);
        clipped.add(previous.lerp(current, t));
      }
      if (currentIn) clipped.add(current);
    }
    return [for (final c in clipped) _toScreen(c)];
  }

  /// The plain rug outline (see [RugGeometry.corners]), clipped.
  List<Offset> get outline => projectPolygon(geometry.corners);

  /// Middle of the far (qibla) edge, or null when it is clipped.
  Offset? get farEdgeCenter => projectPoint(Offset(0, geometry.lengthM / 2));

  /// Middle of the near edge, or null when it is clipped.
  Offset? get nearEdgeCenter => projectPoint(Offset(0, -geometry.lengthM / 2));

  /// The rug centre, or null when it is clipped.
  Offset? get rugCenter => projectPoint(Offset.zero);
}

@immutable
class _Vec3 {
  final double x;
  final double y;
  final double z;

  const _Vec3(this.x, this.y, this.z);

  _Vec3 lerp(_Vec3 other, double t) => _Vec3(
    x + (other.x - x) * t,
    y + (other.y - y) * t,
    z + (other.z - z) * t,
  );
}
