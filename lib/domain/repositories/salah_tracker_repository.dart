import 'package:wadhakir/data/models/salah/salah_log_model.dart';

/// Abstract repository for the Salah (prayer) tracker.
/// Persists the per-day prayer log + qada (make-up) debt.
abstract class SalahTrackerRepository {
  /// Get the current log (returns the empty default if none exists).
  Future<SalahLogModel> getLog();

  /// Persist the full log.
  Future<void> setLog(SalahLogModel log);

  /// Stream of log changes for reactive updates.
  Stream<SalahLogModel> get logStream;

  /// Reset the log to the empty default.
  Future<void> clearLog();
}
