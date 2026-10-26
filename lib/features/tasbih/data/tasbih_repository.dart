import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tasbih_models.dart';

/// What [TasbihRepository.load] hands the cubit.
class TasbihStored {
  const TasbihStored({
    required this.snapshot,
    required this.prefs,
    required this.lifetimeTotal,
    required this.migrated,
  });

  final TasbihSnapshot snapshot;
  final TasbihPrefs prefs;
  final int lifetimeTotal;

  /// True when this load built the state from the pre-3.4.4 keys.
  final bool migrated;
}

/// SharedPreferences store for the tasbih, following
/// `floating_dhikr_repository.dart`: one JSON blob per concern, defaults on
/// anything unreadable.
///
/// ## Keys
/// None begins with `tasbih_`: `BackupKeys` copies that prefix as per-dhikr
/// integer counters for the «تسابيح» sheet, and would mistype a string.
///
/// * [stateKey] — the counts. Backup section: worship.
/// * [prefsKey] — the switches. Backup section: settings.
/// * [legacyTotalKey] — the lifetime total, the meaning it has always had.
/// * [legacyCounterKey] / [legacyTargetKey] — still written, as the selected
///   dhikr's count and target, so a downgrade or a backup restored into an
///   older build still shows the number the user was on.
///
/// ## Migration
/// When [stateKey] is missing or unreadable, the old single counter becomes
/// «سبحان الله»'s count. That is also what happens after restoring a backup
/// taken before 3.4.4: restore REPLACES the allowlisted keys, so it removes
/// [stateKey] and puts the legacy keys back, and the next load migrates them
/// again — which is the right answer, since that backup is what the user
/// chose to go back to.
///
/// A [stateKey] written by a NEWER build (a backup from there, restored
/// here) is read as far as this build understands it, and neither migrated
/// over nor rewritten by [load]; see [TasbihSnapshot.decode].
class TasbihRepository {
  TasbihRepository([SharedPreferences? prefs]) : _injected = prefs;

  final SharedPreferences? _injected;

  static const String stateKey = 'electronic_tasbih_state_v2';
  static const String prefsKey = 'electronic_tasbih_prefs_v1';
  static const String legacyCounterKey = 'electronic_tasbih_counter';
  static const String legacyTargetKey = 'electronic_tasbih_target';
  static const String legacyTotalKey = 'electronic_tasbih_total';

  Future<SharedPreferences> _store() async =>
      _injected ?? await SharedPreferences.getInstance();

  /// Reads everything, migrating if needed, and rolls the day over to [now].
  Future<TasbihStored> load(DateTime now) async {
    final store = await _store();
    final today = tasbihDayKey(now);

    final lifetime = _nonNegative(_int(store, legacyTotalKey));
    final prefs = TasbihPrefs.decode(_string(store, prefsKey));

    TasbihSnapshot? snapshot;
    var newer = false;
    final raw = _string(store, stateKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = TasbihSnapshot.decodeVersioned(raw);
        snapshot = decoded.snapshot;
        newer = decoded.newer;
      } catch (e) {
        debugPrint('TasbihRepository: unreadable $stateKey, migrating: $e');
      }
    }

    if (snapshot != null) {
      final rolled = snapshot.rolledTo(today);
      // A newer build's file is left as it is: rewritten here in this
      // build's shape, whatever that build added would be gone before the
      // user had counted a single tasbiha. The first real save does replace
      // it — by then they are counting in this build.
      if (!newer && !identical(rolled, snapshot)) {
        await _writeOnLoad(store, rolled, lifetime);
      }
      return TasbihStored(
        snapshot: rolled,
        prefs: prefs,
        lifetimeTotal: lifetime,
        migrated: false,
      );
    }

    final migrated = migrateLegacy(
      day: today,
      legacyCounter: _int(store, legacyCounterKey),
      legacyTarget: _int(store, legacyTargetKey),
    );
    // Written straight away, so the migration runs once. The legacy keys are
    // left in place: they are the downgrade path.
    await _writeOnLoad(store, migrated, lifetime);
    return TasbihStored(
      snapshot: migrated,
      prefs: prefs,
      lifetimeTotal: lifetime,
      migrated: true,
    );
  }

  /// The pre-3.4.4 single counter, as the first dhikr's progress.
  ///
  /// * The target is the old one, clamped to 1..9999; zero, negative or
  ///   missing becomes 33. A value like 1000 survives and shows as «مخصص».
  /// * The count is taken modulo the target. The old completion dialog could
  ///   be dismissed without resetting, which left counts above the target.
  /// * Only «سبحان الله» inherits it. The old target belonged to the old
  ///   counter; the other adhkar keep their own defaults.
  @visibleForTesting
  static TasbihSnapshot migrateLegacy({
    required String day,
    required int? legacyCounter,
    required int? legacyTarget,
  }) {
    final fresh = TasbihSnapshot.fresh(day);
    final target = legacyTarget == null || legacyTarget < TasbihTargets.min
        ? fresh.items.first.target
        : TasbihTargets.clamp(legacyTarget);
    final count = _nonNegative(legacyCounter) % target;
    return fresh.copyWith(
      items: [
        fresh.items.first.copyWith(count: count, target: target),
        ...fresh.items.skip(1),
      ],
    );
  }

  Future<void> saveState(TasbihSnapshot snapshot, int lifetimeTotal) async {
    await _writeState(await _store(), snapshot, lifetimeTotal);
  }

  Future<void> savePrefs(TasbihPrefs prefs) async {
    final store = await _store();
    await store.setString(prefsKey, prefs.encode());
  }

  /// The writes [load] makes on its own account, the migration and the
  /// rollover. A failure is logged and swallowed: what [load] returns is
  /// still right, the cubit's next save writes it, and until then the next
  /// load simply does the same again. Thrown out of [load], it would leave
  /// the screen loading for good — blank, with every tap ignored.
  Future<void> _writeOnLoad(
    SharedPreferences store,
    TasbihSnapshot snapshot,
    int lifetimeTotal,
  ) async {
    try {
      await _writeState(store, snapshot, lifetimeTotal);
    } catch (e) {
      debugPrint('TasbihRepository: could not write $stateKey on load: $e');
    }
  }

  Future<void> _writeState(
    SharedPreferences store,
    TasbihSnapshot snapshot,
    int lifetimeTotal,
  ) async {
    await store.setString(stateKey, snapshot.encode());
    await store.setInt(legacyCounterKey, snapshot.selected.count);
    await store.setInt(legacyTargetKey, snapshot.selected.target);
    await store.setInt(legacyTotalKey, lifetimeTotal);
  }

  /// A key written with the wrong type (a hand-edited backup) reads as absent
  /// instead of throwing.
  static String? _string(SharedPreferences store, String key) {
    final v = store.get(key);
    return v is String ? v : null;
  }

  static int? _int(SharedPreferences store, String key) {
    final v = store.get(key);
    return v is int ? v : null;
  }

  static int _nonNegative(int? v) => v == null || v < 0 ? 0 : v;
}
