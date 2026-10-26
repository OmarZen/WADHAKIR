import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/geo/qibla_geodesy.dart';

/// The qibla bearing is the one number this whole feature exists to get right,
/// and a wrong one fails silently: the arrow still points somewhere
/// confident. These pin it against values worked out independently for four
/// cities on four sides of Makkah.
void main() {
  const cairo = GeoPoint(30.0444, 31.2357);
  const london = GeoPoint(51.5074, -0.1278);
  const newYork = GeoPoint(40.7128, -74.0060);
  const jakarta = GeoPoint(-6.2088, 106.8456);

  group('qiblaBearing', () {
    test('Cairo faces south-east', () {
      expect(QiblaGeodesy.qiblaBearing(cairo), closeTo(136.14, 0.3));
    });

    test('London faces east-south-east', () {
      expect(QiblaGeodesy.qiblaBearing(london), closeTo(118.99, 0.3));
    });

    test('New York faces north-east, along the great circle', () {
      // A rhumb line would say about 97°; the shortest path bends north.
      expect(QiblaGeodesy.qiblaBearing(newYork), closeTo(58.48, 0.3));
    });

    test('Jakarta faces west-north-west', () {
      expect(QiblaGeodesy.qiblaBearing(jakarta), closeTo(295.15, 0.3));
    });

    test('at the Kaaba itself the bearing is finite, not NaN', () {
      final bearing = QiblaGeodesy.qiblaBearing(QiblaGeodesy.kaaba);
      expect(bearing.isNaN, isFalse);
      expect(bearing, inInclusiveRange(0, 360));
      expect(QiblaGeodesy.distanceToKaabaKm(QiblaGeodesy.kaaba), 0);
    });

    test('at the antipode nothing is NaN', () {
      const antipode = GeoPoint(-21.422487, 39.826206 - 180);
      expect(QiblaGeodesy.qiblaBearing(antipode).isNaN, isFalse);
      expect(
        QiblaGeodesy.distanceToKaabaKm(antipode),
        closeTo(QiblaGeodesy.earthRadiusKm * 3.141592653589793, 1),
      );
    });
  });

  group('distanceKm', () {
    test('Cairo to the Kaaba', () {
      expect(QiblaGeodesy.distanceToKaabaKm(cairo), closeTo(1287.2, 0.5));
    });

    test('London to the Kaaba', () {
      expect(QiblaGeodesy.distanceToKaabaKm(london), closeTo(4793.8, 0.5));
    });

    test('is symmetric', () {
      expect(
        QiblaGeodesy.distanceKm(cairo, london),
        closeTo(QiblaGeodesy.distanceKm(london, cairo), 1e-9),
      );
    });
  });

  group('normalize', () {
    test('folds Android\'s negative headings instead of dropping them', () {
      expect(QiblaGeodesy.normalize(-170), 190);
      expect(QiblaGeodesy.normalize(-180), 180);
      expect(QiblaGeodesy.normalize(-0.5), 359.5);
    });

    test('maps 360 and multiples to 0, and keeps the range half-open', () {
      expect(QiblaGeodesy.normalize(360), 0);
      expect(QiblaGeodesy.normalize(720.25), closeTo(0.25, 1e-9));
      expect(QiblaGeodesy.normalize(-1e-15), lessThan(360));
    });
  });

  group('signedDelta', () {
    test('positive means the target is clockwise: turn right', () {
      expect(QiblaGeodesy.signedDelta(100, 90), 10);
      expect(QiblaGeodesy.signedDelta(80, 90), -10);
    });

    test('wraps across north both ways', () {
      expect(QiblaGeodesy.signedDelta(10, 350), 20);
      expect(QiblaGeodesy.signedDelta(350, 10), -20);
      expect(QiblaGeodesy.signedDelta(0, 359), 1);
    });

    test('exactly opposite is +180, never -180', () {
      expect(QiblaGeodesy.signedDelta(180, 0), 180);
      expect(QiblaGeodesy.signedDelta(0, 180), 180);
    });

    test('accepts unnormalised inputs', () {
      expect(QiblaGeodesy.signedDelta(-170, 170), 20);
      expect(QiblaGeodesy.signedDelta(730, 0), 10);
    });
  });

  group('greatCircle', () {
    test('starts and ends exactly at the endpoints', () {
      final path = QiblaGeodesy.greatCircle(
        cairo,
        QiblaGeodesy.kaaba,
        segments: 32,
      );
      expect(path, hasLength(33));
      expect(path.first, cairo);
      expect(path.last, QiblaGeodesy.kaaba);
    });

    test('progresses steadily toward the destination', () {
      final path = QiblaGeodesy.greatCircle(
        london,
        QiblaGeodesy.kaaba,
        segments: 20,
      );
      final total = QiblaGeodesy.distanceToKaabaKm(london);
      for (var i = 0; i < path.length; i++) {
        expect(
          QiblaGeodesy.distanceKm(london, path[i]),
          closeTo(total * i / 20, 1),
          reason: 'point $i',
        );
      }
    });

    test('bends north from New York, as the bearing says', () {
      final path = QiblaGeodesy.greatCircle(newYork, QiblaGeodesy.kaaba);
      final highest = path
          .map((p) => p.latitude)
          .reduce((a, b) => a > b ? a : b);
      expect(highest, greaterThan(newYork.latitude + 5));
    });

    test('keeps every longitude a valid LatLng across the antimeridian', () {
      // Honolulu's path to Makkah crosses 180°.
      const honolulu = GeoPoint(21.3069, -157.8583);
      final path = QiblaGeodesy.greatCircle(honolulu, QiblaGeodesy.kaaba);
      for (final p in path) {
        expect(p.longitude, inInclusiveRange(-180, 180));
        expect(p.latitude, inInclusiveRange(-90, 90));
      }
      final jumps = <int>[];
      for (var i = 1; i < path.length; i++) {
        if ((path[i].longitude - path[i - 1].longitude).abs() > 180) {
          jumps.add(i);
        }
      }
      expect(jumps, hasLength(1), reason: 'one crossing, left to flutter_map');
    });

    test('a zero-length path is just the two endpoints', () {
      final path = QiblaGeodesy.greatCircle(
        QiblaGeodesy.kaaba,
        QiblaGeodesy.kaaba,
      );
      expect(path, [QiblaGeodesy.kaaba, QiblaGeodesy.kaaba]);
    });
  });
}
