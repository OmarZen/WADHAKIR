import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/domain/repositories/salah_tracker_repository.dart';

/// Use case for retrieving the current Salah log.
class GetSalahLogUseCase {
  final SalahTrackerRepository repository;

  GetSalahLogUseCase(this.repository);

  Future<SalahLogModel> call() => repository.getLog();
}
