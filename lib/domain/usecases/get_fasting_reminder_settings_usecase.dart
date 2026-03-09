import 'package:wadhakir/data/models/fasting/fasting_reminder_settings_model.dart';
import 'package:wadhakir/domain/repositories/fasting_reminders_repository.dart';

/// Use case for retrieving fasting reminder settings
class GetFastingReminderSettingsUseCase {
  final FastingRemindersRepository repository;

  GetFastingReminderSettingsUseCase(this.repository);

  /// Get current fasting reminder settings
  Future<FastingReminderSettings> call() async {
    return await repository.getSettings();
  }
}
