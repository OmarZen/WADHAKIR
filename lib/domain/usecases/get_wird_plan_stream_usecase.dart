import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/domain/repositories/wird_repository.dart';

/// Use case exposing the reactive stream of wird plan changes.
class GetWirdPlanStreamUseCase {
  final WirdRepository repository;

  GetWirdPlanStreamUseCase(this.repository);

  Stream<WirdPlanModel> call() => repository.planStream;
}
