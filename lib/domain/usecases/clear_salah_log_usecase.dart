import 'package:wadhakir/domain/repositories/salah_tracker_repository.dart';

/// Use case for resetting the Salah log to its empty default.
class ClearSalahLogUseCase {
  final SalahTrackerRepository repository;

  ClearSalahLogUseCase(this.repository);

  Future<void> call() => repository.clearLog();
}
