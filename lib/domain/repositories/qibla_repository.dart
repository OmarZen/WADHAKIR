import 'package:wadhakir/data/models/qibla_model.dart';

abstract class QiblaRepository {
  Stream<QiblaModel> getQiblaDirection();
  Future<void> requestPermissions();

  /// Check if compass is available on this device
  bool get isCompassAvailable;

  /// Get the compass error message if compass is not available
  String? get compassErrorMessage;
}
