import 'package:wadhakir/data/models/qibla_model.dart';
import 'package:wadhakir/domain/repositories/qibla_repository.dart';

class GetQiblaDirectionUseCase {
  final QiblaRepository _repository;

  GetQiblaDirectionUseCase(this._repository);

  Stream<QiblaModel> call() {
    return _repository.getQiblaDirection();
  }
}
