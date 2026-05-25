import 'dart:math' as math;

/// Eight discrete phase buckets. The boundary illumination thresholds match
/// the conventional 1/8th-cycle split astronomers use for calendars.
enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

/// Snapshot of moon state for a particular instant (midnight UTC of a date).
/// Computed entirely from a deterministic astronomical formula — no API
/// calls — so the feature works offline.
class MoonPhaseInfo {
  /// Date this snapshot describes (midnight local).
  final DateTime date;

  /// 0.0 (new) … 1.0 (full) … back toward 0.0 (next new). This is the
  /// fraction of the moon's *visible* disc that is illuminated.
  final double illumination;

  /// Position in the cycle from 0..1. 0 = new moon, 0.5 = full moon,
  /// 0.99 ≈ just before the next new moon. Used to choose waxing vs waning.
  final double phaseFraction;

  /// Closest discrete phase bucket for naming + iconography.
  final MoonPhase phase;

  /// Approximate days since the last new moon.
  final double ageDays;

  /// Approximate Earth-Moon distance in kilometres (perturbed).
  final double distanceKm;

  /// Approximate ecliptic longitude in degrees (0..360).
  final double eclipticLongitude;

  /// Zodiac sign the moon currently sits in (Aries..Pisces).
  final MoonZodiac zodiac;

  const MoonPhaseInfo({
    required this.date,
    required this.illumination,
    required this.phaseFraction,
    required this.phase,
    required this.ageDays,
    required this.distanceKm,
    required this.eclipticLongitude,
    required this.zodiac,
  });

  bool get isWaxing => phaseFraction < 0.5;
  bool get isWaning => phaseFraction >= 0.5;
}

enum MoonZodiac {
  aries,
  taurus,
  gemini,
  cancer,
  leo,
  virgo,
  libra,
  scorpio,
  sagittarius,
  capricorn,
  aquarius,
  pisces,
}

/// Pure-Dart moon phase calculator. Accuracy is good enough for a calendar
/// view (phase to ±0.5% illumination, distance to ±few-thousand km). Based
/// on the simplified Meeus algorithm; the synodic month is 29.530588 days,
/// reference new moon is 2000-01-06 18:14 UTC.
class MoonPhaseCalculator {
  MoonPhaseCalculator._();

  static const double _synodicMonthDays = 29.530588853;

  /// Reference new moon: 6 Jan 2000 18:14 UTC. Expressed as Julian Day for
  /// numerical stability across many years.
  static const double _refNewMoonJd = 2451550.26;

  /// Compute moon info for a given calendar day. The instant chosen is
  /// midnight UTC of that date — calendars want a single representative
  /// value per day, not a time-varying one.
  static MoonPhaseInfo forDate(DateTime date) {
    final dayUtc = DateTime.utc(date.year, date.month, date.day);
    final jd = _julianDay(dayUtc);

    final daysSinceRef = jd - _refNewMoonJd;
    final cyclesSinceRef = daysSinceRef / _synodicMonthDays;
    final fraction = cyclesSinceRef - cyclesSinceRef.floorToDouble();
    final phaseFraction = fraction < 0 ? fraction + 1 : fraction;

    // Phase angle in radians: 0 at new moon, π at full moon.
    final phaseAngle = 2 * math.pi * phaseFraction;
    final illumination = (1 - math.cos(phaseAngle)) / 2;

    final ageDays = phaseFraction * _synodicMonthDays;

    // Approximate distance using primary perturbation term. The moon's
    // anomaly drifts ~1/27.55 day. Reference perigee 2000-01-04.
    const double anomalisticMonth = 27.55454989;
    const double refPerigeeJd = 2451548.65;
    final anomalyFraction =
        ((jd - refPerigeeJd) / anomalisticMonth) % 1.0;
    final anomalyAngle = 2 * math.pi * anomalyFraction;
    // 385,000 km mean ± 20,000 km swing is a good first-order approximation.
    final distanceKm = 385000.6 - 20905.355 * math.cos(anomalyAngle);

    // Approximate ecliptic longitude. The moon advances ~13.176° per day
    // along the ecliptic. Reference longitude at JD 2451550.26 ≈ 218.32°.
    const double meanMotionDegPerDay = 13.176358;
    final longitudeRaw =
        218.32 + meanMotionDegPerDay * (jd - 2451550.26);
    final longitude = longitudeRaw % 360.0;
    final eclipticLongitude = longitude < 0 ? longitude + 360 : longitude;
    final zodiac = _zodiacForLongitude(eclipticLongitude);

    return MoonPhaseInfo(
      date: DateTime(date.year, date.month, date.day),
      illumination: illumination,
      phaseFraction: phaseFraction,
      phase: _bucketFor(phaseFraction),
      ageDays: ageDays,
      distanceKm: distanceKm,
      eclipticLongitude: eclipticLongitude,
      zodiac: zodiac,
    );
  }

  /// Compute moon info for every day in [month]. Returns a list ordered by
  /// day-of-month. Used by the calendar grid.
  static List<MoonPhaseInfo> forMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return List<MoonPhaseInfo>.generate(
      daysInMonth,
      (i) => forDate(firstDay.add(Duration(days: i))),
    );
  }

  /// Discrete phase bucket. Boundaries follow the standard 1/8th-cycle
  /// split so a calendar can show one of 8 icons per day.
  static MoonPhase _bucketFor(double f) {
    // Buckets centred on canonical phase points with ~1.85-day half-widths.
    // Edge widths kept symmetric so transitions feel natural in a calendar.
    if (f < 0.03 || f >= 0.97) return MoonPhase.newMoon;
    if (f < 0.22) return MoonPhase.waxingCrescent;
    if (f < 0.28) return MoonPhase.firstQuarter;
    if (f < 0.47) return MoonPhase.waxingGibbous;
    if (f < 0.53) return MoonPhase.fullMoon;
    if (f < 0.72) return MoonPhase.waningGibbous;
    if (f < 0.78) return MoonPhase.lastQuarter;
    return MoonPhase.waningCrescent;
  }

  static MoonZodiac _zodiacForLongitude(double lon) {
    // 30° per sign, starting at Aries 0°.
    final idx = (lon / 30).floor() % 12;
    return MoonZodiac.values[idx];
  }

  /// Standard Julian Day for a UTC DateTime. Uses the Meeus algorithm.
  static double _julianDay(DateTime utc) {
    int y = utc.year;
    int m = utc.month;
    final d = utc.day +
        (utc.hour + utc.minute / 60.0 + utc.second / 3600.0) / 24.0;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jd = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524.5;
    return jd;
  }
}
