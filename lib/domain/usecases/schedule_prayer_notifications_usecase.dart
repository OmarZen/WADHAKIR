import '../repositories/notification_repository.dart';
import '../../data/models/notification_settings_model.dart';

/// Use case for scheduling prayer notifications
class SchedulePrayerNotificationsUseCase {
  final NotificationRepository repository;

  SchedulePrayerNotificationsUseCase(this.repository);

  /// Schedule notifications for all prayers
  Future<void> call({
    required Map<String, DateTime> prayerTimes,
    required NotificationSettingsModel settings,
    String? locationName,
  }) async {
    // Ensure permissions are granted
    final hasPermission = await repository.hasPermissions();
    if (!hasPermission) {
      final granted = await repository.requestPermissions();
      if (!granted) {
        throw Exception('Notification permissions not granted');
      }
    }

    // Schedule all prayer notifications
    await repository.scheduleAllPrayerNotifications(
      prayerTimes: prayerTimes,
      settings: settings,
      locationName: locationName,
    );
  }
}
