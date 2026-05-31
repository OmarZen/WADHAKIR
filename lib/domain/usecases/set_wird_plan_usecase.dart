import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/domain/repositories/wird_repository.dart';

/// Use case for persisting the wird plan.
class SetWirdPlanUseCase {
  final WirdRepository repository;

  SetWirdPlanUseCase(this.repository);

  Future<void> call(WirdPlanModel plan) => repository.setPlan(plan);
}
