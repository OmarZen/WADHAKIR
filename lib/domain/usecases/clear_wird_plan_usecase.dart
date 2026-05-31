import 'package:wadhakir/domain/repositories/wird_repository.dart';

/// Use case for clearing the wird plan (reset to inactive default).
class ClearWirdPlanUseCase {
  final WirdRepository repository;

  ClearWirdPlanUseCase(this.repository);

  Future<void> call() => repository.clearPlan();
}
