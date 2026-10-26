import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'tasbih_catalog.dart';

/// The four ways to count. Stored by [name], so the order here is free to
/// change but the names are not.
enum TasbihMode {
  beads,
  tap,
  ring,
  focus;

  /// An unknown or missing value — a backup from a newer build, a hand-edited
  /// file — opens on [tap], the mode closest to the pre-3.4.4 screen.
  static TasbihMode fromName(Object? name) {
    for (final mode in values) {
      if (mode.name == name) return mode;
    }
    return TasbihMode.tap;
  }
}

/// Bounds for a target. 9999 matches `NumberStepperField`'s default ceiling.
abstract final class TasbihTargets {
  static const int min = 1;
  static const int max = 9999;

  /// The chips in the settings sheet. Anything else shows as «مخصص».
  static const List<int> presets = [33, 99, 100];

  static int clamp(int value) => value.clamp(min, max);
}

/// The local calendar day as `yyyy-MM-dd`, built from [DateTime]'s own fields.
///
/// Not `DateFormat`: that follows the app's locale, and a key that came out in
/// Arabic-Indic digits on one launch and Western on the next would read as a
/// new day and wipe today's totals.
String tasbihDayKey(DateTime local) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-'
      '${two(local.day)}';
}

/// Where one dhikr stands.
class DhikrProgress extends Equatable {
  const DhikrProgress({
    required this.id,
    required this.count,
    required this.target,
    required this.roundsToday,
  });

  factory DhikrProgress.fresh(TasbihDhikr dhikr) => DhikrProgress(
    id: dhikr.id,
    count: 0,
    target: dhikr.defaultTarget,
    roundsToday: 0,
  );

  final String id;

  /// Into the current round, always `0 <= count < target`.
  final int count;
  final int target;

  /// Rounds finished since local midnight.
  final int roundsToday;

  double get progress => target <= 0 ? 0 : (count / target).clamp(0.0, 1.0);

  DhikrProgress copyWith({int? count, int? target, int? roundsToday}) =>
      DhikrProgress(
        id: id,
        count: count ?? this.count,
        target: target ?? this.target,
        roundsToday: roundsToday ?? this.roundsToday,
      );

  Map<String, Object> toJson() => {'c': count, 't': target, 'r': roundsToday};

  /// Field by field, so one bad value costs that value and not the dhikr.
  factory DhikrProgress.fromJson(TasbihDhikr dhikr, Object? raw) {
    final fresh = DhikrProgress.fresh(dhikr);
    if (raw is! Map) return fresh;
    final t = raw['t'];
    final target = t is int && t >= TasbihTargets.min
        ? TasbihTargets.clamp(t)
        : fresh.target;
    final c = raw['c'];
    final count = c is int && c >= 0 ? c % target : 0;
    final r = raw['r'];
    return DhikrProgress(
      id: dhikr.id,
      count: count,
      target: target,
      roundsToday: r is int && r >= 0 ? r : 0,
    );
  }

  @override
  List<Object?> get props => [id, count, target, roundsToday];
}

/// How the tasbih behaves. Stored as `electronic_tasbih_prefs_v1`.
class TasbihPrefs extends Equatable {
  const TasbihPrefs({
    this.mode = TasbihMode.tap,
    this.vibrate = true,
    this.sound = false,
    this.autoAdvance = false,
    this.keepScreenOn = true,
  });

  // Why these defaults:
  //  * vibrate on — the old screen vibrated on every tap, with no switch.
  //  * sound off — people count in the masjid.
  //  * auto-advance off — someone coming from the old single counter keeps
  //    the flow they know: a round ends, the same dhikr starts again.
  //  * keep the screen on — a screen that sleeps mid-count is the commonest
  //    complaint about counting apps.
  final TasbihMode mode;
  final bool vibrate;
  final bool sound;
  final bool autoAdvance;
  final bool keepScreenOn;

  TasbihPrefs copyWith({
    TasbihMode? mode,
    bool? vibrate,
    bool? sound,
    bool? autoAdvance,
    bool? keepScreenOn,
  }) => TasbihPrefs(
    mode: mode ?? this.mode,
    vibrate: vibrate ?? this.vibrate,
    sound: sound ?? this.sound,
    autoAdvance: autoAdvance ?? this.autoAdvance,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
  );

  String encode() => jsonEncode({
    'mode': mode.name,
    'vibrate': vibrate,
    'sound': sound,
    'autoAdvance': autoAdvance,
    'keepScreenOn': keepScreenOn,
  });

  /// Each field decodes on its own: one bad value falls back to its default
  /// without taking the user's other choices with it.
  static TasbihPrefs decode(String? raw) {
    const d = TasbihPrefs();
    if (raw == null || raw.isEmpty) return d;
    Object? json;
    try {
      json = jsonDecode(raw);
    } catch (_) {
      return d;
    }
    if (json is! Map) return d;
    bool flag(String key, bool fallback) {
      final v = json is Map ? json[key] : null;
      return v is bool ? v : fallback;
    }

    return TasbihPrefs(
      mode: TasbihMode.fromName(json['mode']),
      vibrate: flag('vibrate', d.vibrate),
      sound: flag('sound', d.sound),
      autoAdvance: flag('autoAdvance', d.autoAdvance),
      keepScreenOn: flag('keepScreenOn', d.keepScreenOn),
    );
  }

  @override
  List<Object?> get props => [mode, vibrate, sound, autoAdvance, keepScreenOn];
}

/// The counts, as stored in `electronic_tasbih_state_v2`:
/// `{v:2, selected, day, todayTotal, dhikr:{id:{c,t,r}}}`.
///
/// The lifetime total is NOT in here. It stays in `electronic_tasbih_total`,
/// the key it has always lived in, so a downgrade or an old backup still
/// reads the right number.
class TasbihSnapshot extends Equatable {
  const TasbihSnapshot({
    required this.items,
    required this.selectedIndex,
    required this.day,
    required this.todayTotal,
  });

  static const int version = 2;

  factory TasbihSnapshot.fresh(String day) => TasbihSnapshot(
    items: [for (final d in TasbihCatalog.all) DhikrProgress.fresh(d)],
    selectedIndex: 0,
    day: day,
    todayTotal: 0,
  );

  /// In [TasbihCatalog.all] order, one entry per dhikr.
  final List<DhikrProgress> items;
  final int selectedIndex;

  /// [tasbihDayKey] of the day [todayTotal] and every `roundsToday` belong to.
  final String day;
  final int todayTotal;

  DhikrProgress get selected => items[selectedIndex];

  TasbihSnapshot copyWith({
    List<DhikrProgress>? items,
    int? selectedIndex,
    String? day,
    int? todayTotal,
  }) => TasbihSnapshot(
    items: items ?? this.items,
    selectedIndex: selectedIndex ?? this.selectedIndex,
    day: day ?? this.day,
    todayTotal: todayTotal ?? this.todayTotal,
  );

  /// A new day: today's total and every dhikr's rounds start again. The
  /// counts are kept, so someone mid-round across midnight loses nothing.
  TasbihSnapshot rolledTo(String newDay) {
    if (newDay == day) return this;
    return TasbihSnapshot(
      items: [for (final p in items) p.copyWith(roundsToday: 0)],
      selectedIndex: selectedIndex,
      day: newDay,
      todayTotal: 0,
    );
  }

  String encode() => jsonEncode({
    'v': version,
    'selected': selected.id,
    'day': day,
    'todayTotal': todayTotal,
    'dhikr': {for (final p in items) p.id: p.toJson()},
  });

  /// Throws [FormatException] when [raw] is not a v2 document at all, which
  /// the repository answers by migrating from the legacy keys. Within a valid
  /// document every field degrades on its own; an id this build does not know
  /// is dropped, and a dhikr the file does not mention starts fresh (that is
  /// how a dhikr appended to the catalog arrives).
  ///
  /// A document from a NEWER build (`v` above [version]) — a backup taken
  /// there and restored here — is read the same way, best effort, and never
  /// counts as unreadable: "unreadable" means migrating from the legacy keys,
  /// which would swap the user's counts for the old single counter's.
  static TasbihSnapshot decode(String raw) => decodeVersioned(raw).snapshot;

  /// [decode], also saying whether the document came from a newer build, so
  /// the repository can leave such a file as it found it.
  static ({TasbihSnapshot snapshot, bool newer}) decodeVersioned(String raw) {
    final json = jsonDecode(raw);
    if (json is! Map) {
      throw const FormatException('not an electronic_tasbih_state_v2 value');
    }
    final v = json['v'];
    final newer = v is int && v > version;
    if (!newer && (v != version || json['dhikr'] is! Map)) {
      throw const FormatException('not an electronic_tasbih_state_v2 value');
    }
    // Only a newer build's file can get here without a map; its counts are
    // then out of reach, and every dhikr starts fresh.
    final dhikr = json['dhikr'];
    final selected = TasbihCatalog.indexOf('${json['selected']}');
    final day = json['day'];
    final today = json['todayTotal'];
    final snapshot = TasbihSnapshot(
      items: [
        for (final d in TasbihCatalog.all)
          DhikrProgress.fromJson(d, dhikr is Map ? dhikr[d.id] : null),
      ],
      selectedIndex: selected < 0 ? 0 : selected,
      day: day is String ? day : '',
      todayTotal: today is int && today >= 0 ? today : 0,
    );
    return (snapshot: snapshot, newer: newer);
  }

  @override
  List<Object?> get props => [items, selectedIndex, day, todayTotal];
}
