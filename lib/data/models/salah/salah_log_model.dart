import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';

/// Persisted Salah-tracker record: a per-day log of the five fard prayers
/// (plus optional nawafil) and an outstanding qada (make-up) debt per prayer.
///
/// Storage shape — a single JSON blob under one SharedPreferences key
/// (`AppConstants.salahTrackerLogKey`), mirroring the wird/fasting/azkar
/// repositories. Only entries that differ from the default are stored, so the
/// blob stays tiny (a few bytes per active day):
///
/// ```json
/// {
///   "days":     { "2026-06-15": { "fajr": 1, "asr": 2, "maghrib": 4 } },
///   "sunnah":   { "2026-06-15": ["fajrBefore", "dhuhrBefore", "dhuhrAfter"] },
///   "witr":     ["2026-06-15"],
///   "makeUp":   { "fajr": 12 },
///   "trackNawafil": true
/// }
/// ```
///
/// Inner day-map keys are [PrayerSlot.name] (stable across enum value changes);
/// status values are [PrayerStatus.index] (clamp-on-read). The Sunnah rawatib
/// are tracked per [RawatibUnit] ([rawatib]) — the 12 muʾakkadah rakʿah, each
/// before/after unit independent — under the legacy JSON key `"sunnah"`; older
/// logs that stored bare prayer names migrate transparently on read. Witr is a
/// single nightly prayer ([witrDays]). Streaks and weekly/monthly stats are NOT
/// persisted — they are derived on the fly by `SalahStatsService` over [days].
class SalahLogModel extends Equatable {
  /// 'yyyy-MM-dd' -> { slot: status }. Only non-[PrayerStatus.notLogged]
  /// entries are present.
  final Map<String, Map<PrayerSlot, PrayerStatus>> days;

  /// 'yyyy-MM-dd' -> set of [RawatibUnit]s prayed that day. Empty/absent when
  /// none. Each before/after unit is tracked independently (Fajr's 2 qabliyyah,
  /// Dhuhr's 4 qabliyyah + 2 baʿdiyyah, Maghrib's & Isha's 2 baʿdiyyah).
  final Map<String, Set<RawatibUnit>> rawatib;

  /// Day keys on which the Witr prayer was performed.
  final Set<String> witrDays;

  /// Outstanding qada debt per fard prayer (>= 0). Legacy debt entered by the
  /// user plus auto-increments when a day's prayer is marked missed.
  final Map<PrayerSlot, int> makeUp;

  /// Whether the optional Sunnah/Witr rows are shown and tracked.
  final bool trackNawafil;

  const SalahLogModel({
    required this.days,
    required this.rawatib,
    required this.witrDays,
    required this.makeUp,
    required this.trackNawafil,
  });

  factory SalahLogModel.defaultSettings() => const SalahLogModel(
    days: {},
    rawatib: {},
    witrDays: {},
    makeUp: {},
    trackNawafil: false,
  );

  // ── Date key helper ───────────────────────────────────────────────────────

  /// Midnight-normalized 'yyyy-MM-dd' key (matches how PrayerTimesCubit and
  /// main.dart key prayer days). Use everywhere a [days]/[rawatib] key is built.
  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ── Reads ─────────────────────────────────────────────────────────────────

  PrayerStatus fardStatus(String dayKey, PrayerSlot slot) =>
      days[dayKey]?[slot] ?? PrayerStatus.notLogged;

  /// Whether the rawatib [unit] was prayed on [dayKey].
  bool rawatibDone(String dayKey, RawatibUnit unit) =>
      rawatib[dayKey]?.contains(unit) ?? false;

  /// How many of [slot]'s rawatib units were prayed on [dayKey] — 0..N, where N
  /// is the slot's unit count (Dhuhr 2; Fajr/Maghrib/Isha 1; Asr 0).
  int rawatibDoneCount(String dayKey, PrayerSlot slot) {
    final set = rawatib[dayKey];
    if (set == null) return 0;
    return RawatibUnit.forSlot(slot).where(set.contains).length;
  }

  /// Whether the Witr prayer was performed on [dayKey].
  bool witrDone(String dayKey) => witrDays.contains(dayKey);

  int makeUpFor(PrayerSlot slot) => makeUp[slot] ?? 0;

  int get totalMakeUp =>
      makeUp.values.fold(0, (sum, v) => sum + (v < 0 ? 0 : v));

  /// All five fard statuses for [dayKey] (notLogged for unlogged ones).
  Map<PrayerSlot, PrayerStatus> statusesFor(String dayKey) => {
    for (final slot in PrayerSlot.values) slot: fardStatus(dayKey, slot),
  };

  // ── Immutable updates (the cubit orchestrates make-up deltas) ──────────────

  /// Returns a copy with [slot] on [dayKey] set to [status]. Removes the entry
  /// (and the day, if it becomes empty) when [status] is notLogged.
  SalahLogModel setFard(String dayKey, PrayerSlot slot, PrayerStatus status) {
    final newDays = {
      for (final e in days.entries)
        e.key: Map<PrayerSlot, PrayerStatus>.of(e.value),
    };
    final dayMap = newDays.putIfAbsent(dayKey, () => {});
    if (status == PrayerStatus.notLogged) {
      dayMap.remove(slot);
      if (dayMap.isEmpty) newDays.remove(dayKey);
    } else {
      dayMap[slot] = status;
    }
    return copyWith(days: newDays);
  }

  /// Returns a copy with the rawatib [unit] on [dayKey] set to [done].
  SalahLogModel setRawatib(String dayKey, RawatibUnit unit, bool done) {
    final newRawatib = {
      for (final e in rawatib.entries) e.key: Set<RawatibUnit>.of(e.value),
    };
    final set = newRawatib.putIfAbsent(dayKey, () => {});
    if (done) {
      set.add(unit);
    } else {
      set.remove(unit);
      if (set.isEmpty) newRawatib.remove(dayKey);
    }
    return copyWith(rawatib: newRawatib);
  }

  /// Returns a copy with the Witr prayer on [dayKey] set to [done].
  SalahLogModel setWitr(String dayKey, bool done) {
    final newWitr = Set<String>.of(witrDays);
    if (done) {
      newWitr.add(dayKey);
    } else {
      newWitr.remove(dayKey);
    }
    return copyWith(witrDays: newWitr);
  }

  /// Returns a copy with the qada debt of [slot] set to [value] (floored at 0).
  SalahLogModel setMakeUp(PrayerSlot slot, int value) {
    final newMakeUp = Map<PrayerSlot, int>.of(makeUp);
    final v = value < 0 ? 0 : value;
    if (v == 0) {
      newMakeUp.remove(slot);
    } else {
      newMakeUp[slot] = v;
    }
    return copyWith(makeUp: newMakeUp);
  }

  /// Returns a copy with [delta] added to the qada debt of [slot] (floored at 0).
  SalahLogModel adjustMakeUp(PrayerSlot slot, int delta) =>
      setMakeUp(slot, makeUpFor(slot) + delta);

  SalahLogModel copyWith({
    Map<String, Map<PrayerSlot, PrayerStatus>>? days,
    Map<String, Set<RawatibUnit>>? rawatib,
    Set<String>? witrDays,
    Map<PrayerSlot, int>? makeUp,
    bool? trackNawafil,
  }) {
    return SalahLogModel(
      days: days ?? this.days,
      rawatib: rawatib ?? this.rawatib,
      witrDays: witrDays ?? this.witrDays,
      makeUp: makeUp ?? this.makeUp,
      trackNawafil: trackNawafil ?? this.trackNawafil,
    );
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'days': {
      for (final day in days.entries)
        if (day.value.isNotEmpty)
          day.key: {
            for (final e in day.value.entries)
              if (e.value != PrayerStatus.notLogged) e.key.name: e.value.index,
          },
    },
    // Legacy JSON key kept as "sunnah" for storage compat; values are now
    // [RawatibUnit.name]s rather than bare prayer names.
    'sunnah': {
      for (final day in rawatib.entries)
        if (day.value.isNotEmpty)
          day.key: day.value.map((u) => u.name).toList(),
    },
    'witr': witrDays.toList(),
    'makeUp': {
      for (final e in makeUp.entries)
        if (e.value > 0) e.key.name: e.value,
    },
    'trackNawafil': trackNawafil,
  };

  factory SalahLogModel.fromJson(Map<String, dynamic> json) {
    final rawDays = (json['days'] as Map?) ?? const {};
    final days = <String, Map<PrayerSlot, PrayerStatus>>{};
    rawDays.forEach((dayKey, value) {
      if (value is! Map) return;
      final dayMap = <PrayerSlot, PrayerStatus>{};
      value.forEach((slotName, statusIndex) {
        final slot = _slotByName(slotName);
        if (slot == null) return;
        final idx = (statusIndex is int ? statusIndex : 0).clamp(
          0,
          PrayerStatus.values.length - 1,
        );
        final status = PrayerStatus.values[idx];
        if (status != PrayerStatus.notLogged) dayMap[slot] = status;
      });
      if (dayMap.isNotEmpty) days[dayKey as String] = dayMap;
    });

    final rawSunnah = (json['sunnah'] as Map?) ?? const {};
    final rawatib = <String, Set<RawatibUnit>>{};
    rawSunnah.forEach((dayKey, value) {
      if (value is! List) return;
      final set = <RawatibUnit>{};
      for (final n in value) {
        // New format: a RawatibUnit name. Legacy format (pre-3.4): a bare
        // PrayerSlot name representing "this prayer's sunnah" — expand it to
        // that prayer's rawatib units so old logs migrate without data loss.
        final unit = RawatibUnit.byName(n);
        if (unit != null) {
          set.add(unit);
        } else {
          set.addAll(RawatibUnit.legacyUnitsForSlotName(n));
        }
      }
      if (set.isNotEmpty) rawatib[dayKey as String] = set;
    });

    final rawWitr = (json['witr'] as List?) ?? const [];
    final witrDays = <String>{
      for (final d in rawWitr)
        if (d is String) d,
    };

    final rawMakeUp = (json['makeUp'] as Map?) ?? const {};
    final makeUp = <PrayerSlot, int>{};
    rawMakeUp.forEach((slotName, count) {
      final slot = _slotByName(slotName);
      if (slot == null) return;
      final c = count is int ? count : 0;
      if (c > 0) makeUp[slot] = c;
    });

    return SalahLogModel(
      days: days,
      rawatib: rawatib,
      witrDays: witrDays,
      makeUp: makeUp,
      // Tolerant read: a wrong-typed value falls back instead of throwing, so
      // one bad field never discards the whole log.
      trackNawafil: json['trackNawafil'] is bool
          ? json['trackNawafil'] as bool
          : false,
    );
  }

  static PrayerSlot? _slotByName(Object? name) {
    for (final s in PrayerSlot.values) {
      if (s.name == name) return s;
    }
    return null;
  }

  @override
  List<Object?> get props => [days, rawatib, witrDays, makeUp, trackNawafil];

  @override
  String toString() =>
      'SalahLogModel(days: ${days.length}, makeUp: $totalMakeUp, '
      'trackNawafil: $trackNawafil)';
}
