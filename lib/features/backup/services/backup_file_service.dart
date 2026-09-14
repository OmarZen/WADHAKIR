import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Why reading a picked file failed, before anything tries to parse it as a
/// backup.
enum BackupFileFailure {
  /// The picker returned nothing — the user backed out. Not an error; the UI
  /// should return to rest silently rather than showing a failure.
  cancelled,

  /// Far too large to be a backup. Guards against a user picking a video and
  /// the app pulling hundreds of megabytes into memory to find that out.
  tooLarge,

  /// Present but unreadable as text: a binary file, or one in an encoding
  /// that is not UTF-8.
  notReadable,
}

class BackupFileException implements Exception {
  final BackupFileFailure reason;

  const BackupFileException(this.reason);

  @override
  String toString() => 'BackupFileException(${reason.name})';
}

/// Everything the backup feature does with the file system and the share
/// sheet.
///
/// Isolated from [BackupService] on purpose: that class is pure logic over
/// SharedPreferences and is unit-tested directly, while everything here needs
/// a real device. Keeping the boundary sharp is what let the round-trip tests
/// cover the parts that can actually be wrong.
class BackupFileService {
  /// A backup of years of records is measured in hundreds of kilobytes. Ten
  /// megabytes is far past any plausible file while still being small enough
  /// that reading it costs nothing.
  ///
  /// This bounds what is pulled into *memory*, not what touches disk: on
  /// Android the document picker has already copied the chosen file into the
  /// app cache by the time an [XFile] exists, whatever its size. The cap still
  /// does its job — [XFile.readAsBytes] is what would actually exhaust memory
  /// on a low-end phone — but it is not a guard against a large file being
  /// copied.
  static const int maxImportBytes = 10 * 1024 * 1024;

  /// Writes the backup to a temporary file and returns its path.
  ///
  /// The temp directory rather than a user-visible one: the app never owns
  /// this file. It exists only long enough for the share sheet to hand it to
  /// wherever the user actually wants it — Drive, Files, a WhatsApp message to
  /// themselves — and the OS reclaims it afterwards. That also means the app
  /// needs no storage permission on any platform.
  /// Also deletes any backup this app left in the temp directory on a previous
  /// export.
  ///
  /// Without password protection the file is the user's name, coordinates and
  /// full prayer log in plain text. The share sheet needs it to outlive the
  /// call — the receiving app reads it afterwards — so it cannot be deleted
  /// straight away, but there is no reason to accumulate one copy per export
  /// either. Sweeping on the way in bounds it to a single file, and the OS
  /// reclaims that one with the rest of the cache.
  Future<String> writeTempFile({
    required String contents,
    required DateTime exportedAt,
  }) async {
    final dir = await getTemporaryDirectory();
    await _deleteStaleExports(dir);
    // Platform.pathSeparator rather than a hardcoded '/': on Windows
    // path_provider returns a backslash path, and share_plus there goes
    // through WinRT's GetFileFromPathAsync, which rejects a path with forward
    // slashes in it outright.
    final file = File(
      '${dir.path}${Platform.pathSeparator}${backupFileName(exportedAt)}',
    );
    await file.writeAsString(contents, flush: true);
    return file.path;
  }

  /// Best effort by design: a temp file that will not delete is not a reason
  /// to fail an export the user asked for.
  Future<void> _deleteStaleExports(Directory dir) async {
    try {
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (name.startsWith('wadhakir-backup-') && name.endsWith('.json')) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Ignored on purpose.
    }
  }

  /// `wadhakir-backup-2026-03-14.json`.
  ///
  /// `.json` for both the plain and the encrypted variant, because the
  /// encrypted file *is* JSON — the ciphertext rides inside it as base64. A
  /// custom extension would look tidier and cost real usability: Android's
  /// document picker filters by MIME type, and an unknown extension has none,
  /// so half the file managers would hide the file the user is looking for.
  ///
  /// The date is local, not UTC: the name is for a human scanning a folder.
  static String backupFileName(DateTime exportedAt) {
    final local = exportedAt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return 'wadhakir-backup-${local.year}-$month-$day.json';
  }

  /// Hands the file to the OS share sheet.
  ///
  /// This is the whole "save it somewhere" story, and it is deliberately the
  /// only one. A share sheet already contains every destination the user
  /// might want, needs no permission, and works identically on both
  /// platforms — where a built-in file browser would be a second-rate copy of
  /// one the user already has.
  Future<void> share({required String path, required String subject}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], subject: subject),
    );
  }

  /// Opens the system file picker and returns the file's text.
  ///
  /// No type filter. On Android a document picker filters by MIME type, and
  /// files arriving from Drive, WhatsApp or a file manager are inconsistently
  /// tagged — filtering on `application/json` would hide the very file the
  /// user came to select. Accepting anything and validating the *contents* is
  /// both more permissive and more accurate: a file that is not a backup is
  /// rejected by [BackupEnvelope.decode] with a message that says so.
  Future<String> pickAndRead() async {
    final XFile? picked = await openFile();
    if (picked == null) {
      throw const BackupFileException(BackupFileFailure.cancelled);
    }

    final length = await picked.length();
    if (length > maxImportBytes) {
      throw const BackupFileException(BackupFileFailure.tooLarge);
    }

    final bytes = await picked.readAsBytes();
    try {
      // Strict UTF-8: a file that is not valid text cannot be a backup, and
      // saying so here is clearer than letting the JSON parser fail on
      // replacement characters further down.
      return utf8.decode(bytes);
    } on FormatException {
      throw const BackupFileException(BackupFileFailure.notReadable);
    }
  }
}
