import 'package:wadhakir/data/models/fasting/fasting_reminder_settings_model.dart';
import 'package:wadhakir/domain/repositories/fasting_reminders_repository.dart';

/// Use case for getting a stream of fasting reminder settings changes
class GetFastingReminderSettingsStreamUseCase {
  final FastingRemindersRepository repository;

  GetFastingReminderSettingsStreamUseCase(this.repository);

  /// Get stream of fasting reminder settings changes
  Stream<FastingReminderSettings> call() {
    return repository.settingsStream;
  }
}
