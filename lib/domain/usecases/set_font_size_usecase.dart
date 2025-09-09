import 'package:wadhakir/domain/repositories/app_settings_repository.dart';

class SetFontSizeUseCase {
  final AppSettingsRepository _repository;

  SetFontSizeUseCase(this._repository);

  Future<void> call(double fontSize) async {
    await _repository.setFontSize(fontSize);
  }
}
