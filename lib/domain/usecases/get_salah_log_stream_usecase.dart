import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/domain/repositories/salah_tracker_repository.dart';

/// Use case exposing the stream of Salah-log changes.
class GetSalahLogStreamUseCase {
  final SalahTrackerRepository repository;

  GetSalahLogStreamUseCase(this.repository);

  Stream<SalahLogModel> call() => repository.logStream;
}
