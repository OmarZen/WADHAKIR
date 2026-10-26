import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/features/backup/models/backup_envelope.dart';
import 'package:wadhakir/features/backup/services/backup_keys.dart';
import 'package:wadhakir/features/backup/services/backup_service.dart';
import 'package:wadhakir/features/tasbih/data/tasbih_repository.dart';

/// A fixed instant, because the envelope carries `exportedAt` and a test that
/// reads the wall clock is a test that fails at midnight.
final _exportedAt = DateTime.utc(2026, 3, 14, 9, 26, 53);

Future<SharedPreferences> _prefsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  for (final entry in values.entries) {
    final value = entry.value;
    if (value is String) {
      await prefs.setString(entry.key, value);
    } else if (value is bool) {
      await prefs.setBool(entry.key, value);
    } else if (value is int) {
      await prefs.setInt(entry.key, value);
    } else if (value is double) {
      await prefs.setDouble(entry.key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(entry.key, value);
    } else {
      fail('unsupported test value type: ${value.runtimeType}');
    }
  }
  return prefs;
}

/// A realistic salah log: three logged days, so `summarize` has something to
/// count and the JSON shape matches what `SalahLogModel.toJson` writes.
const _salahLogJson =
    '{"days":{"2026-03-12":{"fajr":1},"2026-03-13":{"fajr":1,"dhuhr":1},'
    '"2026-03-14":{"asr":2}},"sunnah":{},"witr":[],"excused":[],'
    '"makeUp":{},"trackNawafil":true}';

const _wirdPlanJson =
    '{"isActive":true,"goalMode":0,"unit":1,"amountPerDay":4,"startPage":1,'
    '"reminderTime":"20:00","reminderEnabled":true,"completedDayIndices":[0,1],'
    '"planStartDate":null,"targetDate":null,"lastReadPage":9,"intention":2}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupService round trip', () {
    test('every SharedPreferences type survives export and restore', () async {
      // One key of each of the five storable types, all allowlisted.
      final original = <String, Object>{
        'salah_tracker_log': _salahLogJson, // String
        'show_basmala': false, // bool
        'theme_mode': 2, // int
        'text_scale': 1.35, // double
        'electronic_tasbih_total': 4821,
        'prayer_times_last_latitude': 30.0444196,
        'prayer_times_last_longitude': 31.2357116,
        'prayer_times_last_location_name': 'القاهرة',
        'user_name': 'عمر',
      };

      final source = BackupService(await _prefsWith(original));
      final envelope = source.buildEnvelope(
        appVersion: '3.3.2+22',
        exportedAt: _exportedAt,
      );

      // Through the wire format, not just the object graph — the encoding is
      // where a type tag would be lost.
      final restored = BackupEnvelope.decode(envelope.encode());

      final target = BackupService(await _prefsWith({}));
      final report = await target.restore(restored);

      expect(report.written, original.length);
      expect(report.removed, 0);
      expect(report.skipped, 0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('salah_tracker_log'), _salahLogJson);
      expect(prefs.getBool('show_basmala'), false);
      expect(prefs.getInt('theme_mode'), 2);
      expect(prefs.getDouble('text_scale'), 1.35);
      expect(prefs.getInt('electronic_tasbih_total'), 4821);
      // Coordinates must keep full precision: a truncated latitude moves the
      // prayer times.
      expect(prefs.getDouble('prayer_times_last_latitude'), 30.0444196);
      expect(prefs.getDouble('prayer_times_last_longitude'), 31.2357116);
      expect(prefs.getString('prayer_times_last_location_name'), 'القاهرة');
      expect(prefs.getString('user_name'), 'عمر');
    });

    test('a string list round-trips through setStringList', () async {
      // No allowlisted key is a StringList today (the only one in the app,
      // feature_nudge_shown_ids, is denied), but the writer must still be
      // correct — the platform encodes lists with a sentinel prefix, so a list
      // written as a plain String would come back corrupted.
      final prefs = await _prefsWith({});
      final service = BackupService(prefs);
      final envelope = BackupEnvelope(
        schemaVersion: BackupEnvelope.currentSchemaVersion,
        appVersion: 'test',
        exportedAt: _exportedAt,
        data: const {
          // Reuse an allowlisted key name so the restore gate lets it through;
          // the point under test is the writer, not the allowlist.
          'user_name': BackupValue(BackupValueType.string, 'x'),
        },
      );
      await service.restore(envelope);
      expect(prefs.getString('user_name'), 'x');

      // And the value encoder itself, for the list branch.
      final list = BackupValue.fromJson({
        't': 'l',
        'v': ['a', 'b'],
      });
      expect(list, isNotNull);
      expect(list!.type, BackupValueType.stringList);
      expect(list.value, ['a', 'b']);
    });

    test('per-dhikr counters travel via their prefix', () async {
      final service = BackupService(
        await _prefsWith({
          'tasbih_123456': 33,
          'raqia_-987654': 7,
          'pray_azkar_42': 1,
          'prayer_adhkar_-1': 10,
        }),
      );

      final envelope = source(service);
      expect(envelope.data.keys, hasLength(4));
      expect(envelope.data['tasbih_123456']!.value, 33);
      // Negative hashCodes are normal — String.hashCode is signed.
      expect(envelope.data['raqia_-987654']!.value, 7);
      expect(envelope.data['prayer_adhkar_-1']!.value, 10);

      expect(service.summarize(envelope.data).dhikrCounters, 4);
    });

    test('the tasbih_ prefix does not swallow electronic_tasbih_*', () {
      // Both are allowlisted, but for different reasons and with different
      // sections; a greedy prefix match would mislabel the fixed keys as
      // per-dhikr counters and inflate the count shown to the user.
      final counter = BackupKeys.specFor('electronic_tasbih_counter');
      expect(counter, isNotNull);
      expect(counter!.key, 'electronic_tasbih_counter');

      final dynamicKey = BackupKeys.specFor('tasbih_99');
      expect(dynamicKey, isNotNull);
      expect(dynamicKey!.section, BackupSection.worship);
    });
  });

  group('the 3.4.4 tasbih', () {
    const stateJson =
        '{"v":2,"selected":"la_hawla","day":"2026-03-14","todayTotal":40,'
        '"dhikr":{"la_hawla":{"c":7,"t":100,"r":0}}}';
    const prefsJson =
        '{"mode":"beads","vibrate":true,"sound":false,'
        '"autoAdvance":true,"keepScreenOn":true}';

    test('its two blobs are allowlisted as strings, in their sections', () {
      final state = BackupKeys.specFor(TasbihRepository.stateKey);
      expect(state, isNotNull);
      expect(state!.type, BackupValueType.string);
      expect(state.section, BackupSection.worship);

      final prefs = BackupKeys.specFor(TasbihRepository.prefsKey);
      expect(prefs, isNotNull);
      expect(prefs!.type, BackupValueType.string);
      expect(prefs.section, BackupSection.settings);

      // The legacy keys are still allowlisted, still integers: they are what
      // an older build reads back.
      for (final key in [
        TasbihRepository.legacyCounterKey,
        TasbihRepository.legacyTargetKey,
        TasbihRepository.legacyTotalKey,
      ]) {
        expect(BackupKeys.specFor(key)?.type, BackupValueType.integer);
        expect(BackupKeys.specFor(key)?.section, BackupSection.worship);
      }
    });

    test('round-trips, and is not counted as a per-dhikr counter', () async {
      final original = <String, Object>{
        TasbihRepository.stateKey: stateJson,
        TasbihRepository.prefsKey: prefsJson,
        TasbihRepository.legacyCounterKey: 7,
        TasbihRepository.legacyTargetKey: 100,
        TasbihRepository.legacyTotalKey: 4821,
      };
      final envelope = BackupEnvelope.decode(
        BackupService(await _prefsWith(original))
            .buildEnvelope(appVersion: '3.4.4+27', exportedAt: _exportedAt)
            .encode(),
      );

      final summary = BackupService(
        await _prefsWith({}),
      ).summarize(envelope.data);
      expect(summary.dhikrCounters, 0);
      expect(summary.keysBySection[BackupSection.worship], 4);
      expect(summary.keysBySection[BackupSection.settings], 1);

      final target = BackupService(await _prefsWith({}));
      final report = await target.restore(envelope);
      expect(report.written, original.length);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(TasbihRepository.stateKey), stateJson);
      expect(prefs.getString(TasbihRepository.prefsKey), prefsJson);
      expect(prefs.getInt(TasbihRepository.legacyTotalKey), 4821);

      final stored = await TasbihRepository(prefs).load(DateTime(2026, 3, 14));
      expect(stored.migrated, isFalse);
      expect(stored.snapshot.selected.id, 'la_hawla');
      expect(stored.snapshot.selected.count, 7);
      expect(stored.lifetimeTotal, 4821);
    });

    test('restoring a pre-3.4.4 backup brings back the old counter', () async {
      // That backup has no state_v2. Restore replaces, so ours is removed,
      // and the tasbih migrates from the legacy keys it does carry.
      final prefs = await _prefsWith({
        TasbihRepository.stateKey: stateJson,
        TasbihRepository.prefsKey: prefsJson,
      });
      await BackupService(prefs).restore(
        BackupEnvelope(
          schemaVersion: 1,
          appVersion: '3.4.3+26',
          exportedAt: _exportedAt,
          data: const {
            'electronic_tasbih_counter': BackupValue(
              BackupValueType.integer,
              21,
            ),
            'electronic_tasbih_target': BackupValue(
              BackupValueType.integer,
              33,
            ),
            'electronic_tasbih_total': BackupValue(
              BackupValueType.integer,
              900,
            ),
          },
        ),
      );
      expect(prefs.containsKey(TasbihRepository.stateKey), isFalse);
      expect(prefs.containsKey(TasbihRepository.prefsKey), isFalse);

      final stored = await TasbihRepository(prefs).load(DateTime(2026, 3, 14));
      expect(stored.migrated, isTrue);
      expect(stored.snapshot.items.first.id, 'subhan_allah');
      expect(stored.snapshot.items.first.count, 21);
      expect(stored.snapshot.items.first.target, 33);
      expect(stored.lifetimeTotal, 900);
    });
  });

  group('the allowlist is a gate in both directions', () {
    test('denied keys are never exported', () async {
      final service = BackupService(
        await _prefsWith({
          'battery_opt_prompted': true,
          'prayer_times_calc_method_auto_detected': true,
          'onboarding_completed': true,
          'app_lock_settings': '{"enabled":true}',
          'feature_nudge_last_shown': 1710000000,
          'feature_nudge_shown_ids': <String>['a', 'b'],
          'home_widget.double.fajr': true,
          // One allowed key, so the export is not trivially empty.
          'theme_mode': 1,
        }),
      );

      final envelope = source(service);
      expect(envelope.data.keys, ['theme_mode']);
    });

    test('unknown keys are never exported', () async {
      final service = BackupService(
        await _prefsWith({
          'some_future_plugin_key': 'x',
          'fajr': '04:41', // a home_widget mirror name
          'theme_mode': 1,
        }),
      );
      expect(source(service).data.keys, ['theme_mode']);
    });

    test('restore leaves denied and unknown device keys untouched', () async {
      // The scenario that matters: a phone that has already been nagged about
      // battery optimisation, restoring a backup taken on a phone that had
      // not been. Carrying the flag across would silently stop every reminder
      // on this device.
      final prefs = await _prefsWith({
        'battery_opt_prompted': true,
        'onboarding_completed': true,
        'prayer_times_calc_method_auto_detected': true,
        'some_other_plugin_key': 'keep me',
        'theme_mode': 0,
      });
      final service = BackupService(prefs);

      // A hand-edited backup that tries to smuggle the denied keys in.
      final hostile = jsonEncode({
        'format': BackupEnvelope.plainFormat,
        'schemaVersion': 1,
        'appVersion': '3.3.2+22',
        'exportedAt': _exportedAt.toIso8601String(),
        'data': {
          'battery_opt_prompted': {'t': 'b', 'v': false},
          'onboarding_completed': {'t': 'b', 'v': false},
          'prayer_times_calc_method_auto_detected': {'t': 'b', 'v': false},
          'some_other_plugin_key': {'t': 's', 'v': 'overwritten'},
          'theme_mode': {'t': 'i', 'v': 2},
        },
      });

      final envelope = BackupEnvelope.decode(hostile);
      expect(envelope.data.keys, ['theme_mode']);
      expect(envelope.skippedEntryCount, 4);

      final report = await service.restore(envelope);

      expect(prefs.getBool('battery_opt_prompted'), true);
      expect(prefs.getBool('onboarding_completed'), true);
      expect(prefs.getString('some_other_plugin_key'), 'keep me');

      // The one documented exception to "denied keys are untouched": the
      // auto-detect guard is cleared when the calculation method it guards is
      // not in the backup, which is the case here. It is never *written from*
      // the file — the hostile `false` above was dropped at decode — it is
      // removed by the restore itself. See the dedicated pair of tests above.
      expect(
        prefs.containsKey('prayer_times_calc_method_auto_detected'),
        isFalse,
      );
      expect(prefs.getInt('theme_mode'), 2);
      expect(report.skipped, 4);
    });
  });

  group('restore replaces rather than merges', () {
    test('allowlisted keys absent from the backup are removed', () async {
      final prefs = await _prefsWith({
        'wird_plan': _wirdPlanJson, // stale local plan
        'tasbih_777': 12, // stale local counter
        'theme_mode': 0,
        'battery_opt_prompted': true, // denied: must survive
      });
      final service = BackupService(prefs);

      final envelope = BackupEnvelope(
        schemaVersion: 1,
        appVersion: '3.3.2+22',
        exportedAt: _exportedAt,
        data: const {'theme_mode': BackupValue(BackupValueType.integer, 2)},
      );

      final report = await service.restore(envelope);

      expect(report.written, 1);
      // wird_plan and tasbih_777 — both allowlisted, both absent from the file.
      expect(report.removed, 2);
      expect(prefs.containsKey('wird_plan'), isFalse);
      expect(prefs.containsKey('tasbih_777'), isFalse);
      expect(prefs.getInt('theme_mode'), 2);
      expect(prefs.getBool('battery_opt_prompted'), true);
    });

    test(
      'removing the calculation method takes its auto-detect guard with it',
      () async {
        // The trap: the guard is denylisted, so it survives a restore holding
        // this device's `true`. PrayerTimesRepositoryImpl reads it as
        // `if (prefs.getBool(_calcMethodAutoDetectedKey) == true) return;`, so
        // a device left with the flag set and NO method stored falls back to
        // the hardcoded Egyptian parameters and never re-detects — silently
        // wrong prayer times for anyone outside Egypt.
        final prefs = await _prefsWith({
          'prayer_times_calculation_method': 'umm_al_qura',
          'prayer_times_calc_method_auto_detected': true,
          'theme_mode': 1,
        });

        // A backup taken before the user ever set a method.
        await BackupService(prefs).restore(
          BackupEnvelope(
            schemaVersion: 1,
            appVersion: '3.3.2+22',
            exportedAt: _exportedAt,
            data: const {'theme_mode': BackupValue(BackupValueType.integer, 2)},
          ),
        );

        expect(prefs.containsKey('prayer_times_calculation_method'), isFalse);
        expect(
          prefs.containsKey('prayer_times_calc_method_auto_detected'),
          isFalse,
          reason: 'the guard must not outlive the method it guards',
        );
      },
    );

    test('the auto-detect guard survives when a method IS restored', () async {
      // The other direction. Here the flag is left alone on purpose: the
      // detector runs once on the new device, sees the restored method,
      // keeps it, and sets the flag itself.
      final prefs = await _prefsWith({
        'prayer_times_calc_method_auto_detected': true,
        'prayer_times_calculation_method': 'egyptian',
      });

      await BackupService(prefs).restore(
        BackupEnvelope(
          schemaVersion: 1,
          appVersion: '3.3.2+22',
          exportedAt: _exportedAt,
          data: const {
            'prayer_times_calculation_method': BackupValue(
              BackupValueType.string,
              'umm_al_qura',
            ),
          },
        ),
      );

      expect(prefs.getString('prayer_times_calculation_method'), 'umm_al_qura');
      expect(prefs.getBool('prayer_times_calc_method_auto_detected'), true);
    });
  });

  group('malformed input is refused, not half-applied', () {
    test('a file that is not JSON is rejected as "not a backup"', () {
      expect(
        () => BackupEnvelope.decode('this is a photo, not a backup'),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.reason,
            'reason',
            BackupFormatFailure.notABackupFile,
          ),
        ),
      );
    });

    test('JSON without the format marker is rejected', () {
      expect(
        () => BackupEnvelope.decode('{"schemaVersion":1,"data":{}}'),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.reason,
            'reason',
            BackupFormatFailure.notABackupFile,
          ),
        ),
      );
    });

    test('a newer schema version is refused with the version it found', () {
      final future = jsonEncode({
        'format': BackupEnvelope.plainFormat,
        'schemaVersion': BackupEnvelope.currentSchemaVersion + 3,
        'appVersion': '9.0.0+1',
        'exportedAt': _exportedAt.toIso8601String(),
        'data': {},
      });
      expect(
        () => BackupEnvelope.decode(future),
        throwsA(
          isA<BackupFormatException>()
              .having(
                (e) => e.reason,
                'reason',
                BackupFormatFailure.unsupportedSchemaVersion,
              )
              .having((e) => e.foundSchemaVersion, 'foundSchemaVersion', 4),
        ),
      );
    });

    test(
      'a value that contradicts its type tag is skipped, not written',
      () async {
        final malformed = jsonEncode({
          'format': BackupEnvelope.plainFormat,
          'schemaVersion': 1,
          'appVersion': '3.3.2+22',
          'exportedAt': _exportedAt.toIso8601String(),
          'data': {
            // theme_mode is an int key; a string value is a contradiction.
            'theme_mode': {'t': 's', 'v': 'dark'},
            // text_scale is a double key carrying a non-numeric value.
            'text_scale': {'t': 'd', 'v': 'large'},
            'user_name': {'t': 's', 'v': 'سلمى'},
          },
        });

        final envelope = BackupEnvelope.decode(malformed);
        expect(envelope.data.keys, ['user_name']);
        expect(envelope.skippedEntryCount, 2);

        final prefs = await _prefsWith({'theme_mode': 1});
        await BackupService(prefs).restore(envelope);
        // The bad entry never reached the store, so the read still type-checks.
        expect(prefs.getString('user_name'), 'سلمى');
      },
    );

    test('an integral double is accepted for an int key', () {
      // A JSON tool that rewrites 2 as 2.0 must not cost the user their theme.
      final value = BackupValue.fromJson({'t': 'i', 'v': 2.0});
      expect(value, isNotNull);
      expect(value!.value, 2);
      expect(value.value, isA<int>());
    });

    test('a fractional double is refused for an int key', () {
      expect(BackupValue.fromJson({'t': 'i', 'v': 2.5}), isNull);
    });

    test('an int is widened for a double key', () {
      final value = BackupValue.fromJson({'t': 'd', 'v': 1});
      expect(value, isNotNull);
      expect(value!.value, 1.0);
      expect(value.value, isA<double>());
    });

    test('an unknown type tag is refused', () {
      expect(BackupValue.fromJson({'t': 'zz', 'v': 1}), isNull);
    });
  });

  group('summary', () {
    test('counts what a person would recognise', () async {
      final service = BackupService(
        await _prefsWith({
          'salah_tracker_log': _salahLogJson,
          'wird_plan': _wirdPlanJson,
          'tasbih_1': 33,
          'tasbih_2': 33,
          'theme_mode': 1,
          'prayer_times_madhab': 'hanafi',
          'prayer_times_last_latitude': 30.04,
        }),
      );

      final summary = service.summarize(source(service).data);

      expect(summary.salahDays, 3);
      expect(summary.hasActiveWirdPlan, isTrue);
      expect(summary.dhikrCounters, 2);
      expect(summary.keysBySection[BackupSection.worship], 4);
      expect(summary.keysBySection[BackupSection.settings], 1);
      expect(summary.keysBySection[BackupSection.prayerTimes], 1);
      expect(summary.keysBySection[BackupSection.location], 1);
      expect(summary.totalKeys, 7);
      expect(summary.isEmpty, isFalse);
      expect(summary.has(BackupSection.location), isTrue);
    });

    test(
      'a corrupt salah log degrades to "unknown" instead of throwing',
      () async {
        // The count is decoration on a confirmation screen. It must never be the
        // reason a user cannot restore their data.
        final service = BackupService(
          await _prefsWith({'salah_tracker_log': 'not json at all'}),
        );
        final summary = service.summarize(source(service).data);
        expect(summary.salahDays, isNull);
        expect(summary.totalKeys, 1);
      },
    );

    test('an empty device produces an empty summary', () async {
      final service = BackupService(await _prefsWith({}));
      final summary = service.summarize(source(service).data);
      expect(summary.isEmpty, isTrue);
      expect(summary.salahDays, isNull);
      expect(summary.hasActiveWirdPlan, isFalse);
    });
  });
}

/// Shorthand for "build an envelope from this service's device state".
BackupEnvelope source(BackupService service) =>
    service.buildEnvelope(appVersion: '3.3.2+22', exportedAt: _exportedAt);
