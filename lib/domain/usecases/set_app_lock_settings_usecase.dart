import '../repositories/app_settings_repository.dart';
import '../../data/models/app_lock_settings_model.dart';

/// Use case for updating app lock settings
class SetAppLockSettingsUseCase {
  final AppSettingsRepository repository;

  SetAppLockSettingsUseCase(this.repository);

  Future<void> call(AppLockSettingsModel settings) async {
    await repository.setAppLockSettings(settings);
  }
}
