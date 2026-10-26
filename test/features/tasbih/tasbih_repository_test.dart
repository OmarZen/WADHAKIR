import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/features/tasbih/data/tasbih_catalog.dart';
import 'package:wadhakir/features/tasbih/data/tasbih_models.dart';
import 'package:wadhakir/features/tasbih/data/tasbih_repository.dart';

import 'write_failing_prefs.dart';

/// Where a user's counting lives on disk, and how 3.4.3's single counter
/// becomes 3.4.4's per-dhikr state without losing a tasbiha.

final _now = DateTime(2026, 10, 25, 14, 30);
const _today = '2026-10-25';

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<TasbihStored> _load(Map<String, Object> values) async =>
    TasbihRepository(await _prefs(values)).load(_now);

DhikrProgress _first(TasbihStored s) => s.snapshot.items.first;

/// A v2 document with [subhanCount] on the first dhikr.
String _v2({
  int subhanCount = 3,
  int subhanTarget = 33,
  int rounds = 0,
  String day = _today,
  int todayTotal = 0,
  String selected = 'subhan_allah',
}) => jsonEncode({
  'v': 2,
  'selected': selected,
  'day': day,
  'todayTotal': todayTotal,
  'dhikr': {
    'subhan_allah': {'c': subhanCount, 't': subhanTarget, 'r': rounds},
  },
});

void main() {
  group('a fresh install', () {
    test('opens on defaults and writes state_v2 at once', () async {
      final stored = await _load({});
      expect(stored.migrated, isTrue);
      expect(stored.lifetimeTotal, 0);
      expect(stored.snapshot.selectedIndex, 0);
      expect(stored.snapshot.day, _today);
      expect(stored.snapshot.todayTotal, 0);
      for (var i = 0; i < TasbihCatalog.all.length; i++) {
        final p = stored.snapshot.items[i];
        expect(p.id, TasbihCatalog.all[i].id);
        expect(p.count, 0);
        expect(p.target, TasbihCatalog.all[i].defaultTarget);
        expect(p.roundsToday, 0);
      }
      expect(stored.prefs, const TasbihPrefs());

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(TasbihRepository.stateKey), isNotNull);
    });
  });

  group('migrating the pre-3.4.4 counter', () {
    test('21 of 33 with a lifetime of 4821', () async {
      final stored = await _load({
        'electronic_tasbih_counter': 21,
        'electronic_tasbih_target': 33,
        'electronic_tasbih_total': 4821,
      });
      expect(stored.migrated, isTrue);
      expect(_first(stored).count, 21);
      expect(_first(stored).target, 33);
      expect(stored.lifetimeTotal, 4821);

      // The legacy keys are the downgrade path: never deleted.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('electronic_tasbih_counter'), 21);
      expect(prefs.getInt('electronic_tasbih_target'), 33);
      expect(prefs.getInt('electronic_tasbih_total'), 4821);
    });

    test('a count past the target wraps: 40 of 33 becomes 7', () async {
      // The old dialog could be dismissed without resetting.
      final stored = await _load({
        'electronic_tasbih_counter': 40,
        'electronic_tasbih_target': 33,
      });
      expect(_first(stored).count, 7);
    });

    test('a custom 1000 survives as a custom target', () async {
      final stored = await _load({
        'electronic_tasbih_counter': 250,
        'electronic_tasbih_target': 1000,
      });
      expect(_first(stored).target, 1000);
      expect(_first(stored).count, 250);
      expect(TasbihTargets.presets, isNot(contains(1000)));
    });

    test('zero, negative or absurd targets are repaired', () async {
      expect(_first(await _load({'electronic_tasbih_target': 0})).target, 33);
      expect(_first(await _load({'electronic_tasbih_target': -5})).target, 33);
      expect(
        _first(await _load({'electronic_tasbih_target': 50000})).target,
        TasbihTargets.max,
      );
    });

    test('only the first dhikr inherits the old counter', () async {
      final stored = await _load({
        'electronic_tasbih_counter': 10,
        'electronic_tasbih_target': 1000,
      });
      for (final p in stored.snapshot.items.skip(1)) {
        expect(p.count, 0);
        expect(p.target, TasbihCatalog.byId(p.id)!.defaultTarget);
      }
    });

    test('a corrupt state_v2 migrates instead of throwing', () async {
      for (final junk in ['{not json', '[]', '{"v":1,"dhikr":{}}', '42']) {
        final stored = await _load({
          TasbihRepository.stateKey: junk,
          'electronic_tasbih_counter': 12,
          'electronic_tasbih_target': 100,
        });
        expect(stored.migrated, isTrue, reason: junk);
        expect(_first(stored).count, 12, reason: junk);
        expect(_first(stored).target, 100, reason: junk);
      }
    });

    test('a valid state_v2 is never re-migrated', () async {
      final stored = await _load({
        TasbihRepository.stateKey: _v2(subhanCount: 3),
        // Stale legacy values that must not win.
        'electronic_tasbih_counter': 21,
        'electronic_tasbih_target': 99,
      });
      expect(stored.migrated, isFalse);
      expect(_first(stored).count, 3);
      expect(_first(stored).target, 33);
    });

    test('restoring a pre-3.4.4 backup migrates again', () async {
      // Restore replaces the allowlisted keys: state_v2 is absent from such a
      // backup, so it is removed, and the legacy keys come back.
      final prefs = await _prefs({
        TasbihRepository.stateKey: _v2(subhanCount: 30),
      });
      final repository = TasbihRepository(prefs);
      expect(_first(await repository.load(_now)).count, 30);

      await prefs.remove(TasbihRepository.stateKey);
      await prefs.setInt('electronic_tasbih_counter', 12);
      await prefs.setInt('electronic_tasbih_target', 100);

      final stored = await repository.load(_now);
      expect(stored.migrated, isTrue);
      expect(_first(stored).count, 12);
      expect(_first(stored).target, 100);
    });
  });

  group('decoding state_v2', () {
    test(
      'an unknown dhikr id is dropped; a missing one starts fresh',
      () async {
        final stored = await _load({
          TasbihRepository.stateKey: jsonEncode({
            'v': 2,
            'selected': 'la_hawla',
            'day': _today,
            'todayTotal': 9,
            'dhikr': {
              'la_hawla': {'c': 4, 't': 100, 'r': 1},
              'from_the_future': {'c': 1, 't': 7, 'r': 0},
            },
          }),
        });
        expect(stored.snapshot.items, hasLength(TasbihCatalog.all.length));
        expect(stored.snapshot.selected.id, 'la_hawla');
        expect(stored.snapshot.selected.count, 4);
        expect(stored.snapshot.selected.roundsToday, 1);
        expect(stored.snapshot.todayTotal, 9);
        expect(stored.snapshot.items.first.count, 0);
      },
    );

    test(
      'a newer build\'s state is read, never migrated over or rewritten',
      () async {
        // A backup taken in a later version and restored here. Treated as
        // corrupt, it would be migrated from the legacy keys and written over
        // at once, and the user's counts would be gone.
        final newer = jsonEncode({
          'v': 3,
          'selected': 'la_hawla',
          'day': '2026-10-24',
          'todayTotal': 12,
          'dhikr': {
            'subhan_allah': {'c': 5, 't': 33, 'r': 1, 'later': true},
            'la_hawla': {'c': 4, 't': 100, 'r': 2},
          },
          'somethingNew': [1, 2, 3],
        });
        final prefs = await _prefs({
          TasbihRepository.stateKey: newer,
          'electronic_tasbih_counter': 21,
          'electronic_tasbih_target': 99,
        });
        final stored = await TasbihRepository(prefs).load(_now);

        expect(stored.migrated, isFalse);
        expect(stored.snapshot.selected.id, 'la_hawla');
        expect(stored.snapshot.selected.count, 4);
        expect(stored.snapshot.selected.target, 100);
        expect(_first(stored).count, 5);
        // Rolled to today in memory...
        expect(stored.snapshot.day, _today);
        expect(stored.snapshot.todayTotal, 0);
        // ...but nothing on disk is touched until the user counts.
        expect(prefs.getString(TasbihRepository.stateKey), newer);
        expect(prefs.getInt('electronic_tasbih_counter'), 21);
        expect(prefs.getInt('electronic_tasbih_target'), 99);
      },
    );

    test(
      'a newer build\'s state this build cannot read still is not migrated',
      () async {
        const newer = '{"v":7,"dhikr":["a list now"]}';
        final prefs = await _prefs({
          TasbihRepository.stateKey: newer,
          'electronic_tasbih_counter': 21,
        });
        final stored = await TasbihRepository(prefs).load(_now);
        expect(stored.migrated, isFalse);
        expect(_first(stored).count, 0);
        expect(prefs.getString(TasbihRepository.stateKey), newer);
      },
    );

    test('an unknown selected id falls back to the first dhikr', () async {
      final stored = await _load({
        TasbihRepository.stateKey: _v2(selected: 'gone'),
      });
      expect(stored.snapshot.selectedIndex, 0);
    });

    test('round-trips through encode', () {
      final snapshot = TasbihSnapshot.fresh(
        _today,
      ).copyWith(selectedIndex: 4, todayTotal: 77);
      expect(TasbihSnapshot.decode(snapshot.encode()), snapshot);
    });
  });

  group('the day', () {
    test('rolls over on load: today clears, counts stay', () async {
      final stored = await _load({
        TasbihRepository.stateKey: _v2(
          subhanCount: 5,
          rounds: 2,
          day: '2026-10-24',
          todayTotal: 71,
        ),
      });
      expect(stored.snapshot.day, _today);
      expect(stored.snapshot.todayTotal, 0);
      expect(_first(stored).roundsToday, 0);
      expect(_first(stored).count, 5);

      // And the rollover is written, so it is not repeated on every open.
      final prefs = await SharedPreferences.getInstance();
      final saved = TasbihSnapshot.decode(
        prefs.getString(TasbihRepository.stateKey)!,
      );
      expect(saved.day, _today);
      expect(saved.todayTotal, 0);
    });

    test('the key is built from fields, in Western digits', () {
      expect(tasbihDayKey(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
      expect(tasbihDayKey(DateTime(987, 12, 31)), '0987-12-31');
    });
  });

  group('prefs', () {
    test('round-trip', () async {
      final prefs = await _prefs({});
      final repository = TasbihRepository(prefs);
      const custom = TasbihPrefs(
        mode: TasbihMode.beads,
        vibrate: false,
        sound: true,
        autoAdvance: true,
        keepScreenOn: false,
      );
      await repository.savePrefs(custom);
      expect((await repository.load(_now)).prefs, custom);
    });

    test('an unknown mode opens on tap', () {
      expect(TasbihPrefs.decode('{"mode":"hologram"}').mode, TasbihMode.tap);
      expect(TasbihMode.fromName(null), TasbihMode.tap);
    });

    test('one bad field costs only that field', () {
      final prefs = TasbihPrefs.decode(
        '{"mode":"ring","vibrate":"yes","sound":true,"autoAdvance":1}',
      );
      expect(prefs.mode, TasbihMode.ring);
      expect(prefs.vibrate, isTrue, reason: 'default');
      expect(prefs.sound, isTrue);
      expect(prefs.autoAdvance, isFalse, reason: 'default');
      expect(TasbihPrefs.decode('nonsense'), const TasbihPrefs());
    });

    test('defaults: tap, vibrate on, sound off, no auto-advance, awake', () {
      const d = TasbihPrefs();
      expect(d.mode, TasbihMode.tap);
      expect(d.vibrate, isTrue);
      expect(d.sound, isFalse);
      expect(d.autoAdvance, isFalse);
      expect(d.keepScreenOn, isTrue);
    });
  });

  test('saving mirrors the selected dhikr into the legacy keys', () async {
    final prefs = await _prefs({});
    final repository = TasbihRepository(prefs);
    final snapshot = TasbihSnapshot.fresh(_today);
    final items = [...snapshot.items];
    items[3] = items[3].copyWith(count: 42, target: 100);
    await repository.saveState(
      snapshot.copyWith(items: items, selectedIndex: 3),
      999,
    );
    expect(prefs.getInt('electronic_tasbih_counter'), 42);
    expect(prefs.getInt('electronic_tasbih_target'), 100);
    expect(prefs.getInt('electronic_tasbih_total'), 999);
  });

  group('a store that refuses writes', () {
    // load() writes on its own account (the migration, the rollover). A
    // failure there must not escape: the cubit would sit loading for good.
    test('still migrates, and says what it read', () async {
      final store = WriteFailingPrefs({
        'electronic_tasbih_counter': 21,
        'electronic_tasbih_target': 33,
        'electronic_tasbih_total': 4821,
      });
      final stored = await TasbihRepository(store).load(_now);
      expect(store.failedWrites, greaterThan(0));
      expect(stored.migrated, isTrue);
      expect(_first(stored).count, 21);
      expect(stored.lifetimeTotal, 4821);
    });

    test('still rolls the day over', () async {
      final store = WriteFailingPrefs({
        TasbihRepository.stateKey: _v2(
          subhanCount: 5,
          day: '2026-10-24',
          todayTotal: 71,
        ),
      });
      final stored = await TasbihRepository(store).load(_now);
      expect(store.failedWrites, greaterThan(0));
      expect(stored.snapshot.day, _today);
      expect(stored.snapshot.todayTotal, 0);
      expect(_first(stored).count, 5);
    });
  });

  test('a mistyped legacy key reads as absent instead of throwing', () async {
    final stored = await _load({
      'electronic_tasbih_counter': 'twenty',
      'electronic_tasbih_total': 'lots',
    });
    expect(_first(stored).count, 0);
    expect(stored.lifetimeTotal, 0);
  });
}
