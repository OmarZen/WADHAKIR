import '../repositories/notification_repository.dart';

/// Use case for canceling prayer notifications
class CancelPrayerNotificationsUseCase {
  final NotificationRepository repository;

  CancelPrayerNotificationsUseCase(this.repository);

  /// Cancel all scheduled prayer notifications — and only those. Deliberately
  /// NOT cancelAllNotifications(), which would also wipe azkar/wird/fasting/
  /// daily-inspiration reminders that this use case's name does not claim to
  /// touch.
  Future<void> call() async {
    await repository.cancelPrayerSchedules();
  }
}
