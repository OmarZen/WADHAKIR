import 'dart:developer';
import 'adhan_player_service.dart';
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
    ReceivedAction receivedAction,
  ) async {
    // Handle notification actions here
    // For example: Mark prayer as done, snooze, etc.
    log('Notification action received: ${receivedAction.actionType}');

    // Stop adhan playback when any action is taken
    AdhanPlayerService().stopAdhan();
  }

  /// Called when a notification is created
  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    log('Notification created: ${receivedNotification.id}');
  }

  /// Called when a notification is displayed
  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    log('Notification displayed: ${receivedNotification.id}');

    // Get sound settings from payload
    final soundPath = receivedNotification.payload?['soundPath'];
    final useCustomAdhan =
        receivedNotification.payload?['useCustomAdhan'] == 'true';
    final prayerName = receivedNotification.payload?['prayer'];

    log(
      'Notification for $prayerName - useCustomAdhan: $useCustomAdhan, soundPath: ${soundPath ?? "none"}',
    );

    // Only play custom adhan if explicitly using custom sound
    // Default notification sound is handled by the channel itself
    if (useCustomAdhan && soundPath != null && soundPath.isNotEmpty) {
      log('Playing custom adhan for $prayerName');
      AdhanPlayerService().playAdhan(
        soundPath: soundPath,
        onComplete: () {
          log('Adhan playback completed for $prayerName');
        },
      );
    } else {
      log('Using default notification sound for $prayerName (no custom adhan)');
    }
  }

  /// Called when a notification is dismissed
  @pragma('vm:entry-point')
  static Future<void> _onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    log('Notification dismissed: ${receivedAction.id}');

    // Stop adhan playback when notification is dismissed
    AdhanPlayerService().stopAdhan();
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

  /// Convenience wrapper for the UI: trigger a default-sound test notification
  /// using a neutral "test" prayer name so the user can confirm the channel +
  /// permission flow without committing to a particular prayer's settings.
  /// Returns false if permission is denied.
  Future<bool> sendQuickTest() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      final hasPerm = await hasPermissions();
      if (!hasPerm) {
        final granted = await requestPermissions();
        if (!granted) return false;
      }
      await sendTestNotification(
        prayerName: 'TestPrayer',
        prayerNameArabic: 'تنبيه تجريبي',
      );
      return true;
    } catch (e) {
      log('sendQuickTest error: $e');
      return false;
    }
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

  /// Send a test notification immediately (for testing volume/flip controls)
  Future<void> sendTestNotification({
    required String prayerName,
    required String prayerNameArabic,
    String? customSoundPath,
  }) async {
    log('🔔 Sending test notification for $prayerName');

    // Ensure permissions are granted
    final hasPermission = await hasPermissions();
    if (!hasPermission) {
      final granted = await requestPermissions();
      if (!granted) {
        throw Exception('Notification permissions not granted');
      }
    }

    // Use repository to send test notification (platform-aware)
    // This will use Windows implementation on Windows, mobile on mobile
    try {
      // Create a test notification using the repository's implementation
      await _repository.schedulePrayerNotification(
        prayerName: 'TestNotification',
        prayerNameArabic: prayerNameArabic,
        prayerTime: DateTime.now().add(
          const Duration(seconds: 2),
        ), // Schedule 2 seconds from now
        settings: PrayerNotificationSettings(
          enabled: true,
          timing: NotificationTiming.onTime,
          sound: NotificationSound.defaultSound,
          vibration: true,
          customSoundPath: customSoundPath,
        ),
        locationName: 'Test Location',
      );

      log('🔔 Test notification scheduled successfully for $prayerName');
    } catch (e) {
      log('❌ Error scheduling test notification: $e');
      rethrow;
    }
  }
}
