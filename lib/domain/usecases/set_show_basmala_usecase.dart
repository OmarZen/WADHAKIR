import 'package:wadhakir/domain/repositories/app_settings_repository.dart';

class SetShowBasmalaUseCase {
  final AppSettingsRepository _repository;

  SetShowBasmalaUseCase(this._repository);

  Future<void> call(bool showBasmala) async {
    await _repository.setShowBasmala(showBasmala);
  }
}
