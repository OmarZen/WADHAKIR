import '../repositories/notification_repository.dart';

/// Use case for canceling prayer notifications
class CancelPrayerNotificationsUseCase {
  final NotificationRepository repository;

  CancelPrayerNotificationsUseCase(this.repository);

  /// Cancel all scheduled prayer notifications
  Future<void> call() async {
    await repository.cancelAllNotifications();
  }
}
