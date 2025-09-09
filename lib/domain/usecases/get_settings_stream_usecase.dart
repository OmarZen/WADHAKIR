import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/domain/repositories/app_settings_repository.dart';

class GetSettingsStreamUseCase {
  final AppSettingsRepository _repository;

  GetSettingsStreamUseCase(this._repository);

  Stream<AppSettingsModel> call() {
    return _repository.settingsStream;
  }
}
