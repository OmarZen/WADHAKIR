import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// A position on the Earth, in degrees: latitude north-positive, longitude
/// east-positive.
///
/// Kept independent of `latlong2` on purpose: this file is pure maths shared
/// by the cubit, the dial and the map, and only the map needs `LatLng`. The
/// map converts at its edge.
@immutable
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

/// Bearings and distances to the Kaaba.
///
/// Everything here is on a sphere. The ellipsoid changes the qibla bearing by
/// well under a tenth of a degree anywhere people live, which is far inside
/// what a phone compass can resolve, and the spherical formulas have no
/// convergence edge cases to get wrong.
abstract final class QiblaGeodesy {
  /// The Kaaba, Makkah. The same coordinates the app has always used, so the
  /// bearing does not shift for anyone on update.
  static const GeoPoint kaaba = GeoPoint(21.422487, 39.826206);

  /// IUGG mean Earth radius. The haversine distance is only as good as the
  /// sphere it assumes; the mean radius keeps the error under about 0.3%.
  static const double earthRadiusKm = 6371.0088;

  /// Folds any angle into `[0, 360)`.
  ///
  /// The double modulo is deliberate. flutter_compass on Android reports
  /// −180..180, and a single `% 360` can return exactly 360.0 for a tiny
  /// negative input once the subtraction rounds, which would then fail every
  /// "is this < 360" check downstream.
  static double normalize(double degrees) => (degrees % 360 + 360) % 360;

  /// How far, and which way, to turn from [from] to face [target], in
  /// `(-180, 180]`.
  ///
  /// Positive means [target] is clockwise of [from]: turn right. Exactly
  /// opposite counts as +180 so the answer is never ambiguous.
  static double signedDelta(double target, double from) {
    final d = normalize(target - from);
    return d > 180 ? d - 360 : d;
  }

  /// The initial great-circle bearing from [from] to [to], degrees clockwise
  /// from true north in `[0, 360)`.
  ///
  /// At the destination itself both atan2 arguments are zero and Dart returns
  /// 0, so a user standing at the Kaaba gets a finite (meaningless) bearing,
  /// never NaN. The UI shows "you are at the Kaaba" there instead.
  static double initialBearing(GeoPoint from, GeoPoint to) {
    final phi1 = _rad(from.latitude);
    final phi2 = _rad(to.latitude);
    final dLambda = _rad(to.longitude - from.longitude);
    final y = math.sin(dLambda) * math.cos(phi2);
    final x =
        math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
    return normalize(_deg(math.atan2(y, x)));
  }

  /// The qibla: the bearing from [from] to the Kaaba, relative to TRUE north.
  ///
  /// A compass heading has to be true-north too before the two are compared;
  /// see the declination step in the qibla cubit.
  static double qiblaBearing(GeoPoint from) => initialBearing(from, kaaba);

  /// Great-circle (haversine) distance in kilometres.
  static double distanceKm(GeoPoint a, GeoPoint b) {
    final phi1 = _rad(a.latitude);
    final phi2 = _rad(b.latitude);
    final dPhi = phi2 - phi1;
    final dLambda = _rad(b.longitude - a.longitude);
    final h =
        math.pow(math.sin(dPhi / 2), 2) +
        math.cos(phi1) * math.cos(phi2) * math.pow(math.sin(dLambda / 2), 2);
    // Clamped: rounding can push h a hair past 1 for antipodal points, and
    // asin(1.0000000001) is NaN.
    return 2 * earthRadiusKm * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }

  /// Distance from [from] to the Kaaba in kilometres.
  static double distanceToKaabaKm(GeoPoint from) => distanceKm(from, kaaba);

  /// [segments] + 1 points along the great circle from [from] to [to],
  /// endpoints included and exact.
  ///
  /// Longitudes come back folded into `[-180, 180]`, so every point is a valid
  /// `LatLng`. A path that crosses the antimeridian therefore jumps from about
  /// +180 to −180 between two neighbours; flutter_map 8 projects a polyline
  /// relative to its previous point and draws that as one continuous line
  /// (`Projection.projectList`), so the map must not split it.
  ///
  /// Walks the circle by destination-point steps along the initial bearing
  /// rather than slerping unit vectors, because slerp divides by sin(distance)
  /// and falls apart at the antipode, where every bearing is a great circle.
  static List<GeoPoint> greatCircle(
    GeoPoint from,
    GeoPoint to, {
    int segments = 96,
  }) {
    assert(segments >= 1, 'a path needs at least one segment');
    final start = GeoPoint(from.latitude, _foldLongitude(from.longitude));
    final end = GeoPoint(to.latitude, _foldLongitude(to.longitude));
    final angular = distanceKm(from, to) / earthRadiusKm;
    if (angular < 1e-9) return [start, end];

    final phi1 = _rad(from.latitude);
    final lambda1 = _rad(from.longitude);
    final theta = _rad(initialBearing(from, to));
    final points = <GeoPoint>[start];
    for (var i = 1; i < segments; i++) {
      final delta = angular * i / segments;
      final sinPhi =
          math.sin(phi1) * math.cos(delta) +
          math.cos(phi1) * math.sin(delta) * math.cos(theta);
      final phi = math.asin(sinPhi.clamp(-1.0, 1.0));
      final lambda =
          lambda1 +
          math.atan2(
            math.sin(theta) * math.sin(delta) * math.cos(phi1),
            math.cos(delta) - math.sin(phi1) * sinPhi,
          );
      points.add(GeoPoint(_deg(phi), _foldLongitude(_deg(lambda))));
    }
    points.add(end);
    return points;
  }

  /// Into `[-180, 180]`, leaving in-range values bit-for-bit alone so the
  /// endpoints come back exactly as given.
  static double _foldLongitude(double lng) =>
      (lng >= -180 && lng <= 180) ? lng : (lng + 540) % 360 - 180;

  static double _rad(double deg) => deg * math.pi / 180;

  static double _deg(double rad) => rad * 180 / math.pi;
}
