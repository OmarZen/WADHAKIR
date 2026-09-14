/// Enums + identity helpers for the Salah (prayer) tracker.
///
/// The five obligatory (fard) prayers are the de-facto enum across the app,
/// keyed by their Arabic names (الفجر/الظهر/العصر/المغرب/العشاء) — see
/// PrayerTimesModel.nextPrayerName and PrayerTimesCubit._timeAdjustments. The
/// tracker uses the same Arabic literals so logic lines up with the rest of the
/// codebase, while UI labels still come from the l10n `salah_tracker.*` keys.
library;

/// The five daily obligatory prayers, in chronological order.
enum PrayerSlot { fajr, dhuhr, asr, maghrib, isha }

/// Logged status of a single prayer on a single day.
///
/// Persisted as [Enum.index] (clamp-on-read for forward-compat). Only statuses
/// other than [notLogged] are stored; a missing entry reads back as notLogged.
enum PrayerStatus {
  /// Not yet acted on (default / absent in storage).
  notLogged,

  /// Prayed within the prayer's own time window.
  onTime,

  /// Prayed, but after the next prayer's time had entered (same day).
  late,

  /// Made up later, or a past day logged retroactively (قضاء).
  qada,

  /// Not prayed and not yet made up — feeds the make-up counter.
  missed,
}

extension PrayerSlotX on PrayerSlot {
  /// The canonical Arabic name used across the prayer-times code.
  String get arabicName {
    switch (this) {
      case PrayerSlot.fajr:
        return 'الفجر';
      case PrayerSlot.dhuhr:
        return 'الظهر';
      case PrayerSlot.asr:
        return 'العصر';
      case PrayerSlot.maghrib:
        return 'المغرب';
      case PrayerSlot.isha:
        return 'العشاء';
    }
  }

  /// The dot-key suffix for l10n lookups (`salah_tracker.fajr`, …) and for the
  /// English labels — matches the existing `prayer_times.<name>` keys.
  String get key => name;
}

extension PrayerStatusX on PrayerStatus {
  bool get isPrayed =>
      this == PrayerStatus.onTime ||
      this == PrayerStatus.late ||
      this == PrayerStatus.qada;

  bool get isMissed => this == PrayerStatus.missed;
}

/// Whether a Sunnah rawatib falls before (قبلية) or after (بعدية) its fard.
enum RawatibPosition { before, after }

/// The 12 rakʿah of confirmed Sunan Rawatib Muʾakkadah (السنن الرواتب المؤكدة),
/// per the hadiths of Umm Ḥabībah and ʿĀʾishah (RA): two before Fajr, four
/// before and two after Dhuhr, two after Maghrib, and two after Isha. ʿAsr has
/// no muʾakkadah rawatib, so it is intentionally absent. Each unit is tracked
/// independently in the Salah log; persisted by [Enum.name] (stable, tolerant
/// read). Order of declaration is worship order (qabliyyah before baʿdiyyah).
enum RawatibUnit {
  /// ركعتا الفجر القبلية — راتبة الفجر، آكد السنن الرواتب.
  fajrBefore(PrayerSlot.fajr, RawatibPosition.before, 2, emphasized: true),

  /// أربع ركعات قبل الظهر (بتسليمتين).
  dhuhrBefore(PrayerSlot.dhuhr, RawatibPosition.before, 4),

  /// ركعتان بعد الظهر.
  dhuhrAfter(PrayerSlot.dhuhr, RawatibPosition.after, 2),

  /// ركعتان بعد المغرب.
  maghribAfter(PrayerSlot.maghrib, RawatibPosition.after, 2),

  /// ركعتان بعد العشاء.
  ishaAfter(PrayerSlot.isha, RawatibPosition.after, 2);

  const RawatibUnit(
    this.slot,
    this.position,
    this.rakat, {
    this.emphasized = false,
  });

  /// The fard prayer this rawatib belongs to.
  final PrayerSlot slot;

  /// Before (قبلية) or after (بعدية) the fard.
  final RawatibPosition position;

  /// Number of rakʿah in this unit (2 or 4).
  final int rakat;

  /// True for the single most-emphasized rawatib (راتبة الفجر).
  final bool emphasized;

  /// The rawatib units for [slot] in worship order (qabliyyah then baʿdiyyah).
  /// Returns an empty list for ʿAsr, which has no muʾakkadah rawatib.
  static List<RawatibUnit> forSlot(PrayerSlot slot) =>
      RawatibUnit.values.where((u) => u.slot == slot).toList(growable: false);

  /// Resolve a persisted [Enum.name]; null if unknown.
  static RawatibUnit? byName(Object? name) {
    for (final u in RawatibUnit.values) {
      if (u.name == name) return u;
    }
    return null;
  }

  /// Maps a legacy per-prayer sunnah toggle (stored as a [PrayerSlot.name])
  /// onto this prayer's rawatib units, so old logs migrate without data loss.
  /// ʿAsr maps to nothing (it had no real rawatib to begin with).
  static List<RawatibUnit> legacyUnitsForSlotName(Object? slotName) {
    for (final s in PrayerSlot.values) {
      if (s.name == slotName) return forSlot(s);
    }
    return const [];
  }
}
