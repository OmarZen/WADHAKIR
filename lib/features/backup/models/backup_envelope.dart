import 'dart:convert';
import 'dart:typed_data';

import 'package:wadhakir/features/backup/services/backup_crypto.dart';
import 'package:wadhakir/features/backup/services/backup_keys.dart';

/// Why a file could not be read as a Wadhakir backup.
///
/// Separate from `BackupCryptoException`: these are all decidable without a
/// password, so the UI can say something specific *before* asking for one.
enum BackupFormatFailure {
  /// Not JSON at all, or JSON without the `format` marker. The user picked the
  /// wrong file.
  notABackupFile,

  /// A Wadhakir backup, but written by a newer app version whose schema this
  /// build does not understand. Refusing beats guessing: a partial restore of
  /// a format we cannot read would corrupt data rather than fail to load it.
  unsupportedSchemaVersion,

  /// The right shape but damaged inside — a missing field, a type tag that is
  /// not one of [BackupValueType], base64 that will not decode.
  malformed,
}

class BackupFormatException implements Exception {
  final BackupFormatFailure reason;

  /// The schema version that was found, when [reason] is
  /// [BackupFormatFailure.unsupportedSchemaVersion]. Lets the UI say "this
  /// backup needs a newer version of the app" and mean it.
  final int? foundSchemaVersion;

  const BackupFormatException(this.reason, {this.foundSchemaVersion});

  @override
  String toString() => 'BackupFormatException(${reason.name})';
}

/// One preference value, carrying the type it must be written back as.
///
/// SharedPreferences is typed and JSON is not: without the tag, a restore
/// cannot tell `text_scale = 1.0` (a double) from `theme_mode = 1` (an int),
/// and writing the wrong one makes the next read throw.
class BackupValue {
  final BackupValueType type;

  /// A `String`, `bool`, `int`, `double` or `List<String>`, matching [type].
  final Object value;

  const BackupValue(this.type, this.value);

  Map<String, dynamic> toJson() => {'t': type.tag, 'v': value};

  /// Rebuilds a value from its JSON form, coercing numbers to the type the tag
  /// declares.
  ///
  /// The coercion is deliberate. A backup file is a JSON document that may
  /// have passed through another tool between export and import — a cloud
  /// drive that reformats, a text editor, a messaging app — and several JSON
  /// implementations will happily render `1.0` as `1`. Trusting the tag over
  /// the runtime type of the parsed literal makes the round-trip survive that.
  ///
  /// Returns null for anything that cannot be honestly coerced, so the caller
  /// can skip the entry rather than write a wrong value.
  static BackupValue? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final tag = raw['t'];
    final value = raw['v'];
    if (tag is! String) return null;
    final type = BackupValueType.fromTag(tag);
    if (type == null) return null;

    switch (type) {
      case BackupValueType.string:
        return value is String ? BackupValue(type, value) : null;
      case BackupValueType.boolean:
        return value is bool ? BackupValue(type, value) : null;
      case BackupValueType.integer:
        if (value is int) return BackupValue(type, value);
        // A double that is exactly an integer round-trips safely; one with a
        // real fraction means the file disagrees with itself, so refuse it.
        if (value is double && value == value.roundToDouble()) {
          return BackupValue(type, value.toInt());
        }
        return null;
      case BackupValueType.decimal:
        return value is num ? BackupValue(type, value.toDouble()) : null;
      case BackupValueType.stringList:
        if (value is! List) return null;
        if (value.any((e) => e is! String)) return null;
        return BackupValue(type, value.cast<String>().toList());
    }
  }
}

/// A decrypted backup: the metadata plus every preference it carries.
///
/// The on-disk shape is deliberately boring JSON so that a user who opens the
/// file in a text editor — or a future maintainer with no tooling — can see
/// exactly what they are holding. The app's own promise is that data belongs
/// to the user, and an opaque binary blob would undercut it.
class BackupEnvelope {
  /// Marker for an unencrypted file.
  static const String plainFormat = 'wadhakir.backup';

  /// Marker for a password-protected file.
  static const String encryptedFormat = 'wadhakir.backup.enc';

  /// Bump only for a change a v1 reader could not handle correctly. Adding
  /// keys does not qualify — unknown keys are skipped on restore by design,
  /// so an older build reads a newer file safely.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;

  /// The `version+build` of the app that wrote the file, shown on the restore
  /// screen so the user can tell two backups apart.
  final String appVersion;

  /// Always UTC. Rendered in the device's own locale at display time.
  final DateTime exportedAt;

  final Map<String, BackupValue> data;

  /// Entries the file contained that [decode] refused to keep — a key this
  /// build does not allow, or a value that contradicted its own type tag.
  ///
  /// Kept as a count rather than dropped silently so the restore screen can
  /// admit that a file from a newer app version carried something this build
  /// did not understand. Always zero for an envelope built locally.
  final int skippedEntryCount;

  const BackupEnvelope({
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.data,
    this.skippedEntryCount = 0,
  });

  String encode() => jsonEncode({
    'format': plainFormat,
    'schemaVersion': schemaVersion,
    'appVersion': appVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'data': {for (final entry in data.entries) entry.key: entry.value.toJson()},
  });

  /// Parses the plaintext body.
  ///
  /// Entries whose key is not allowlisted, or whose value does not match its
  /// own type tag, are dropped here rather than at write time. That keeps the
  /// restore path free of decisions: whatever survives parsing is safe to
  /// write, so a restore cannot fail halfway and leave a mixture of old and
  /// new data.
  static BackupEnvelope decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } catch (_) {
      throw const BackupFormatException(BackupFormatFailure.notABackupFile);
    }
    if (decoded is! Map || decoded['format'] != plainFormat) {
      throw const BackupFormatException(BackupFormatFailure.notABackupFile);
    }

    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int) {
      throw const BackupFormatException(BackupFormatFailure.malformed);
    }
    if (schemaVersion > currentSchemaVersion) {
      throw BackupFormatException(
        BackupFormatFailure.unsupportedSchemaVersion,
        foundSchemaVersion: schemaVersion,
      );
    }

    final rawData = decoded['data'];
    if (rawData is! Map) {
      throw const BackupFormatException(BackupFormatFailure.malformed);
    }

    final data = <String, BackupValue>{};
    var skipped = 0;
    rawData.forEach((key, raw) {
      if (key is! String) {
        skipped++;
        return;
      }
      final spec = BackupKeys.specFor(key);
      if (spec == null) {
        skipped++;
        return;
      }
      final value = BackupValue.fromJson(raw);
      if (value == null || value.type != spec.type) {
        skipped++;
        return;
      }
      data[key] = value;
    });

    return BackupEnvelope(
      schemaVersion: schemaVersion,
      appVersion: decoded['appVersion'] as String? ?? '',
      exportedAt:
          DateTime.tryParse(decoded['exportedAt'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      data: data,
      skippedEntryCount: skipped,
    );
  }
}

/// The outer, unencrypted wrapper around a password-protected backup.
///
/// Everything here is public by design. It has to be: the app must know which
/// KDF parameters to run *before* it can ask the user for a password, and the
/// restore screen should be able to show when a backup was taken without
/// demanding the password first. None of these fields reveals anything about
/// the user — and none of them can be edited without detection, because
/// [BackupCrypto.buildAad] binds them into the GCM authentication tag.
class EncryptedBackupEnvelope {
  final int schemaVersion;
  final String appVersion;
  final DateTime exportedAt;
  final String kdfAlgorithm;
  final int iterations;
  final String cipherAlgorithm;
  final Uint8List salt;
  final Uint8List nonce;

  /// Ciphertext with the GCM tag appended.
  final Uint8List payload;

  const EncryptedBackupEnvelope({
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.kdfAlgorithm,
    required this.iterations,
    required this.cipherAlgorithm,
    required this.salt,
    required this.nonce,
    required this.payload,
  });

  String encode() => jsonEncode({
    'format': BackupEnvelope.encryptedFormat,
    'schemaVersion': schemaVersion,
    'appVersion': appVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'kdf': {'algorithm': kdfAlgorithm, 'iterations': iterations},
    'cipher': {
      'algorithm': cipherAlgorithm,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
    },
    'payload': base64Encode(payload),
  });

  static EncryptedBackupEnvelope decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } catch (_) {
      throw const BackupFormatException(BackupFormatFailure.notABackupFile);
    }
    if (decoded is! Map ||
        decoded['format'] != BackupEnvelope.encryptedFormat) {
      throw const BackupFormatException(BackupFormatFailure.notABackupFile);
    }

    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int) {
      throw const BackupFormatException(BackupFormatFailure.malformed);
    }
    if (schemaVersion > BackupEnvelope.currentSchemaVersion) {
      throw BackupFormatException(
        BackupFormatFailure.unsupportedSchemaVersion,
        foundSchemaVersion: schemaVersion,
      );
    }

    final kdf = decoded['kdf'];
    final cipher = decoded['cipher'];
    if (kdf is! Map || cipher is! Map) {
      throw const BackupFormatException(BackupFormatFailure.malformed);
    }

    final iterations = kdf['iterations'];
    final kdfAlgorithm = kdf['algorithm'];
    final cipherAlgorithm = cipher['algorithm'];
    if (iterations is! int ||
        kdfAlgorithm is! String ||
        cipherAlgorithm is! String) {
      throw const BackupFormatException(BackupFormatFailure.malformed);
    }

    // The algorithm names are written into the file so a future format change
    // can be detected, which only works if somebody checks them. Without this
    // the reader would fail open: a file made with a different KDF would get
    // PBKDF2 run against it anyway and come back as "wrong password" forever,
    // sending the user to hunt for a password that was never the problem.
    if (kdfAlgorithm != BackupCrypto.kdfAlgorithm ||
        cipherAlgorithm != BackupCrypto.cipherAlgorithm) {
      throw const BackupFormatException(
        BackupFormatFailure.unsupportedSchemaVersion,
      );
    }

    // Same reasoning for the KDF cost. Checking it here — before the password
    // prompt — turns "your password is wrong, try again forever" into one
    // honest "this file is damaged".
    if (iterations < BackupCrypto.minAcceptedIterations ||
        iterations > BackupCrypto.maxAcceptedIterations) {
      throw const BackupFormatException(BackupFormatFailure.malformed);
    }

    Uint8List readBytes(Object? raw) {
      if (raw is! String) {
        throw const BackupFormatException(BackupFormatFailure.malformed);
      }
      try {
        return base64Decode(raw);
      } on FormatException {
        throw const BackupFormatException(BackupFormatFailure.malformed);
      }
    }

    return EncryptedBackupEnvelope(
      schemaVersion: schemaVersion,
      appVersion: decoded['appVersion'] as String? ?? '',
      exportedAt:
          DateTime.tryParse(decoded['exportedAt'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      kdfAlgorithm: kdfAlgorithm,
      iterations: iterations,
      cipherAlgorithm: cipherAlgorithm,
      salt: readBytes(cipher['salt']),
      nonce: readBytes(cipher['nonce']),
      payload: readBytes(decoded['payload']),
    );
  }
}

/// Whether a file needs a password, decided without one.
///
/// Returns null when the content is not a Wadhakir backup at all, so the
/// caller can report "wrong file" instead of "wrong password" — two failures
/// users confuse constantly, and only one of them is their fault.
bool? backupFileIsEncrypted(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map) return null;
    final format = decoded['format'];
    if (format == BackupEnvelope.encryptedFormat) return true;
    if (format == BackupEnvelope.plainFormat) return false;
    return null;
  } catch (_) {
    return null;
  }
}
