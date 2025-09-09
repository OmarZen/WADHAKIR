import 'package:wadhakir/domain/repositories/qibla_repository.dart';

class RequestQiblaPermissionsUseCase {
  final QiblaRepository _repository;

  RequestQiblaPermissionsUseCase(this._repository);

  Future<void> call() async {
    return await _repository.requestPermissions();
  }
}
