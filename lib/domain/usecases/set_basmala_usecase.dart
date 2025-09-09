import '../repositories/app_settings_repository.dart';

class SetBasmalaUseCase {
  final AppSettingsRepository repository;

  SetBasmalaUseCase(this.repository);

  Future<void> call(bool showBasmala) async {
    return await repository.setShowBasmala(showBasmala);
  }
}
