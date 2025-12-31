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
      ReceivedAction receivedAction) async {
    // Handle notification actions here
    // For example: Mark prayer as done, snooze, etc.
    log('Notification action received: ${receivedAction.actionType}');

    // Stop adhan playback when any action is taken
    AdhanPlayerService().stopAdhan();
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

    // Get sound settings from payload
    final soundPath = receivedNotification.payload?['soundPath'];
    final useCustomAdhan =
        receivedNotification.payload?['useCustomAdhan'] == 'true';
    final prayerName = receivedNotification.payload?['prayer'];

    log('Notification for $prayerName - useCustomAdhan: $useCustomAdhan, soundPath: ${soundPath ?? "none"}');

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
      ReceivedAction receivedAction) async {
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

    // Determine if using custom adhan
    final bool useCustomAdhan =
        customSoundPath != null && customSoundPath.isNotEmpty;
    final bool isFajr = prayerName.toLowerCase() == 'fajr';

    // Use appropriate channel based on sound preference
    final String channelKey = useCustomAdhan
        ? (isFajr ? 'fajr_channel' : 'prayers_channel')
        : (isFajr
            ? 'fajr_channel_default_sound'
            : 'prayers_channel_default_sound');

    // Create immediate notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999, // Test notification ID
        channelKey: channelKey,
        groupKey: 'prayer_notifications',
        title: '🕌 اختبار: حان وقت صلاة $prayerNameArabic',
        body:
            'هذا إشعار تجريبي${useCustomAdhan ? ' - اضغط أزرار الصوت أو اقلب الهاتف للإيقاف' : ''}',
        notificationLayout: NotificationLayout.Default,
        payload: {
          'prayer': prayerName,
          'time': DateTime.now().toIso8601String(),
          'soundPath': customSoundPath ?? '',
          'useCustomAdhan': useCustomAdhan.toString(),
          'isTest': 'true',
        },
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
        criticalAlert: isFajr,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISMISS',
          label: 'تم',
          actionType: ActionType.DismissAction,
        ),
      ],
    );

    log('🔔 Test notification sent for $prayerName');
  }

  /// Schedule all fasting notifications
  Future<void> scheduleAllFastingNotifications({
    required bool mondayEnabled,
    required bool thursdayEnabled,
    required String notificationTime,
    required bool vibration,
  }) async {
    await _repository.scheduleAllFastingNotifications(
      mondayEnabled: mondayEnabled,
      thursdayEnabled: thursdayEnabled,
      notificationTime: notificationTime,
      vibration: vibration,
    );
  }

  /// Cancel fasting notification for specific day
  Future<void> cancelFastingNotification(String dayName) async {
    await _repository.cancelFastingNotification(dayName);
  }
}
