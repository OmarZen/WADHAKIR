import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/domain/repositories/salah_tracker_repository.dart';

/// Use case for persisting the Salah log.
class SetSalahLogUseCase {
  final SalahTrackerRepository repository;

  SetSalahLogUseCase(this.repository);

  Future<void> call(SalahLogModel log) => repository.setLog(log);
}
