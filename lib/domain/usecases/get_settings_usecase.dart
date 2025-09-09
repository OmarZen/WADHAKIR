import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/domain/repositories/app_settings_repository.dart';

class GetSettingsUseCase {
  final AppSettingsRepository _repository;

  GetSettingsUseCase(this._repository);

  Future<AppSettingsModel> call() async {
    return await _repository.getSettings();
  }
}
