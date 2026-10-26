import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/astronomy/celestial_position.dart';

/// Pinned against Jean Meeus, *Astronomical Algorithms* (2nd ed.). Meeus gives
/// his ephemeris examples in Dynamical Time (TD), so those tests call the
/// `jde` functions directly; the public `sun()` / `moon()` add ΔT themselves.
void main() {
  group('time', () {
    test('J2000.0 is JD 2451545.0', () {
      expect(
        CelestialPosition.julianDay(DateTime.utc(2000, 1, 1, 12)),
        2451545.0,
      );
    });

    test('a local DateTime is read as the instant it is', () {
      final utc = DateTime.utc(2026, 10, 25, 9);
      expect(
        CelestialPosition.julianDay(utc.toLocal()),
        CelestialPosition.julianDay(utc),
      );
    });

    test('Meeus 12.a: sidereal time at Greenwich, 1987 April 10 0h UT', () {
      // 13h 10m 46.3668s
      const expected = (13 + 10 / 60 + 46.3668 / 3600) * 15;
      expect(
        CelestialPosition.greenwichMeanSiderealTime(2446895.5),
        closeTo(expected, 0.0005),
      );
    });
  });

  group('sun', () {
    test('Meeus 25.a: apparent position, 1992 October 13.0 TD', () {
      final sun = CelestialPosition.sunEquatorial(2448908.5);
      expect(sun.rightAscension, closeTo(198.38083, 0.01));
      expect(sun.declination, closeTo(-7.78507, 0.01));
      expect(sun.distanceKm! / 149597870.7, closeTo(0.99766, 0.0005));
    });

    test('at solar noon the sun is due south of Cairo', () {
      // Scan a winter morning (UTC) for the sun's highest point; at that
      // moment its azimuth must be 180° from true north.
      var bestAlt = -90.0;
      var bestAz = 0.0;
      for (var s = 0; s < 3 * 3600; s += 20) {
        final t = DateTime.utc(2026, 12, 21, 8, 30).add(Duration(seconds: s));
        final p = CelestialPosition.sun(
          t,
          latitude: 30.0444,
          longitude: 31.2357,
        );
        if (p.altitude > bestAlt) {
          bestAlt = p.altitude;
          bestAz = p.azimuth;
        }
      }
      expect(bestAz, closeTo(180, 0.5));
      // 90 − latitude + declination (−23.43) at the December solstice.
      expect(bestAlt, closeTo(90 - 30.0444 - 23.43, 0.15));
    });

    test('is below the horizon at Cairo midnight', () {
      final p = CelestialPosition.sun(
        DateTime.utc(2026, 12, 21, 22),
        latitude: 30.0444,
        longitude: 31.2357,
      );
      expect(p.isAboveHorizon, isFalse);
      expect(p.altitude, lessThan(-30));
    });

    test('a stick\'s shadow points directly away from the sun', () {
      expect(
        CelestialPosition.shadowAzimuth(
          const HorizontalPosition(azimuth: 100, altitude: 30),
        ),
        280,
      );
      expect(
        CelestialPosition.shadowAzimuth(
          const HorizontalPosition(azimuth: 250, altitude: 30),
        ),
        70,
      );
    });
  });

  group('equatorialToHorizontal', () {
    test('Meeus 13.b: Venus from Washington, 248.03° from north', () {
      // 1987 April 10, 19:21:00 UT. Apparent sidereal time at Greenwich
      // 8h 34m 56.853s; Washington 77°03′56″ W, 38°55′17″ N.
      const gst = (8 + 34 / 60 + 56.853 / 3600) * 15;
      const longitude = -(77 + 3 / 60 + 56 / 3600);
      const latitude = 38 + 55 / 60 + 17 / 3600;
      const ra = (23 + 9 / 60 + 16.641 / 3600) * 15;
      const dec = -(6 + 43 / 60 + 11.61 / 3600);
      final p = CelestialPosition.equatorialToHorizontal(
        rightAscension: ra,
        declination: dec,
        latitude: latitude,
        localSiderealTime: gst + longitude,
      );
      // Meeus: A = 68.0337° measured from the SOUTH; h = 15.1249°.
      expect(p.azimuth, closeTo(248.0337, 0.05));
      expect(p.altitude, closeTo(15.1249, 0.05));
    });

    test('on the meridian a body south of the zenith is due south', () {
      final p = CelestialPosition.equatorialToHorizontal(
        rightAscension: 40,
        declination: -10,
        latitude: 30,
        localSiderealTime: 40,
      );
      expect(p.azimuth, closeTo(180, 1e-9));
      expect(p.altitude, closeTo(50, 1e-9));
    });
  });

  group('moon', () {
    test('Meeus 47.a: geocentric position, 1992 April 12.0 TD', () {
      final moon = CelestialPosition.moonEquatorial(2448724.5);
      expect(moon.rightAscension, closeTo(134.688470, 0.1));
      expect(moon.declination, closeTo(13.768368, 0.1));
      expect(moon.distanceKm, closeTo(368409.7, 368409.7 * 0.01));
    });

    test('parallax lowers the moon about a degree at the horizon', () {
      // An observer on the equator with the moon exactly on the geocentric
      // horizon (hour angle 90°, declination 0).
      const geo = EquatorialPosition(
        rightAscension: 0,
        declination: 0,
        distanceKm: 384400,
      );
      final topo = CelestialPosition.topocentric(
        geo,
        latitude: 0,
        localSiderealTime: 90,
      );
      final geometric = CelestialPosition.equatorialToHorizontal(
        rightAscension: geo.rightAscension,
        declination: geo.declination,
        latitude: 0,
        localSiderealTime: 90,
      );
      final seen = CelestialPosition.equatorialToHorizontal(
        rightAscension: topo.rightAscension,
        declination: topo.declination,
        latitude: 0,
        localSiderealTime: 90,
      );
      expect(geometric.altitude, closeTo(0, 1e-9));
      expect(seen.altitude, closeTo(-0.95, 0.02));
    });

    test('there is no parallax at the zenith', () {
      const geo = EquatorialPosition(
        rightAscension: 0,
        declination: 0,
        distanceKm: 384400,
      );
      final topo = CelestialPosition.topocentric(
        geo,
        latitude: 0,
        localSiderealTime: 0,
      );
      final seen = CelestialPosition.equatorialToHorizontal(
        rightAscension: topo.rightAscension,
        declination: topo.declination,
        latitude: 0,
        localSiderealTime: 0,
      );
      expect(seen.altitude, closeTo(90, 0.01));
    });

    test('public moon() gives finite values on the equator', () {
      // Schlyter's shortcut divides by zero here; the rigorous form does not.
      final p = CelestialPosition.moon(
        DateTime.utc(2026, 10, 25, 18),
        latitude: 0,
        longitude: 0,
      );
      expect(p.azimuth.isFinite, isTrue);
      expect(p.altitude.isFinite, isTrue);
    });
  });

  group('refraction (Sæmundsson)', () {
    test('is about half a degree at the horizon', () {
      expect(CelestialPosition.refraction(0), closeTo(0.48, 0.02));
    });

    test('vanishes at the zenith and below -1°', () {
      expect(CelestialPosition.refraction(90), closeTo(0, 0.001));
      expect(CelestialPosition.refraction(-2), 0);
    });

    test('lifts the apparent sun above the geometric one', () {
      final t = DateTime.utc(2026, 10, 25, 4);
      final apparent = CelestialPosition.sun(t, latitude: 30, longitude: 31);
      final eq = CelestialPosition.sunEquatorial(
        CelestialPosition.julianEphemerisDay(t),
      );
      final geometric = CelestialPosition.equatorialToHorizontal(
        rightAscension: eq.rightAscension,
        declination: eq.declination,
        latitude: 30,
        localSiderealTime: CelestialPosition.localSiderealTime(
          CelestialPosition.julianDay(t),
          31,
        ),
      );
      expect(apparent.altitude, greaterThanOrEqualTo(geometric.altitude));
      expect(apparent.azimuth, geometric.azimuth);
    });
  });
}
