import 'dart:convert';

/// What a ledger row records.
///
/// Deliberately small. Every kind here is something the app can *observe*
/// happening; nothing here is inferred, because a ledger that stores
/// conclusions cannot be re-read by a later, smarter verdict.
enum ReminderEventType {
  /// A plan was committed: [ReminderLedgerEntry.count] alarms armed through
  /// [ReminderLedgerEntry.until], on the path named in
  /// [ReminderLedgerEntry.detail].
  ///
  /// **One row per commit, never one per alarm.** Sixty days is three hundred
  /// alarms; a row each would flush a 2,000-row ring in under seven
  /// reschedules and answer nothing that this single row does not.
  armed('armed'),

  /// An alarm fired. [ReminderLedgerEntry.due] is the instant it was armed
  /// for, [ReminderLedgerEntry.at] the instant it actually arrived — their
  /// difference is the only honest measure of whether this device delivers
  /// alarms on time.
  fired('fired'),

  /// An alarm was armed, its moment came and went, and nothing fired.
  ///
  /// Written by the re-arm sweep, which is the only place with both halves of
  /// the evidence: the set the OS was asked to hold, and a clock. See
  /// `PrayerAlarmScheduler.rearmWindow`.
  lapsed('lapsed'),

  /// How many of the app's scheduled notifications the OS still holds.
  ///
  /// The iOS health signal, since iOS has no native fire path to report from:
  /// the cap is 64 and silently drops the overflow, so "we planned N, the OS
  /// admits to M" is the whole diagnosis.
  pending('pending'),

  /// A system event rebuilt the chain — boot, a timezone change, a Play
  /// update. Explains gaps rather than diagnosing them.
  trigger('trigger');

  final String tag;
  const ReminderEventType(this.tag);

  static ReminderEventType? fromTag(String? tag) {
    for (final type in ReminderEventType.values) {
      if (type.tag == tag) return type;
    }
    return null;
  }
}

/// What happened when an alarm fired.
///
/// Only [sounded] is the product working. The other four are all reachable
/// without anything being broken, which is why they are recorded separately —
/// a verdict that counted them as failures would tell a user who silenced
/// their own phone that their device is at fault.
enum ReminderFireOutcome {
  /// The adhan playback service started. The promise, kept.
  sounded('sounded'),

  /// The channel is blocked. The user's own doing, and not fixable from here —
  /// but it *is* fixable, which makes it the most actionable verdict there is.
  muted('muted'),

  /// The phone was silenced and «يتجاوز الوضع الصامت» is off. Card only, by
  /// the user's explicit choice.
  silent('silent'),

  /// The platform refused the foreground service start. Card only, and the one
  /// outcome here that is a genuine degradation.
  refused('refused'),

  /// An alarm fired that the ledger no longer contains — a reschedule that
  /// switched this prayer off, or wiped app data. Recorded because a run of
  /// these means the two ledgers have drifted.
  orphan('orphan');

  final String tag;
  const ReminderFireOutcome(this.tag);

  static ReminderFireOutcome? fromTag(String? tag) {
    for (final outcome in ReminderFireOutcome.values) {
      if (outcome.tag == tag) return outcome;
    }
    return null;
  }
}

/// One append-only row of the reminder ledger.
///
/// ## The wire format is shared with Kotlin
///
/// These rows are written from **two** processes' worth of code: this class,
/// and `ReminderLedgerStore.kt`, which appends from a BroadcastReceiver with
/// no Flutter engine alive. The single most valuable row in the whole ledger —
/// an alarm firing while the app is closed — is the one Dart can never write.
///
/// So the field names below are a wire contract, not an implementation detail.
/// **Changing one means changing `ReminderLedgerStore.kt` in the same commit**,
/// and old rows written by the previous build are still in the file.
///
/// The names are short because they repeat on every one of 2,000 rows; at
/// ~125 bytes a row that is the difference between a 250 KB ledger and a
/// 400 KB one, and this file rides along in every backup.
class ReminderLedgerEntry {
  /// `t` — what happened.
  final ReminderEventType type;

  /// `at` — when it was recorded, epoch milliseconds UTC.
  ///
  /// Wall-clock, because it is compared against [due], which is also
  /// wall-clock: an alarm is armed for an instant on the user's calendar. A
  /// device whose clock jumps makes both wrong together, which is the least
  /// misleading of the available failures.
  final int atEpochMs;

  /// `id` — the alarm or notification id, when the row is about one.
  final int? id;

  /// `due` — the instant the row's subject was meant to happen.
  final int? dueEpochMs;

  /// `o` — for [ReminderEventType.fired], how it went.
  final ReminderFireOutcome? outcome;

  /// `n` — a count, for [ReminderEventType.armed] and
  /// [ReminderEventType.pending].
  final int? count;

  /// `u` — the far end of an armed horizon, epoch milliseconds.
  final int? untilEpochMs;

  /// `d` — free-text detail: the path for [ReminderEventType.armed], the
  /// broadcast action for [ReminderEventType.trigger].
  ///
  /// Capped at [_maxDetailLength] on the way in. Nothing generates a long one
  /// today, and a ring buffer whose row size is unbounded is a ring buffer
  /// whose retention is unknown.
  final String? detail;

  static const int _maxDetailLength = 64;

  ReminderLedgerEntry({
    required this.type,
    required this.atEpochMs,
    this.id,
    this.dueEpochMs,
    this.outcome,
    this.count,
    this.untilEpochMs,
    String? detail,
  }) : detail = detail == null || detail.length <= _maxDetailLength
           ? detail
           : detail.substring(0, _maxDetailLength);

  /// How late the row's subject was, or null when the row is not about an
  /// instant.
  ///
  /// Negative for an alarm that arrived early, which a lead-time reminder
  /// legitimately can be — callers that want "lateness" should clamp, not
  /// assume.
  Duration? get skew => dueEpochMs == null
      ? null
      : Duration(milliseconds: atEpochMs - dueEpochMs!);

  DateTime get at =>
      DateTime.fromMillisecondsSinceEpoch(atEpochMs, isUtc: true);

  Map<String, Object?> toJson() => {
    't': type.tag,
    'at': atEpochMs,
    if (id != null) 'id': id,
    if (dueEpochMs != null) 'due': dueEpochMs,
    if (outcome != null) 'o': outcome!.tag,
    if (count != null) 'n': count,
    if (untilEpochMs != null) 'u': untilEpochMs,
    if (detail != null) 'd': detail,
  };

  /// One NDJSON line, newline included.
  ///
  /// `jsonEncode` never emits a raw newline — it escapes them inside strings —
  /// so one row can never become two on the way back in.
  String encodeLine() => '${jsonEncode(toJson())}\n';

  /// Rebuilds a row, or returns null for anything unreadable.
  ///
  /// Null rather than throwing, because this parses a file that a *previous
  /// build* wrote and that a crash may have truncated mid-line. One damaged
  /// row must cost one row — a ledger that refuses to load at all takes the
  /// health screen down with it, and the health screen is what a user opens
  /// precisely when things are already going wrong.
  static ReminderLedgerEntry? decodeLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;

    final type = ReminderEventType.fromTag(decoded['t'] as String?);
    final at = decoded['at'];
    if (type == null || at is! int) return null;

    int? asInt(Object? raw) => raw is int
        ? raw
        : raw is double && raw == raw.roundToDouble()
        ? raw.toInt()
        : null;

    return ReminderLedgerEntry(
      type: type,
      atEpochMs: at,
      id: asInt(decoded['id']),
      dueEpochMs: asInt(decoded['due']),
      outcome: ReminderFireOutcome.fromTag(decoded['o'] as String?),
      count: asInt(decoded['n']),
      untilEpochMs: asInt(decoded['u']),
      detail: decoded['d'] as String?,
    );
  }

  /// Parses a whole NDJSON document, skipping rows it cannot read.
  static List<ReminderLedgerEntry> decodeAll(String source) {
    final entries = <ReminderLedgerEntry>[];
    for (final line in const LineSplitter().convert(source)) {
      final entry = decodeLine(line);
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  static String encodeAll(Iterable<ReminderLedgerEntry> entries) =>
      entries.map((e) => e.encodeLine()).join();
}
