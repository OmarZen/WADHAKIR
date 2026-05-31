import 'package:wadhakir/data/models/wird/wird_plan_model.dart';

/// Abstract repository for the Quran wird (ختم القرآن) plan.
/// Handles persistence of the user's plan configuration and progress.
abstract class WirdRepository {
  /// Get the current wird plan (returns the inactive default if none exists).
  Future<WirdPlanModel> getPlan();

  /// Persist the wird plan.
  Future<void> setPlan(WirdPlanModel plan);

  /// Stream of plan changes for reactive updates.
  Stream<WirdPlanModel> get planStream;

  /// Clear the plan (reset to the inactive default — "إعادة ضبط الختمة").
  Future<void> clearPlan();
}
