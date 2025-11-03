import 'dart:developer';
import '../../../data/models/notification_settings_model.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../../domain/repositories/notification_repository.dart';
import '../../../data/repositories/notification_repository_impl.dart';

/// Service for managing prayer time notifications
class PrayerNotificationService {
  static final PrayerNotificationService _instance =
      PrayerNotificationService._internal();
  factory PrayerNotificationService() => _instance;
  PrayerNotificationService._internal();

  final NotificationRepository _repository = NotificationRepositoryImpl();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _repository.initialize();
    await _setupListeners();
    _isInitialized = true;
  }

  /// Setup notification action listeners
  Future<void> _setupListeners() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );
  }

  /// Called when a notification action is received
  @pragma('vm:entry-point')
  static Future<void> _onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Handle notification actions here
    // For example: Mark prayer as done, snooze, etc.
    log('Notification action received: ${receivedAction.actionType}');
  }

  /// Called when a notification is created
  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    log('Notification created: ${receivedNotification.id}');
  }

  /// Called when a notification is displayed
  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    log('Notification displayed: ${receivedNotification.id}');
  }

  /// Called when a notification is dismissed
  @pragma('vm:entry-point')
  static Future<void> _onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    log('Notification dismissed: ${receivedAction.id}');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    return await _repository.requestPermissions();
  }

  /// Check if permissions are granted
  Future<bool> hasPermissions() async {
    return await _repository.hasPermissions();
  }

  /// Schedule prayer notifications
  Future<void> schedulePrayerNotifications({
    required Map<String, DateTime> prayerTimes,
    required NotificationSettingsModel settings,
    String? locationName,
  }) async {
    if (!settings.masterEnabled) {
      await cancelAllNotifications();
      return;
    }

    // Ensure permissions are granted
    final hasPermission = await hasPermissions();
    if (!hasPermission) {
      final granted = await requestPermissions();
      if (!granted) {
        throw Exception('Notification permissions not granted');
      }
    }

    // Schedule notifications for all prayers
    await _repository.scheduleAllPrayerNotifications(
      prayerTimes: prayerTimes,
      settings: settings,
      locationName: locationName,
    );
  }

  /// Cancel all prayer notifications
  Future<void> cancelAllNotifications() async {
    await _repository.cancelAllNotifications();
  }

  /// Cancel a specific prayer notification
  Future<void> cancelPrayerNotification(String prayerName) async {
    await _repository.cancelPrayerNotification(prayerName);
  }

  /// Check if there are active notifications
  Future<bool> hasActiveNotifications() async {
    return await _repository.hasActiveNotifications();
  }

  /// Get list of scheduled notification IDs
  Future<List<int>> getScheduledNotifications() async {
    return await _repository.getScheduledNotificationIds();
  }

  /// Show persistent notification with next prayer info
  Future<void> showPersistentNotification({
    required String nextPrayerName,
    required String nextPrayerNameArabic,
    required DateTime nextPrayerTime,
    String? locationName,
  }) async {
    await _repository.showPersistentNotification(
      nextPrayerName: nextPrayerName,
      nextPrayerNameArabic: nextPrayerNameArabic,
      nextPrayerTime: nextPrayerTime,
      locationName: locationName,
    );
  }

  /// Hide persistent notification
  Future<void> hidePersistentNotification() async {
    await _repository.hidePersistentNotification();
  }
}
