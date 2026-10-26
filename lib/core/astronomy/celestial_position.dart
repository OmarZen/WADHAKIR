import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:wadhakir/core/geo/qibla_geodesy.dart';

/// Where a body is in the local sky.
@immutable
class HorizontalPosition {
  /// Degrees clockwise from TRUE north, `[0, 360)`.
  final double azimuth;

  /// Degrees above the horizon. For the public [CelestialPosition.sun] and
  /// [CelestialPosition.moon] this is the APPARENT altitude: refraction is
  /// applied, and the moon's is topocentric. [CelestialPosition.equatorialToHorizontal]
  /// on its own returns the geometric altitude.
  final double altitude;

  const HorizontalPosition({required this.azimuth, required this.altitude});

  /// The centre of the disc is above the horizon.
  ///
  /// The centre rather than the upper limb (−0.27°): this picks sun or moon
  /// for the Sun/Moon tab, and a body whose centre is already down is no use
  /// for aiming at.
  bool get isAboveHorizon => altitude > 0;

  @override
  bool operator ==(Object other) =>
      other is HorizontalPosition &&
      other.azimuth == azimuth &&
      other.altitude == altitude;

  @override
  int get hashCode => Object.hash(azimuth, altitude);

  @override
  String toString() =>
      'HorizontalPosition(az: ${azimuth.toStringAsFixed(2)}, '
      'alt: ${altitude.toStringAsFixed(2)})';
}

/// A position on the celestial sphere, in degrees.
@immutable
class EquatorialPosition {
  /// Right ascension, `[0, 360)` degrees (not hours).
  final double rightAscension;

  final double declination;

  /// Distance from the Earth's centre in km, where the model gives one.
  final double? distanceKm;

  const EquatorialPosition({
    required this.rightAscension,
    required this.declination,
    this.distanceKm,
  });
}

/// Sun and moon positions for the Shadow and Sun/Moon qibla tabs.
///
/// Written here rather than taken from a package: adhan_dart has the solar
/// coordinates but does not export them (a `src/` import trips the
/// `implementation_imports` lint), it has no moon at all, and the maths is a
/// few dozen lines that tests pin against Meeus's worked examples.
///
/// Accuracy is about 0.01° for the sun and a few hundredths of a degree for
/// the moon, against a use that needs about one degree: the user lines a
/// marker up with the sun by eye.
///
/// ## Time scales
/// The ephemerides run on Terrestrial Time; sidereal time runs on UT. Public
/// entry points take a UTC instant and add [deltaTSeconds] for the former.
/// Meeus's examples are given in TD, so the tests call the `jde` functions
/// directly and skip that conversion.
abstract final class CelestialPosition {
  /// TT − UT. About 69 s through the 2020s and drifting by well under a second
  /// a year; at that rate the moon moves 0.01° per second of error, so a
  /// constant is plenty.
  static const double deltaTSeconds = 69.0;

  /// Equatorial Earth radius, km (Meeus's value).
  static const double earthEquatorialRadiusKm = 6378.14;

  /// Julian Day (UT) of an instant.
  static double julianDay(DateTime instant) =>
      instant.toUtc().millisecondsSinceEpoch / 86400000.0 + 2440587.5;

  /// Julian Ephemeris Day (TT) of an instant.
  static double julianEphemerisDay(DateTime instant) =>
      julianDay(instant) + deltaTSeconds / 86400.0;

  /// Greenwich mean sidereal time in degrees for a UT Julian Day
  /// (Meeus 12.4).
  ///
  /// Mean, not apparent: the nutation term is at most about 0.005°.
  static double greenwichMeanSiderealTime(double jdUt) {
    final t = (jdUt - 2451545.0) / 36525.0;
    return QiblaGeodesy.normalize(
      280.46061837 +
          360.98564736629 * (jdUt - 2451545.0) +
          0.000387933 * t * t -
          t * t * t / 38710000.0,
    );
  }

  /// Local sidereal time in degrees; [longitude] is east-positive.
  static double localSiderealTime(double jdUt, double longitude) =>
      QiblaGeodesy.normalize(greenwichMeanSiderealTime(jdUt) + longitude);

  /// Apparent geocentric sun (NOAA / Meeus chapter 25, low accuracy).
  static EquatorialPosition sunEquatorial(double jde) {
    final t = (jde - 2451545.0) / 36525.0;
    final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
    final m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
    final e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;
    final c =
        (1.914602 - 0.004817 * t - 0.000014 * t * t) * _sin(m) +
        (0.019993 - 0.000101 * t) * _sin(2 * m) +
        0.000289 * _sin(3 * m);
    final trueLongitude = l0 + c;
    final trueAnomaly = m + c;
    final distanceAu = 1.000001018 * (1 - e * e) / (1 + e * _cos(trueAnomaly));
    final omega = 125.04 - 1934.136 * t;
    final lambda = trueLongitude - 0.00569 - 0.00478 * _sin(omega);
    final epsilon = _meanObliquity(t) + 0.00256 * _cos(omega);
    return EquatorialPosition(
      rightAscension: QiblaGeodesy.normalize(
        _deg(math.atan2(_cos(epsilon) * _sin(lambda), _cos(lambda))),
      ),
      declination: _deg(math.asin(_sin(epsilon) * _sin(lambda))),
      distanceKm: distanceAu * 149597870.7,
    );
  }

  /// Geocentric moon (Paul Schlyter's method with its main perturbations:
  /// evection, variation, the yearly and parallactic equations and the
  /// largest latitude and distance terms).
  ///
  /// Referred to the mean equinox of date. Against Meeus 47.a it is within
  /// about 0.03° in right ascension and 0.1% in distance.
  static EquatorialPosition moonEquatorial(double jde) {
    // Schlyter's day number: 0.0 at 2000 Jan 0.0 TT.
    final d = jde - 2451543.5;

    final node = 125.1228 - 0.0529538083 * d;
    const inclination = 5.1454;
    final perigee = 318.0634 + 0.1643573223 * d;
    const a = 60.2666; // Earth radii
    const e = 0.054900;
    final mMoon = QiblaGeodesy.normalize(115.3654 + 13.0649929509 * d);
    final wSun = 282.9404 + 4.70935e-5 * d;
    final mSun = QiblaGeodesy.normalize(356.0470 + 0.9856002585 * d);

    // Kepler's equation, Newton's method from Schlyter's first guess.
    var ecc = mMoon + _deg(e * _sin(mMoon) * (1 + e * _cos(mMoon)));
    for (var i = 0; i < 5; i++) {
      ecc -= (ecc - _deg(e * _sin(ecc)) - mMoon) / (1 - e * _cos(ecc));
    }

    final xv = a * (_cos(ecc) - e);
    final yv = a * math.sqrt(1 - e * e) * _sin(ecc);
    final v = _deg(math.atan2(yv, xv));
    var r = math.sqrt(xv * xv + yv * yv);

    final xh =
        r *
        (_cos(node) * _cos(v + perigee) -
            _sin(node) * _sin(v + perigee) * _cos(inclination));
    final yh =
        r *
        (_sin(node) * _cos(v + perigee) +
            _cos(node) * _sin(v + perigee) * _cos(inclination));
    final zh = r * _sin(v + perigee) * _sin(inclination);
    var lon = _deg(math.atan2(yh, xh));
    var lat = _deg(math.atan2(zh, math.sqrt(xh * xh + yh * yh)));

    final lSun = mSun + wSun; // sun's mean longitude
    final lMoon = mMoon + perigee + node; // moon's mean longitude
    final dElong = lMoon - lSun; // mean elongation
    final f = lMoon - node; // argument of latitude

    lon +=
        -1.274 * _sin(mMoon - 2 * dElong) + // evection
        0.658 * _sin(2 * dElong) + // variation
        -0.186 * _sin(mSun) + // yearly equation
        -0.059 * _sin(2 * mMoon - 2 * dElong) +
        -0.057 * _sin(mMoon - 2 * dElong + mSun) +
        0.053 * _sin(mMoon + 2 * dElong) +
        0.046 * _sin(2 * dElong - mSun) +
        0.041 * _sin(mMoon - mSun) +
        -0.035 * _sin(dElong) + // parallactic equation
        -0.031 * _sin(mMoon + mSun) +
        -0.015 * _sin(2 * f - 2 * dElong) +
        0.011 * _sin(mMoon - 4 * dElong);
    lat +=
        -0.173 * _sin(f - 2 * dElong) +
        -0.055 * _sin(mMoon - f - 2 * dElong) +
        -0.046 * _sin(mMoon + f - 2 * dElong) +
        0.033 * _sin(f + 2 * dElong) +
        0.017 * _sin(2 * mMoon + f);
    r += -0.58 * _cos(mMoon - 2 * dElong) - 0.46 * _cos(2 * dElong);

    final obliquity = 23.4393 - 3.563e-7 * d;
    final xe = _cos(lon) * _cos(lat);
    final ye = _sin(lon) * _cos(lat);
    final ze = _sin(lat);
    final xq = xe;
    final yq = ye * _cos(obliquity) - ze * _sin(obliquity);
    final zq = ye * _sin(obliquity) + ze * _cos(obliquity);
    return EquatorialPosition(
      rightAscension: QiblaGeodesy.normalize(_deg(math.atan2(yq, xq))),
      declination: _deg(math.atan2(zq, math.sqrt(xq * xq + yq * yq))),
      distanceKm: r * earthEquatorialRadiusKm,
    );
  }

  /// Shifts a geocentric position to what an observer on the surface sees
  /// (Meeus chapter 40, rigorous form).
  ///
  /// It only matters for the moon, whose parallax is about a degree: seen from
  /// the surface it sits up to a degree lower than from the Earth's centre,
  /// which is exactly the size of error the Sun/Moon tab cannot afford. The
  /// rigorous form is used because Schlyter's shortcut divides by zero for an
  /// observer on the equator.
  static EquatorialPosition topocentric(
    EquatorialPosition geocentric, {
    required double latitude,
    required double localSiderealTime,
    double heightMeters = 0,
  }) {
    final distance = geocentric.distanceKm;
    if (distance == null || distance <= 0) return geocentric;
    final u = _deg(math.atan(0.99664719 * _tan(latitude)));
    final heightRatio = heightMeters / (earthEquatorialRadiusKm * 1000);
    final rhoSin = 0.99664719 * _sin(u) + heightRatio * _sin(latitude);
    final rhoCos = _cos(u) + heightRatio * _cos(latitude);
    final sinParallax = earthEquatorialRadiusKm / distance;
    final hourAngle = localSiderealTime - geocentric.rightAscension;
    final dec = geocentric.declination;

    final denominator = _cos(dec) - rhoCos * sinParallax * _cos(hourAngle);
    final deltaRa = _deg(
      math.atan2(-rhoCos * sinParallax * _sin(hourAngle), denominator),
    );
    final topoDec = _deg(
      math.atan2(
        (_sin(dec) - rhoSin * sinParallax) * _cos(deltaRa),
        denominator,
      ),
    );
    return EquatorialPosition(
      rightAscension: QiblaGeodesy.normalize(
        geocentric.rightAscension + deltaRa,
      ),
      declination: topoDec,
      distanceKm: distance,
    );
  }

  /// Equatorial to horizontal coordinates (Meeus 13.5/13.6), azimuth measured
  /// from NORTH (Meeus measures from south; this adds the 180°).
  ///
  /// Returns the geometric altitude, no refraction.
  static HorizontalPosition equatorialToHorizontal({
    required double rightAscension,
    required double declination,
    required double latitude,
    required double localSiderealTime,
  }) {
    final hourAngle = localSiderealTime - rightAscension;
    final fromSouth = _deg(
      math.atan2(
        _sin(hourAngle),
        _cos(hourAngle) * _sin(latitude) - _tan(declination) * _cos(latitude),
      ),
    );
    final sinAlt =
        _sin(latitude) * _sin(declination) +
        _cos(latitude) * _cos(declination) * _cos(hourAngle);
    return HorizontalPosition(
      azimuth: QiblaGeodesy.normalize(fromSouth + 180),
      altitude: _deg(math.asin(sinAlt.clamp(-1.0, 1.0))),
    );
  }

  /// Atmospheric refraction in degrees for a TRUE (geometric) altitude
  /// (Sæmundsson 1986, with the constant that makes it zero at the zenith).
  ///
  /// Sæmundsson rather than Bennett because Bennett's formula takes the
  /// apparent altitude, which is what we are trying to find. Below −1° the
  /// body is down whichever way it is bent, and the formula heads for its
  /// pole at −5.11°, so it returns 0 there.
  static double refraction(double trueAltitude) {
    if (trueAltitude < -1) return 0;
    final arcMinutes =
        1.02 / _tan(trueAltitude + 10.3 / (trueAltitude + 5.11)) + 0.0019279;
    return math.max(0, arcMinutes) / 60;
  }

  /// The sun as seen from [latitude], [longitude] at [instant], with
  /// refraction. Solar parallax (9 arcseconds) is left out.
  static HorizontalPosition sun(
    DateTime instant, {
    required double latitude,
    required double longitude,
  }) {
    final equatorial = sunEquatorial(julianEphemerisDay(instant));
    final geometric = equatorialToHorizontal(
      rightAscension: equatorial.rightAscension,
      declination: equatorial.declination,
      latitude: latitude,
      localSiderealTime: localSiderealTime(julianDay(instant), longitude),
    );
    return _refracted(geometric);
  }

  /// The moon as seen from [latitude], [longitude] at [instant]: topocentric,
  /// with refraction.
  static HorizontalPosition moon(
    DateTime instant, {
    required double latitude,
    required double longitude,
    double heightMeters = 0,
  }) {
    final lst = localSiderealTime(julianDay(instant), longitude);
    final local = topocentric(
      moonEquatorial(julianEphemerisDay(instant)),
      latitude: latitude,
      localSiderealTime: lst,
      heightMeters: heightMeters,
    );
    final geometric = equatorialToHorizontal(
      rightAscension: local.rightAscension,
      declination: local.declination,
      latitude: latitude,
      localSiderealTime: lst,
    );
    return _refracted(geometric);
  }

  /// Where a vertical stick's shadow points: directly away from the sun.
  static double shadowAzimuth(HorizontalPosition sun) =>
      QiblaGeodesy.normalize(sun.azimuth + 180);

  static HorizontalPosition _refracted(HorizontalPosition geometric) =>
      HorizontalPosition(
        azimuth: geometric.azimuth,
        altitude: geometric.altitude + refraction(geometric.altitude),
      );

  /// Mean obliquity of the ecliptic (Meeus 22.2), degrees.
  static double _meanObliquity(double t) =>
      23 +
      26 / 60 +
      (21.448 - 46.8150 * t - 0.00059 * t * t + 0.001813 * t * t * t) / 3600;

  static double _sin(double deg) => math.sin(deg * math.pi / 180);

  static double _cos(double deg) => math.cos(deg * math.pi / 180);

  static double _tan(double deg) => math.tan(deg * math.pi / 180);

  static double _deg(double rad) => rad * 180 / math.pi;
}
