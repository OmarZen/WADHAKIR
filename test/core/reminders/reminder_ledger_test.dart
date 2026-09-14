import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/reminders/reminder_ledger.dart';
import 'package:wadhakir/core/reminders/reminder_ledger_entry.dart';

void main() {
  group('the wire format', () {
    test('a fired row round-trips every field', () {
      final entry = ReminderLedgerEntry(
        type: ReminderEventType.fired,
        atEpochMs: 1757800005000,
        id: 142,
        dueEpochMs: 1757800000000,
        outcome: ReminderFireOutcome.sounded,
      );

      final back = ReminderLedgerEntry.decodeLine(entry.encodeLine())!;

      expect(back.type, ReminderEventType.fired);
      expect(back.atEpochMs, 1757800005000);
      expect(back.id, 142);
      expect(back.dueEpochMs, 1757800000000);
      expect(back.outcome, ReminderFireOutcome.sounded);
      expect(back.skew, const Duration(seconds: 5));
    });

    test('an armed row round-trips its count, horizon and path', () {
      final entry = ReminderLedgerEntry(
        type: ReminderEventType.armed,
        atEpochMs: 1757800000000,
        count: 300,
        untilEpochMs: 1762900000000,
        detail: 'native',
      );

      final back = ReminderLedgerEntry.decodeLine(entry.encodeLine())!;

      expect(back.count, 300);
      expect(back.untilEpochMs, 1762900000000);
      expect(back.detail, 'native');
      expect(back.skew, isNull, reason: 'no instant to be late against');
    });

    test('one row is always exactly one line', () {
      // The ledger is newline-delimited, so a value carrying a newline would
      // turn one row into two unreadable halves. jsonEncode escapes them; this
      // is the assertion that it is jsonEncode doing the writing.
      final entry = ReminderLedgerEntry(
        type: ReminderEventType.trigger,
        atEpochMs: 1757800000000,
        detail: 'android.intent\nACTION_FAKE',
      );

      expect('\n'.allMatches(entry.encodeLine()).length, 1);
      expect(ReminderLedgerEntry.decodeAll(entry.encodeLine()).length, 1);
    });

    test('a detail longer than the cap is truncated on the way in', () {
      final entry = ReminderLedgerEntry(
        type: ReminderEventType.trigger,
        atEpochMs: 1,
        detail: 'x' * 500,
      );
      // A ring buffer whose row size is unbounded has unknown retention.
      expect(entry.detail!.length, 64);
    });

    test('a row with no type or no timestamp is refused', () {
      expect(ReminderLedgerEntry.decodeLine('{"at":123}'), isNull);
      expect(ReminderLedgerEntry.decodeLine('{"t":"fired"}'), isNull);
      expect(ReminderLedgerEntry.decodeLine('{"t":"nope","at":1}'), isNull);
    });

    test(
      'an unknown outcome degrades to null rather than dropping the row',
      () {
        // A newer build may write an outcome this one has never heard of. The
        // row still says an alarm fired, and that is the part that matters.
        final back = ReminderLedgerEntry.decodeLine(
          '{"t":"fired","at":10,"id":1,"due":5,"o":"teleported"}',
        )!;
        expect(back.type, ReminderEventType.fired);
        expect(back.outcome, isNull);
        expect(back.skew, const Duration(milliseconds: 5));
      },
    );

    test('epoch values that arrived as doubles are accepted', () {
      // A backup file can pass through a tool that renders 10 as 10.0 on its
      // way back — the same coercion BackupValue.fromJson exists for.
      final back = ReminderLedgerEntry.decodeLine(
        '{"t":"fired","at":10,"id":1.0,"due":5.0}',
      )!;
      expect(back.id, 1);
      expect(back.dueEpochMs, 5);
    });

    test('one damaged row costs one row, not the whole ledger', () {
      // The health screen is what a user opens when things are ALREADY going
      // wrong. A parser that refused the file would take it down with it.
      final source = [
        '{"t":"fired","at":1,"id":1,"due":1}',
        'not json at all',
        '',
        '{"t":"fired","at":2,"id":2,"due":2}',
        '{"t":"fired","at":3,', // truncated by a kill mid-write
      ].join('\n');

      final entries = ReminderLedgerEntry.decodeAll(source);

      expect(entries.map((e) => e.id), [1, 2]);
    });
  });

  group('the iOS file store', () {
    late Directory dir;
    late File file;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('wadhakir_ledger_test');
      file = File('${dir.path}/reminder_ledger.ndjson');
    });

    tearDown(() => dir.deleteSync(recursive: true));

    ReminderLedgerEntry row(int at) => ReminderLedgerEntry(
      type: ReminderEventType.fired,
      atEpochMs: at,
      id: at,
      dueEpochMs: at,
    );

    test('appends, and reads back in order', () async {
      final store = FileReminderLedgerStore(fileForTesting: file);
      for (var i = 1; i <= 5; i++) {
        await store.append(row(i));
      }

      expect((await store.read()).map((e) => e.id), [1, 2, 3, 4, 5]);
    });

    test('reads empty when the file has never been written', () async {
      final store = FileReminderLedgerStore(fileForTesting: file);
      expect(await store.read(), isEmpty);
    });

    test('trims to exactly the cap, keeping the NEWEST rows', () async {
      // maxRows is tiny here so the cap is reachable without writing a quarter
      // of a megabyte in a unit test.
      final store = FileReminderLedgerStore(maxRows: 10, fileForTesting: file);
      for (var i = 1; i <= 400; i++) {
        await store.append(row(i));
      }

      final entries = await store.read();

      // Exactly ten, not "about ten". The bound is a row count the retention
      // decision names, and a cap that depends on how long the rows happen to
      // be is not a cap.
      expect(entries.length, 10);
      expect(entries.map((e) => e.id), [
        391,
        392,
        393,
        394,
        395,
        396,
        397,
        398,
        399,
        400,
      ], reason: 'a verdict reads recent behaviour; the oldest rows go first');
    });

    test(
      'the trim leaves every surviving line readable, and no temp file',
      () async {
        // Named for what it actually proves. It cannot prove atomicity — nothing
        // in-process can kill the isolate between the temp write and the rename —
        // so it asserts the observable consequences instead: no line is half of
        // one generation glued to half of another, and no `.tmp` is orphaned.
        final store = FileReminderLedgerStore(
          maxRows: 10,
          fileForTesting: file,
        );
        for (var i = 1; i <= 400; i++) {
          await store.append(row(i));
        }

        final lines = const LineSplitter()
            .convert(file.readAsStringSync())
            .where((l) => l.trim().isNotEmpty);
        for (final line in lines) {
          expect(
            ReminderLedgerEntry.decodeLine(line),
            isNotNull,
            reason: 'unreadable line survived a trim: $line',
          );
        }
        expect(File('${file.path}.tmp').existsSync(), isFalse);
      },
    );

    test('the trim keeps INSERTION order, not timestamp order', () async {
      // These are different rules and the obvious test cannot tell them apart,
      // because rows normally arrive in chronological order. Writing them
      // backwards separates the two: a trim that sorted by `at` would keep
      // ids 1..10 (the newest timestamps); the ledger is append-only and must
      // keep the last ten LINES, which are ids 391..400.
      final store = FileReminderLedgerStore(maxRows: 10, fileForTesting: file);
      for (var i = 1; i <= 400; i++) {
        await store.append(
          ReminderLedgerEntry(
            type: ReminderEventType.fired,
            atEpochMs: 1000000000000 - i * 1000,
            id: i,
            dueEpochMs: 1000000000000 - i * 1000,
          ),
        );
      }

      final entries = await store.read();
      expect(entries.length, 10);
      expect(entries.map((e) => e.id), [
        391,
        392,
        393,
        394,
        395,
        396,
        397,
        398,
        399,
        400,
      ]);
    });

    test('retention is by row count and never against the clock', () async {
      // The Stage 1 defect this rule comes from: a device whose clock jumps
      // forward deleted every row it skipped past, permanently.
      //
      // Sized so the trim's rewrite branch ACTUALLY RUNS — an earlier version
      // appended three rows against a cap of 2,000, never crossed the fast-path
      // guard, and so never exercised the code a date-based prune would live
      // in. Here the rewrite fires repeatedly, with rows dated a century apart
      // in both directions, and the only thing that decides survival is how
      // recently a row was written.
      final store = FileReminderLedgerStore(maxRows: 10, fileForTesting: file);
      const wild = [
        1,
        99999999999999,
        -2208988800000,
        1757800000000,
        4102444800000,
      ];
      for (var i = 0; i < 100; i++) {
        await store.append(
          ReminderLedgerEntry(
            type: ReminderEventType.fired,
            atEpochMs: wild[i % wild.length],
            id: i,
            dueEpochMs: wild[i % wild.length],
          ),
        );
      }

      final entries = await store.read();
      expect(entries.length, 10);
      expect(entries.map((e) => e.id), [
        90,
        91,
        92,
        93,
        94,
        95,
        96,
        97,
        98,
        99,
      ], reason: 'the last ten written, regardless of what they are dated');
      expect(
        entries.map((e) => e.atEpochMs).toSet().length,
        greaterThan(1),
        reason: 'rows from wildly different eras all survived together',
      );
    });

    test('clear empties it', () async {
      final store = FileReminderLedgerStore(fileForTesting: file);
      await store.append(row(1));
      await store.clear();
      expect(await store.read(), isEmpty);
    });
  });

  group('the recording helpers', () {
    test('an armed row carries the count, the horizon and the path', () async {
      final store = InMemoryReminderLedgerStore();
      ReminderLedger.overrideStore(store);
      addTearDown(ReminderLedger.resetForTesting);

      await ReminderLedger.instance.recordArmed(
        count: 300,
        until: DateTime.fromMillisecondsSinceEpoch(1762900000000),
        path: 'native',
        now: DateTime.fromMillisecondsSinceEpoch(1757800000000),
      );

      final entry = store.entries.single;
      expect(entry.type, ReminderEventType.armed);
      expect(entry.count, 300);
      expect(entry.untilEpochMs, 1762900000000);
      expect(entry.detail, 'native');
    });

    test('an empty plan is still recorded', () async {
      // "The app armed nothing on the 3rd" is what makes a week of silence
      // afterwards make sense. Recording only non-empty plans would delete the
      // explanation and keep the symptom.
      final store = InMemoryReminderLedgerStore();
      ReminderLedger.overrideStore(store);
      addTearDown(ReminderLedger.resetForTesting);

      await ReminderLedger.instance.recordArmed(
        count: 0,
        until: null,
        path: 'plugin',
      );

      expect(store.entries.single.count, 0);
      expect(store.entries.single.untilEpochMs, isNull);
    });
  });
}
