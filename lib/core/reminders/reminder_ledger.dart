import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wadhakir/core/reminders/reminder_ledger_entry.dart';

/// How many rows the ledger keeps.
///
/// Bounded by **count only**, never by date. Pruning against `now` is the trap
/// that already cost this project a defect once: a device whose clock jumps
/// forward — a bad NTP sync, a user setting the date to check something — would
/// delete every row it skipped past, permanently, and the evidence the health
/// screen exists to read would be gone exactly when something was wrong enough
/// to change the clock. See `PrayerAlarmStore`'s missing `pruneExpired`.
///
/// 2,000 rows is roughly 250 KB and sixty to ninety days of real use: about
/// five fired rows a day, one armed row per reschedule, and a lapsed row only
/// when something actually fails.
const int kReminderLedgerMaxRows = 2000;

/// A floor on how small one NDJSON row can be.
///
/// `{"t":"armed","at":1757800000000}` is 32 bytes with its newline, and every
/// row carries at least those two fields. Used only as a fast path: below
/// `maxRows * this` the file cannot possibly hold `maxRows` rows, so there is
/// nothing to count. Deliberately an under-estimate — it is a lower bound on
/// row size, and getting it wrong in the other direction would let the ledger
/// grow past its cap unchecked.
const int _minRowBytes = 30;

/// Append-only storage for [ReminderLedgerEntry], with two implementations
/// because the ledger has two writers.
///
/// ## Why this is an interface and not a class with an `if (Platform)` in it
///
/// On Android the file is owned by **Kotlin**. `PrayerAlarmReceiver` fires with
/// the app closed and no Flutter engine alive, and the row it writes — an alarm
/// arriving, and how late — is the single most valuable row in the ledger and
/// the one Dart can never write. So on Android, Dart does not open the file at
/// all: it asks Kotlin, which owns the only writer, and two processes' worth of
/// code append through one lock to one document.
///
/// On iOS there is no native path, so Dart owns the file outright.
///
/// One interface, two writers — not two designs. Everything above this layer
/// reads a `List<ReminderLedgerEntry>` and cannot tell which platform produced
/// it.
abstract interface class ReminderLedgerStore {
  /// Appends one row. Never throws.
  Future<void> append(ReminderLedgerEntry entry);

  /// Every row, oldest first. Returns empty for any failure.
  Future<List<ReminderLedgerEntry>> read();

  /// Empties the ledger. Used by the "forget this" affordance and by tests.
  Future<void> clear();
}

/// The Android store: Kotlin owns the file, Dart asks.
///
/// Deliberately thin. The method channel is the same one the alarm bridge
/// already uses (`PrayerAlarmBridge.CHANNEL_NAME`), so this adds two cases to
/// an existing handler rather than a second channel with its own lifecycle.
class MethodChannelReminderLedgerStore implements ReminderLedgerStore {
  /// The same channel `NativePrayerAlarmGateway` talks to.
  static const MethodChannel channel = MethodChannel(
    'com.bloom.wadhakir/prayer_alarms',
  );

  const MethodChannelReminderLedgerStore();

  @override
  Future<void> append(ReminderLedgerEntry entry) async {
    try {
      await channel.invokeMethod<void>('ledgerAppend', entry.toJson());
    } catch (e) {
      // A ledger that cannot be written must never take a reminder down with
      // it. This whole feature is diagnostics; it has no claim on the fire
      // path's reliability budget.
      log('📓 ReminderLedger.append failed: $e');
    }
  }

  @override
  Future<List<ReminderLedgerEntry>> read() async {
    try {
      final raw = await channel.invokeMethod<String>('ledgerRead');
      if (raw == null || raw.isEmpty) return const [];
      return ReminderLedgerEntry.decodeAll(raw);
    } catch (e) {
      log('📓 ReminderLedger.read failed: $e');
      return const [];
    }
  }

  @override
  Future<void> clear() async {
    try {
      await channel.invokeMethod<void>('ledgerClear');
    } catch (e) {
      log('📓 ReminderLedger.clear failed: $e');
    }
  }
}

/// The iOS store: an NDJSON file in the app's documents directory.
///
/// Not device-protected storage — iOS has no such concept, and no iOS code path
/// here runs before first unlock the way `PrayerAlarmReceiver` does. The file
/// sits under the app container's default data protection, which is stronger
/// than what the Android ledger gets before first unlock.
class FileReminderLedgerStore implements ReminderLedgerStore {
  /// Resolved once and cached — `getApplicationDocumentsDirectory` is a
  /// platform channel round-trip, and this is on the resume path.
  File? _file;

  final int maxRows;

  /// Both are injectable so the trim below can be driven by a test.
  ///
  /// It is the one part of this class worth testing and the one part that
  /// cannot be checked by reading it: it rewrites the file the app's evidence
  /// lives in, and it does so from inside a broadcast receiver's ten-second
  /// budget. `path_provider` is a plugin, so without a seam a test would need a
  /// device — and a rewrite nobody can test is a rewrite that eats the ledger
  /// in the field.
  FileReminderLedgerStore({
    this.maxRows = kReminderLedgerMaxRows,
    @visibleForTesting File? fileForTesting,
  }) : _file = fileForTesting;

  Future<File?> _resolve() async {
    final cached = _file;
    if (cached != null) return cached;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return _file = File('${dir.path}/reminder_ledger.ndjson');
    } catch (e) {
      log('📓 ReminderLedger could not resolve its directory: $e');
      return null;
    }
  }

  /// Serialises every append and trim against each other.
  ///
  /// The Kotlin twin holds a monitor for this reason, spelled out in its own
  /// source: a trim that rewrites the file while an append is in flight loses
  /// the appended row or duplicates the tail. Dart's single thread does not
  /// make the problem go away, because these are `async` — `main.dart` fires
  /// `_recordPendingReminders()` unawaited on the same resume that
  /// `notification_repository_impl` fires `recordArmed()` on, so two appends
  /// interleave at their `await` points. Worse, two concurrent trims write the
  /// *same* temp path and then both rename it over the ledger.
  ///
  /// Same shape as `PrayerScheduler._queue`, including the `onError` that stops
  /// one failed append from poisoning every later one.
  Future<void> _queue = Future<void>.value();

  @override
  Future<void> append(ReminderLedgerEntry entry) {
    final done = _queue.then((_) => _appendSerially(entry));
    _queue = done.then((_) {}, onError: (_) {});
    return done;
  }

  Future<void> _appendSerially(ReminderLedgerEntry entry) async {
    final file = await _resolve();
    if (file == null) return;
    try {
      await file.writeAsString(
        entry.encodeLine(),
        mode: FileMode.append,
        flush: true,
      );
      await _trimIfNeeded(file);
    } catch (e) {
      log('📓 ReminderLedger.append failed: $e');
    }
  }

  /// Rewrites the file down to [maxRows] once it holds more than that.
  ///
  /// ## The bound is rows, and it is exact
  ///
  /// An earlier draft triggered the rewrite on byte length alone, which was
  /// cheaper and quietly wrong: the row count it actually enforced depended on
  /// how long the rows happened to be, so a ledger of short rows would have
  /// held twice the 2,000 the retention decision names. A cap nobody can state
  /// in one number is not a cap.
  ///
  /// ## Why counting on every append is affordable here
  ///
  /// Appends happen about six times a day — five prayers and a re-plan. Reading
  /// a quarter-megabyte file six times a day, on a background thread, is not a
  /// cost worth designing around, and [_minRowBytes] keeps even that off the
  /// table until the ledger is genuinely large.
  Future<void> _trimIfNeeded(File file) async {
    // The smallest row this format can produce is about thirty bytes, so below
    // this the file CANNOT hold maxRows and there is nothing to count.
    if (await file.length() <= maxRows * _minRowBytes) return;

    // Counted and rewritten as LINES, not as decoded entries.
    //
    // Decoding first would have silently deleted every row this build cannot
    // parse — a row from a newer build carrying an unknown event type, or one
    // a crash truncated. `decodeLine` promises that one damaged row costs one
    // row; rebuilding the file from what decoded would have made it cost that
    // row forever. It also keeps the cap meaning the same thing on both
    // platforms: Kotlin counts non-blank lines.
    final lines = const LineSplitter()
        .convert(await file.readAsString())
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length <= maxRows) return;
    final kept = lines.sublist(lines.length - maxRows);

    // Through a temp file and a rename, which is atomic within a directory.
    // A crash partway through an in-place rewrite would leave a ledger that is
    // half one generation and half another, and the one thing worse than no
    // evidence is evidence that lies.
    final temp = File('${file.path}.tmp');
    await temp.writeAsString('${kept.join('\n')}\n', flush: true);
    await temp.rename(file.path);
  }

  /// Queued like [append], so a read never lands inside a trim's rewrite.
  @override
  Future<List<ReminderLedgerEntry>> read() {
    final done = _queue.then((_) => _readSerially());
    _queue = done.then((_) {}, onError: (_) {});
    return done;
  }

  Future<List<ReminderLedgerEntry>> _readSerially() async {
    final file = await _resolve();
    if (file == null) return const [];
    try {
      if (!await file.exists()) return const [];
      return ReminderLedgerEntry.decodeAll(await file.readAsString());
    } catch (e) {
      log('📓 ReminderLedger.read failed: $e');
      return const [];
    }
  }

  /// Queued for a sharper reason than [read] is.
  ///
  /// A `delete` racing an in-flight append does not merely lose a row: if the
  /// append's trim completes its temp-file rename *after* the delete, the
  /// "cleared" ledger comes back from the dead holding the trimmed remnant of
  /// what the user just asked to be forgotten. Both callers of this class fire
  /// appends unawaited from the resume path, so the two genuinely overlap.
  @override
  Future<void> clear() {
    final done = _queue.then((_) => _clearSerially());
    _queue = done.then((_) {}, onError: (_) {});
    return done;
  }

  Future<void> _clearSerially() async {
    final file = await _resolve();
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
      // The trim's scratch file too. Left behind, a stale one is a copy of
      // rows the user asked to be rid of.
      final temp = File('${file.path}.tmp');
      if (await temp.exists()) await temp.delete();
    } catch (e) {
      log('📓 ReminderLedger.clear failed: $e');
    }
  }
}

/// A store that keeps nothing.
///
/// Windows, and any platform with neither a native bridge nor a writable
/// documents directory. Reads empty, which [ReminderHealth] already has to
/// handle — a fresh install has an empty ledger too.
class NullReminderLedgerStore implements ReminderLedgerStore {
  const NullReminderLedgerStore();

  @override
  Future<void> append(ReminderLedgerEntry entry) async {}

  @override
  Future<List<ReminderLedgerEntry>> read() async => const [];

  @override
  Future<void> clear() async {}
}

/// In-memory, for tests.
@visibleForTesting
class InMemoryReminderLedgerStore implements ReminderLedgerStore {
  final List<ReminderLedgerEntry> entries = [];
  final int maxRows;

  InMemoryReminderLedgerStore({this.maxRows = kReminderLedgerMaxRows});

  @override
  Future<void> append(ReminderLedgerEntry entry) async {
    entries.add(entry);
    if (entries.length > maxRows) {
      entries.removeRange(0, entries.length - maxRows);
    }
  }

  @override
  Future<List<ReminderLedgerEntry>> read() async => List.of(entries);

  @override
  Future<void> clear() async => entries.clear();
}

/// The app's one ledger.
///
/// A singleton for the same reason `ReminderFloorService` is one: it is reached
/// from the resume path, the scheduler and a settings screen, and a second
/// instance would mean a second cached file handle over the same document.
class ReminderLedger {
  ReminderLedger._(this._store);

  static ReminderLedger? _instance;

  /// The live ledger, picking the writer this platform actually has.
  static ReminderLedger get instance =>
      _instance ??= ReminderLedger._(_defaultStore());

  /// Replaces the store for a test.
  ///
  /// Pair it with [resetForTesting] in a teardown. An earlier version of this
  /// left the caller to "own the teardown", and both callers duly registered
  /// one that re-installed the *same* in-memory store — so the singleton stayed
  /// pointed at one test's state for the rest of the process.
  @visibleForTesting
  static void overrideStore(ReminderLedgerStore store) {
    _instance = ReminderLedger._(store);
  }

  /// Drops any override, so the next `instance` picks the real platform store.
  @visibleForTesting
  static void resetForTesting() => _instance = null;

  static ReminderLedgerStore _defaultStore() {
    if (Platform.isAndroid) return const MethodChannelReminderLedgerStore();
    if (Platform.isIOS) return FileReminderLedgerStore();
    return const NullReminderLedgerStore();
  }

  final ReminderLedgerStore _store;

  ReminderLedgerStore get store => _store;

  Future<List<ReminderLedgerEntry>> read() => _store.read();

  Future<void> clear() => _store.clear();

  /// Records that a plan was committed.
  ///
  /// [count] alarms through [until], on [path] (`native` or `plugin`). One row,
  /// not one per alarm — see [ReminderEventType.armed].
  Future<void> recordArmed({
    required int count,
    required DateTime? until,
    required String path,
    DateTime? now,
  }) => _store.append(
    ReminderLedgerEntry(
      type: ReminderEventType.armed,
      atEpochMs: (now ?? DateTime.now()).millisecondsSinceEpoch,
      count: count,
      untilEpochMs: until?.millisecondsSinceEpoch,
      detail: path,
    ),
  );

  /// Records how many scheduled notifications the OS admits to still holding.
  ///
  /// The iOS diagnosis in one number. See [ReminderEventType.pending].
  Future<void> recordPending({required int count, DateTime? now}) =>
      _store.append(
        ReminderLedgerEntry(
          type: ReminderEventType.pending,
          atEpochMs: (now ?? DateTime.now()).millisecondsSinceEpoch,
          count: count,
        ),
      );
}
