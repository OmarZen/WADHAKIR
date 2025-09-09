import 'package:wadhakir/domain/repositories/app_settings_repository.dart';

class SetLanguageUseCase {
  final AppSettingsRepository _repository;

  SetLanguageUseCase(this._repository);

  Future<void> call(String languageCode) async {
    await _repository.setLanguage(languageCode);
  }
}
