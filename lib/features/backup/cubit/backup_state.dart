import 'package:equatable/equatable.dart';
import 'package:wadhakir/features/backup/models/backup_envelope.dart';
import 'package:wadhakir/features/backup/services/backup_service.dart';

/// What the app is busy doing, so the UI can name it instead of showing a bare
/// spinner. Each of these can take a visible moment: the KDF runs for about a
/// second on a mid-range phone, by design.
enum BackupTask { exporting, readingFile, unlocking, restoring }

/// Every way this feature can fail, as a closed set.
///
/// A closed enum rather than an error string because the messages are
/// localised into two languages and because the distinctions matter to the
/// user: "this is not a backup file" and "that password is wrong" send someone
/// looking in two completely different places.
enum BackupError {
  /// The picked file is far bigger than any backup could be.
  fileTooLarge,

  /// The picked file is not readable as UTF-8 text.
  fileNotReadable,

  /// Readable, but not a Wadhakir backup — the user picked the wrong file.
  notABackupFile,

  /// A backup written by a newer version of the app.
  unsupportedVersion,

  /// A Wadhakir backup that is damaged inside.
  malformedFile,

  /// There is nothing on this device worth exporting yet.
  nothingToExport,

  /// Writing or sharing the file failed.
  exportFailed,

  /// Writing the restored values failed.
  restoreFailed,
}

abstract class BackupState extends Equatable {
  const BackupState();

  @override
  List<Object?> get props => [];
}

class BackupInitial extends BackupState {
  const BackupInitial();
}

/// The resting state: nothing in flight, showing what this device would put
/// into a backup right now.
class BackupReady extends BackupState {
  final BackupSummary summary;

  /// Set when the previous action failed, so the screen can show the reason
  /// without becoming a dead end — the buttons stay live.
  final BackupError? error;

  const BackupReady(this.summary, {this.error});

  @override
  List<Object?> get props => [
    summary.totalKeys,
    summary.salahDays,
    summary.dhikrCounters,
    summary.hasActiveWirdPlan,
    error,
  ];
}

class BackupInProgress extends BackupState {
  final BackupTask task;

  const BackupInProgress(this.task);

  @override
  List<Object?> get props => [task];
}

/// A password-protected file is open and waiting for its password.
class BackupPasswordRequired extends BackupState {
  final EncryptedBackupEnvelope envelope;

  /// True after at least one failed attempt, so the field can say so instead
  /// of silently clearing.
  final bool previousAttemptFailed;

  const BackupPasswordRequired(
    this.envelope, {
    this.previousAttemptFailed = false,
  });

  @override
  List<Object?> get props => [
    envelope.exportedAt,
    envelope.payload.length,
    previousAttemptFailed,
  ];
}

/// The file is readable and understood. Nothing has been written yet — this is
/// the last point at which the user can walk away with their data intact.
class BackupRestoreConfirmation extends BackupState {
  final BackupEnvelope envelope;

  /// What is in the file.
  final BackupSummary incoming;

  /// What is on this device, and about to be replaced.
  final BackupSummary current;

  /// Set when a restore was attempted from this state and failed. The user
  /// stays here rather than being sent back to the file picker, because a
  /// failed write leaves the device holding part of each dataset and
  /// retrying — which is idempotent — is the only way out.
  final BackupError? error;

  const BackupRestoreConfirmation({
    required this.envelope,
    required this.incoming,
    required this.current,
    this.error,
  });

  @override
  List<Object?> get props => [
    envelope.exportedAt,
    incoming.totalKeys,
    current.totalKeys,
    error,
  ];
}

/// The data is in. The app now has to be restarted — every repository in the
/// process is holding an in-memory cache of the values that were just
/// replaced, and the first one to write would put the old data back.
class BackupRestored extends BackupState {
  final BackupRestoreReport report;
  final BackupSummary restored;

  const BackupRestored({required this.report, required this.restored});

  @override
  List<Object?> get props => [
    report.written,
    report.removed,
    report.skipped,
    restored.totalKeys,
  ];
}
