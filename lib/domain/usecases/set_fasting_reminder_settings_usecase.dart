import 'package:wadhakir/data/models/fasting/fasting_reminder_settings_model.dart';
import 'package:wadhakir/domain/repositories/fasting_reminders_repository.dart';

/// Use case for updating fasting reminder settings
class SetFastingReminderSettingsUseCase {
  final FastingRemindersRepository repository;

  SetFastingReminderSettingsUseCase(this.repository);

  /// Update fasting reminder settings
  Future<void> call(FastingReminderSettings settings) async {
    await repository.setSettings(settings);
  }
}
