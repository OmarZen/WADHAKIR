import 'package:wadhakir/data/models/fasting/fasting_reminder_settings_model.dart';

/// Abstract repository for fasting reminders settings
/// Handles persistence of fasting reminder user preferences
abstract class FastingRemindersRepository {
  /// Get current fasting reminder settings
  Future<FastingReminderSettings> getSettings();

  /// Update fasting reminder settings
  Future<void> setSettings(FastingReminderSettings settings);

  /// Stream of settings changes for reactive updates
  Stream<FastingReminderSettings> get settingsStream;

  /// Clear all fasting reminder settings (reset to defaults)
  Future<void> clearSettings();
}
