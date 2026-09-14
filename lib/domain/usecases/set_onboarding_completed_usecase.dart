import 'package:wadhakir/domain/repositories/app_settings_repository.dart';

class SetOnboardingCompletedUseCase {
  final AppSettingsRepository repository;

  SetOnboardingCompletedUseCase(this.repository);

  Future<void> call(bool completed) async {
    await repository.setOnboardingCompleted(completed);
  }
}
