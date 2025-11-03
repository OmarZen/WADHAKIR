import '../repositories/app_settings_repository.dart';
import '../../data/models/notification_settings_model.dart';

/// Use case for updating notification settings
class SetNotificationSettingsUseCase {
  final AppSettingsRepository repository;

  SetNotificationSettingsUseCase(this.repository);

  Future<void> call(NotificationSettingsModel settings) async {
    await repository.setNotificationSettings(settings);
  }
}
