import 'package:wadhakir/domain/repositories/app_settings_repository.dart';

class SetTextScaleUseCase {
  final AppSettingsRepository _repository;

  SetTextScaleUseCase(this._repository);

  Future<void> call(double scale) async {
    await _repository.setTextScale(scale);
  }
}
