import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wadhakir/core/app/restart_required.dart';
import 'package:wadhakir/features/backup/cubit/backup_state.dart';
import 'package:wadhakir/features/backup/models/backup_envelope.dart';
import 'package:wadhakir/features/backup/services/backup_crypto.dart';
import 'package:wadhakir/features/backup/services/backup_file_service.dart';
import 'package:wadhakir/features/backup/services/backup_service.dart';

/// Drives export and restore.
///
/// The state machine is small on purpose, and every transition that touches
/// user data passes through [BackupRestoreConfirmation] first. Restoring is
/// the only destructive action in the app, and it is worth one extra tap.
class BackupCubit extends Cubit<BackupState> {
  final BackupService _service;
  final BackupFileService _files;

  /// Injected rather than called directly so the export timestamp is
  /// controllable in tests. This is the same shape the `PrayerSchedulePlanner`
  /// work will need across the app, so it may as well start here.
  final DateTime Function() _now;

  /// [service] is positional to match how every repository in this codebase
  /// takes its store (`SalahTrackerRepositoryImpl(this._sharedPreferences)`).
  /// The other two are optional seams for tests.
  BackupCubit(
    this._service, {
    BackupFileService? fileService,
    DateTime Function()? now,
  }) : _files = fileService ?? BackupFileService(),
       _now = now ?? DateTime.now,
       super(const BackupInitial()) {
    refresh();
  }

  /// Emits only if this cubit is still alive.
  ///
  /// Every public method here awaits something slow — a KDF in an isolate, a
  /// file picker, a share sheet — and the user can leave the screen while it
  /// runs. `BlocProvider` closes the cubit on dispose, and a plain `emit`
  /// after that throws a `StateError` that surfaces as a red screen for
  /// nothing. There is no state worth delivering to a screen that is gone.
  void _safeEmit(BackupState next) {
    if (isClosed) return;
    emit(next);
  }

  /// Recomputes what this device would export. Cheap — it reads
  /// SharedPreferences, which is already in memory.
  void refresh({BackupError? error}) {
    final envelope = _buildEnvelope('');
    _safeEmit(BackupReady(_service.summarize(envelope.data), error: error));
  }

  /// Builds the file and hands it to the share sheet.
  ///
  /// An empty [password] means no encryption. That is a deliberate choice the
  /// user makes on the export screen, not a default that happens to them: the
  /// field explains what leaving it blank means.
  Future<void> export({required String password}) async {
    // Claim the busy state before the first await. `_appVersion()` is a
    // platform-channel round trip, so without this a double tap starts two
    // exports, and the first one's trailing refresh() would stamp over
    // whatever the second had reached.
    if (state is BackupInProgress) return;
    emit(const BackupInProgress(BackupTask.exporting));

    final envelope = _buildEnvelope(await _appVersion());
    if (envelope.data.isEmpty) {
      refresh(error: BackupError.nothingToExport);
      return;
    }

    try {
      final String contents;
      if (password.isEmpty) {
        contents = envelope.encode();
      } else {
        // PBKDF2 blocks its thread for roughly a second at the shipping
        // iteration count. On the UI thread that is a frozen button and a
        // pile of dropped frames, so it goes to an isolate.
        final sealed = await compute(
          runBackupEncrypt,
          BackupEncryptRequest(
            plaintext: envelope.encode(),
            password: password,
            format: BackupEnvelope.encryptedFormat,
            schemaVersion: BackupEnvelope.currentSchemaVersion,
            iterations: BackupCrypto.defaultIterations,
          ),
        );
        contents = EncryptedBackupEnvelope(
          schemaVersion: BackupEnvelope.currentSchemaVersion,
          appVersion: envelope.appVersion,
          exportedAt: envelope.exportedAt,
          kdfAlgorithm: BackupCrypto.kdfAlgorithm,
          iterations: BackupCrypto.defaultIterations,
          cipherAlgorithm: BackupCrypto.cipherAlgorithm,
          salt: sealed.salt,
          nonce: sealed.nonce,
          payload: sealed.ciphertext,
        ).encode();
      }

      final path = await _files.writeTempFile(
        contents: contents,
        exportedAt: envelope.exportedAt,
      );
      await _files.share(
        path: path,
        subject: BackupFileService.backupFileName(envelope.exportedAt),
      );
      refresh();
    } catch (e) {
      debugPrint('BackupCubit.export failed: $e');
      refresh(error: BackupError.exportFailed);
    }
  }

  /// Opens the file picker and works out what the user chose.
  ///
  /// Nothing is written here. The most this can do is move to the password
  /// prompt or the confirmation screen.
  Future<void> pickFile() async {
    if (state is BackupInProgress) return;
    emit(const BackupInProgress(BackupTask.readingFile));
    final String contents;
    try {
      contents = await _files.pickAndRead();
    } on BackupFileException catch (e) {
      refresh(error: _mapFileFailure(e.reason));
      return;
    } catch (e) {
      debugPrint('BackupCubit.pickFile failed: $e');
      refresh(error: BackupError.fileNotReadable);
      return;
    }

    final encrypted = backupFileIsEncrypted(contents);
    if (encrypted == null) {
      refresh(error: BackupError.notABackupFile);
      return;
    }

    try {
      if (encrypted) {
        _safeEmit(
          BackupPasswordRequired(EncryptedBackupEnvelope.decode(contents)),
        );
      } else {
        _emitConfirmation(BackupEnvelope.decode(contents));
      }
    } on BackupFormatException catch (e) {
      refresh(error: _mapFormatFailure(e.reason));
    }
  }

  /// Tries [password] against the file currently waiting in
  /// [BackupPasswordRequired].
  ///
  /// A failure returns to the same prompt rather than dropping the user back
  /// to the start — mistyping a password should not cost them the file they
  /// just found.
  Future<void> submitPassword(String password) async {
    final pending = state;
    if (pending is! BackupPasswordRequired) return;

    _safeEmit(const BackupInProgress(BackupTask.unlocking));
    try {
      final envelope = pending.envelope;
      final plaintext = await compute(
        runBackupDecrypt,
        BackupDecryptRequest(
          ciphertext: envelope.payload,
          salt: envelope.salt,
          nonce: envelope.nonce,
          password: password,
          format: BackupEnvelope.encryptedFormat,
          schemaVersion: envelope.schemaVersion,
          iterations: envelope.iterations,
        ),
      );
      _emitConfirmation(BackupEnvelope.decode(plaintext));
    } on BackupCryptoException {
      _safeEmit(
        BackupPasswordRequired(pending.envelope, previousAttemptFailed: true),
      );
    } on BackupFormatException catch (e) {
      refresh(error: _mapFormatFailure(e.reason));
    } catch (e) {
      debugPrint('BackupCubit.submitPassword failed: $e');
      refresh(error: BackupError.malformedFile);
    }
  }

  /// Writes the data. The only destructive call in the feature.
  Future<void> confirmRestore() async {
    final pending = state;
    if (pending is! BackupRestoreConfirmation) return;

    _safeEmit(const BackupInProgress(BackupTask.restoring));
    try {
      final report = await _service.restore(pending.envelope);
      // Latch BEFORE emitting the success state, so there is no window in
      // which the screen is on-screen and resume-time housekeeping could still
      // write from a stale cache. See RestartRequired.
      RestartRequired.markRestoreCompleted();
      _safeEmit(BackupRestored(report: report, restored: pending.incoming));
    } catch (e) {
      debugPrint('BackupCubit.confirmRestore failed: $e');
      // Back to the confirmation, not to the start. The write loop has no way
      // to fail on content — decode() validated every entry — so a failure
      // here is I/O, which means the device is now holding part of the
      // backup and part of its old data. Retrying is both safe (the writes
      // are idempotent) and the only thing that gets it out of that state, so
      // the envelope has to stay in hand. Sending the user back to "pick a
      // file" would strand a half-restored device.
      _safeEmit(
        BackupRestoreConfirmation(
          envelope: pending.envelope,
          incoming: pending.incoming,
          current: _service.summarize(_buildEnvelope('').data),
          error: BackupError.restoreFailed,
        ),
      );
    }
  }

  /// Backs out of the password prompt or the confirmation screen.
  void cancel() => refresh();

  void _emitConfirmation(BackupEnvelope envelope) {
    if (envelope.data.isEmpty) {
      refresh(error: BackupError.malformedFile);
      return;
    }
    _safeEmit(
      BackupRestoreConfirmation(
        envelope: envelope,
        incoming: _service.summarize(envelope.data),
        current: _service.summarize(_buildEnvelope('').data),
      ),
    );
  }

  BackupEnvelope _buildEnvelope(String appVersion) =>
      _service.buildEnvelope(appVersion: appVersion, exportedAt: _now());

  /// The running app's `version+build`, recorded in the file so a user with
  /// two backups can tell which is which.
  ///
  /// Never fatal: a backup that cannot name its origin is still a perfectly
  /// good backup, so a platform-channel failure degrades to an empty string.
  Future<String> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (e) {
      debugPrint('BackupCubit could not read the app version: $e');
      return '';
    }
  }

  /// Null for a cancellation: backing out of the file picker is a decision,
  /// not a failure, and showing "could not read the file" for it would tell
  /// the user something went wrong when nothing did. The screen just returns
  /// to rest.
  static BackupError? _mapFileFailure(BackupFileFailure reason) =>
      switch (reason) {
        BackupFileFailure.cancelled => null,
        BackupFileFailure.tooLarge => BackupError.fileTooLarge,
        BackupFileFailure.notReadable => BackupError.fileNotReadable,
      };

  static BackupError _mapFormatFailure(BackupFormatFailure reason) =>
      switch (reason) {
        BackupFormatFailure.notABackupFile => BackupError.notABackupFile,
        BackupFormatFailure.unsupportedSchemaVersion =>
          BackupError.unsupportedVersion,
        BackupFormatFailure.malformed => BackupError.malformedFile,
      };
}
