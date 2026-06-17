import 'package:wadhakir/domain/repositories/app_settings_repository.dart';

class SetUserNameUseCase {
  final AppSettingsRepository repository;

  SetUserNameUseCase(this.repository);

  Future<void> call(String name) async {
    await repository.setUserName(name);
  }
}
