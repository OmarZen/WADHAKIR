import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/domain/repositories/wird_repository.dart';

/// Use case for retrieving the current wird plan.
class GetWirdPlanUseCase {
  final WirdRepository repository;

  GetWirdPlanUseCase(this.repository);

  Future<WirdPlanModel> call() => repository.getPlan();
}
