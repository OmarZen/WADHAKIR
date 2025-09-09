import 'package:wadhakir/data/models/qibla_model.dart';

abstract class QiblaRepository {
  Stream<QiblaModel> getQiblaDirection();
  Future<void> requestPermissions();
}
