import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/features/backup/models/backup_envelope.dart';
import 'package:wadhakir/features/backup/services/backup_keys.dart';

/// A human-readable description of what a backup holds, for the export
/// preview and the restore confirmation.
///
/// Deliberately not a key count. "38 preferences" tells the user nothing and
/// makes the most consequential action in the app — overwriting years of
/// records — feel arbitrary. "412 days of prayer, a khatma plan, 3 counters"
/// is a sentence someone can actually decide on.
class BackupSummary {
  /// Days with at least one logged prayer, read out of `salah_tracker_log`.
  /// Null when the backup carries no salah log at all.
  final int? salahDays;

  /// Whether a khatma plan is present and marked active.
  final bool hasActiveWirdPlan;

  /// How many per-dhikr counters travelled (the prefix families).
  final int dhikrCounters;

  /// Keys present, per section. A section missing from the map carried
  /// nothing.
  final Map<BackupSection, int> keysBySection;

  const BackupSummary({
    required this.salahDays,
    required this.hasActiveWirdPlan,
    required this.dhikrCounters,
    required this.keysBySection,
  });

  int get totalKeys =>
      keysBySection.values.fold(0, (sum, count) => sum + count);

  bool get isEmpty => totalKeys == 0;

  bool has(BackupSection section) => (keysBySection[section] ?? 0) > 0;
}

/// What a restore actually did, so the success screen can report it truthfully
/// rather than saying "done" and hoping.
class BackupRestoreReport {
  /// Keys written from the backup.
  final int written;

  /// Allowlisted keys that existed on this device but were absent from the
  /// backup, and were therefore removed. This is what makes the restore a
  /// replacement rather than a merge.
  final int removed;

  /// Entries in the file this build refused to write: keys that are not
  /// allowlisted, or whose value did not match its declared type. Non-zero is
  /// normal when restoring a file from a newer app version.
  final int skipped;

  const BackupRestoreReport({
    required this.written,
    required this.removed,
    required this.skipped,
  });
}

/// Reads and writes the backup payload against [SharedPreferences].
///
/// Everything here goes through the Dart preferences API, never the
/// filesystem. On Android the values physically live in a Jetpack DataStore
/// protobuf under `flutter.`-prefixed names, with doubles and string lists
/// re-encoded as tagged strings; on iOS they are in NSUserDefaults. Only the
/// plugin knows how to do that correctly, and going around it is how backup
/// features silently corrupt data.
///
/// The class holds no clock and no file handles: `exportedAt` is passed in.
/// That keeps every branch here testable with an in-memory preference store
/// and no fake time.
class BackupService {
  final SharedPreferences _prefs;

  BackupService(this._prefs);

  /// Collects everything on this device that is allowed to travel.
  ///
  /// Scans the live key set rather than reading a fixed list, because the
  /// per-dhikr counters are keyed by a runtime hash and have no other index.
  /// [BackupKeys.specFor] is the only gate — a key that is not allowlisted is
  /// never read, so a plugin's private keys cannot leak into a file the user
  /// is about to send to themselves over WhatsApp.
  BackupEnvelope buildEnvelope({
    required String appVersion,
    required DateTime exportedAt,
  }) {
    final data = <String, BackupValue>{};
    for (final key in _prefs.getKeys()) {
      final spec = BackupKeys.specFor(key);
      if (spec == null) continue;
      final value = _read(key, spec.type);
      if (value != null) data[key] = value;
    }
    return BackupEnvelope(
      schemaVersion: BackupEnvelope.currentSchemaVersion,
      appVersion: appVersion,
      exportedAt: exportedAt.toUtc(),
      data: data,
    );
  }

  /// Describes a payload — the device's own on the export screen, the file's
  /// on the restore screen. One function so the two screens can never
  /// disagree about what a backup contains.
  BackupSummary summarize(Map<String, BackupValue> data) {
    final counts = <BackupSection, int>{};
    var dhikrCounters = 0;

    for (final entry in data.entries) {
      final spec = BackupKeys.specFor(entry.key);
      if (spec == null) continue;
      counts[spec.section] = (counts[spec.section] ?? 0) + 1;
      for (final prefix in BackupKeys.allowPrefixes) {
        if (entry.key.startsWith(prefix.prefix)) {
          dhikrCounters++;
          break;
        }
      }
    }

    return BackupSummary(
      salahDays: _countSalahDays(data['salah_tracker_log']),
      hasActiveWirdPlan: _wirdPlanIsActive(data['wird_plan']),
      dhikrCounters: dhikrCounters,
      keysBySection: counts,
    );
  }

  /// Replaces this device's backed-up data with the file's.
  ///
  /// The replacement is total within the allowlist: keys in the file are
  /// written, and allowlisted keys the device has but the file does not are
  /// removed. Without that second half a "restore" would leave a stale wird
  /// plan or an old excused-days anchor sitting behind data that no longer
  /// refers to it — a merge wearing a restore's label.
  ///
  /// Nothing outside the allowlist is read, written or deleted. In particular
  /// the caller's `battery_opt_prompted` and onboarding state survive
  /// untouched, which is exactly the point of
  /// [BackupKeys.denyKeys].
  ///
  /// Validation happened during [BackupEnvelope.decode], so by the time a
  /// value reaches this method it is known to be allowlisted and correctly
  /// typed. That is deliberate: it means this loop has no way to fail on
  /// content, and cannot leave the device holding half of two different
  /// backups.
  Future<BackupRestoreReport> restore(BackupEnvelope envelope) async {
    final incoming = envelope.data;

    final existing = _prefs
        .getKeys()
        .where((key) => BackupKeys.specFor(key) != null)
        .toSet();

    var written = 0;
    for (final entry in incoming.entries) {
      await _write(entry.key, entry.value);
      written++;
    }

    var removed = 0;
    for (final key in existing) {
      if (incoming.containsKey(key)) continue;
      await _prefs.remove(key);
      removed++;
    }

    // Removing the calculation method has to take its auto-detect guard with
    // it. The guard is denylisted, so it survives the restore holding this
    // device's old `true` — and `_autoDetectCalculationMethod` early-returns
    // on `true`. A device left with the flag set and no method stored would
    // fall back to the hardcoded Egyptian parameters and never re-detect,
    // which means silently wrong prayer times for anyone outside Egypt.
    //
    // Clearing it is safe in the other direction too: if a method IS restored,
    // the detector runs once, sees it, keeps it, and sets the flag itself.
    if (!incoming.containsKey(BackupKeys.calculationMethodKey) &&
        _prefs.containsKey(BackupKeys.calcMethodAutoDetectedKey)) {
      await _prefs.remove(BackupKeys.calcMethodAutoDetectedKey);
    }

    return BackupRestoreReport(
      written: written,
      removed: removed,
      // decode() dropped anything unwritable; the difference is what it
      // dropped. Reported rather than hidden so a file from a newer build
      // says so out loud.
      skipped: envelope.skippedEntryCount,
    );
  }

  BackupValue? _read(String key, BackupValueType type) {
    switch (type) {
      case BackupValueType.string:
        final v = _prefs.getString(key);
        return v == null ? null : BackupValue(type, v);
      case BackupValueType.boolean:
        final v = _prefs.getBool(key);
        return v == null ? null : BackupValue(type, v);
      case BackupValueType.integer:
        final v = _prefs.getInt(key);
        return v == null ? null : BackupValue(type, v);
      case BackupValueType.decimal:
        final v = _prefs.getDouble(key);
        return v == null ? null : BackupValue(type, v);
      case BackupValueType.stringList:
        final v = _prefs.getStringList(key);
        return v == null ? null : BackupValue(type, v);
    }
  }

  Future<void> _write(String key, BackupValue value) async {
    switch (value.type) {
      case BackupValueType.string:
        await _prefs.setString(key, value.value as String);
      case BackupValueType.boolean:
        await _prefs.setBool(key, value.value as bool);
      case BackupValueType.integer:
        await _prefs.setInt(key, value.value as int);
      case BackupValueType.decimal:
        await _prefs.setDouble(key, value.value as double);
      case BackupValueType.stringList:
        // Must go through setStringList: the platform encodes lists with a
        // sentinel prefix, and writing one as a plain String corrupts it.
        await _prefs.setStringList(key, (value.value as List).cast<String>());
    }
  }

  /// Days with at least one logged prayer.
  ///
  /// Reads the raw JSON rather than going through `SalahLogModel.fromJson`, on
  /// purpose: this runs against a *file*, which may have been written by a
  /// different app version whose model would refuse or silently reshape it.
  /// A count for a confirmation screen must never be the thing that makes a
  /// restore impossible, so every failure here degrades to "unknown".
  static int? _countSalahDays(BackupValue? raw) {
    if (raw == null || raw.type != BackupValueType.string) return null;
    try {
      final decoded = jsonDecode(raw.value as String);
      if (decoded is! Map) return null;
      final days = decoded['days'];
      return days is Map ? days.length : null;
    } catch (_) {
      return null;
    }
  }

  static bool _wirdPlanIsActive(BackupValue? raw) {
    if (raw == null || raw.type != BackupValueType.string) return false;
    try {
      final decoded = jsonDecode(raw.value as String);
      return decoded is Map && decoded['isActive'] == true;
    } catch (_) {
      return false;
    }
  }
}
