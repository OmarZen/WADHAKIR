import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/reminders/reminder_ledger_entry.dart';
import 'package:wadhakir/features/backup/models/backup_envelope.dart';
import 'package:wadhakir/features/backup/services/backup_service.dart';

/// The reminder ledger travels **out** of a device in a backup file and never
/// back **into** one.
///
/// That asymmetry is the whole design, and it is invisible from either side on
/// its own: `BackupEnvelope.diagnostics` looks like just another field, and
/// `BackupService.restore` looks complete. What makes it correct is that the
/// rows are outside `data`, where restore physically cannot reach them.
///
/// Restoring one device's ledger onto another would make the health screen
/// diagnose hardware it has never run on — confidently, in one calm sentence,
/// with nothing on screen to suggest it might be wrong.
final _exportedAt = DateTime.utc(2026, 9, 13, 11, 0);

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  for (final entry in values.entries) {
    final value = entry.value;
    if (value is String) await prefs.setString(entry.key, value);
    if (value is bool) await prefs.setBool(entry.key, value);
  }
  return prefs;
}

List<Map<String, Object?>> _ledger(int rows) => [
  for (var i = 0; i < rows; i++)
    ReminderLedgerEntry(
      type: ReminderEventType.fired,
      atEpochMs: 1757800000000 + i * 1000,
      id: 100 + i,
      dueEpochMs: 1757800000000 + i * 1000,
      outcome: ReminderFireOutcome.sounded,
    ).toJson(),
];

void main() {
  test('the ledger rides out in the file', () async {
    final service = BackupService(await _prefs({'text_scale_pref': 'x'}));

    final envelope = service.buildEnvelope(
      appVersion: '3.3.2+22',
      exportedAt: _exportedAt,
      diagnostics: _ledger(3),
    );
    final back = BackupEnvelope.decode(envelope.encode());

    expect(back.diagnostics.length, 3);
    expect(back.diagnostics.first['t'], 'fired');
    expect(back.diagnostics.first['id'], 100);
  });

  test('the rows survive as readable ledger entries', () async {
    final service = BackupService(await _prefs({}));

    final encoded = service
        .buildEnvelope(
          appVersion: '3.3.2+22',
          exportedAt: _exportedAt,
          diagnostics: _ledger(5),
        )
        .encode();

    // What a support conversation actually needs: the rows, parseable by the
    // same code the device uses.
    final rows = BackupEnvelope.decode(encoded).diagnostics;
    final entries = [
      for (final row in rows) ReminderLedgerEntry.decodeLine(jsonEncode(row))!,
    ];

    expect(entries.length, 5);
    expect(entries.first.outcome, ReminderFireOutcome.sounded);
  });

  test('a restore never writes a single diagnostics row', () async {
    final prefs = await _prefs({'text_scale_pref': 'device'});
    final service = BackupService(prefs);

    final incoming = BackupEnvelope.decode(
      BackupEnvelope(
        schemaVersion: BackupEnvelope.currentSchemaVersion,
        appVersion: '3.3.2+22',
        exportedAt: _exportedAt,
        data: const {},
        diagnostics: _ledger(50),
      ).encode(),
    );

    final before = prefs.getKeys().toSet();
    final report = await service.restore(incoming);

    // Not one key gained. `written` counts `data` only, and `data` is empty.
    expect(report.written, 0);
    final gained = prefs.getKeys().toSet().difference(before);
    expect(
      gained,
      isEmpty,
      reason: 'diagnostics leaked into SharedPreferences',
    );
  });

  test('no ledger means no key at all in the file', () async {
    final service = BackupService(await _prefs({'text_scale_pref': 'x'}));

    final encoded = service
        .buildEnvelope(appVersion: '3.3.2+22', exportedAt: _exportedAt)
        .encode();

    // A device that has never fired a reminder writes a file byte-identical in
    // shape to one written before this field existed.
    expect(jsonDecode(encoded), isNot(contains('diagnostics')));
    expect(BackupEnvelope.decode(encoded).diagnostics, isEmpty);
  });

  test('a file from before this field reads fine', () {
    final legacy = jsonEncode({
      'format': BackupEnvelope.plainFormat,
      'schemaVersion': 1,
      'appVersion': '3.3.1+21',
      'exportedAt': _exportedAt.toIso8601String(),
      'data': <String, Object?>{},
    });

    expect(BackupEnvelope.decode(legacy).diagnostics, isEmpty);
  });

  test('a damaged diagnostics block never blocks a restore', () {
    // The rest of the parser refuses damaged input because writing it back
    // would corrupt real records. Nothing writes these rows anywhere, so the
    // worst a bad one can do is not be read — and a restore that refused to run
    // over a diagnostics fault would fail at the moment someone has just lost
    // their phone.
    for (final broken in <Object>[
      'not a list',
      42,
      [1, 2, 3],
      [
        {'t': 'fired'},
        'junk',
      ],
    ]) {
      final source = jsonEncode({
        'format': BackupEnvelope.plainFormat,
        'schemaVersion': 1,
        'appVersion': '3.3.2+22',
        'exportedAt': _exportedAt.toIso8601String(),
        'data': <String, Object?>{},
        'diagnostics': broken,
      });

      expect(
        () => BackupEnvelope.decode(source),
        returnsNormally,
        reason: 'decode threw on diagnostics: $broken',
      );
    }
  });

  test('the ledger is not counted as backup content', () async {
    // `export` refuses when `data` is empty. A device with a full ledger and no
    // worship data must still be told it has nothing to back up, rather than
    // handed a file containing only its own diagnostics.
    final service = BackupService(await _prefs({}));

    final envelope = service.buildEnvelope(
      appVersion: '3.3.2+22',
      exportedAt: _exportedAt,
      diagnostics: _ledger(2000),
    );

    expect(envelope.data, isEmpty);
    expect(service.summarize(envelope.data).isEmpty, isTrue);
  });
}
