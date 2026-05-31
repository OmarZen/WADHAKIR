import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/domain/repositories/wird_repository.dart';

/// Implementation of [WirdRepository] using SharedPreferences.
/// Mirrors FastingRemindersRepositoryImpl (cache + broadcast stream).
class WirdRepositoryImpl implements WirdRepository {
  static const String _planKey = 'wird_plan';

  final SharedPreferences _sharedPreferences;
  final StreamController<WirdPlanModel> _planController =
      StreamController<WirdPlanModel>.broadcast();

  WirdPlanModel? _cachedPlan;

  WirdRepositoryImpl(this._sharedPreferences);

  @override
  Future<WirdPlanModel> getPlan() async {
    if (_cachedPlan != null) return _cachedPlan!;

    final planJson = _sharedPreferences.getString(_planKey);

    if (planJson != null && planJson.isNotEmpty) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(planJson);
        _cachedPlan = WirdPlanModel.fromJson(jsonMap);
      } catch (e) {
        // Corrupted data — clear it and fall back to defaults.
        await _sharedPreferences.remove(_planKey);
        _cachedPlan = WirdPlanModel.defaultSettings();
      }
    } else {
      _cachedPlan = WirdPlanModel.defaultSettings();
    }

    _planController.add(_cachedPlan!);
    return _cachedPlan!;
  }

  @override
  Future<void> setPlan(WirdPlanModel plan) async {
    final jsonString = jsonEncode(plan.toJson());
    await _sharedPreferences.setString(_planKey, jsonString);
    _cachedPlan = plan;
    _planController.add(_cachedPlan!);
  }

  @override
  Stream<WirdPlanModel> get planStream => _planController.stream;

  @override
  Future<void> clearPlan() async {
    await _sharedPreferences.remove(_planKey);
    _cachedPlan = WirdPlanModel.defaultSettings();
    _planController.add(_cachedPlan!);
  }

  /// Dispose the stream controller when no longer needed.
  void dispose() {
    _planController.close();
  }
}
