import '../../data/models/notification_settings_model.dart';

/// Repository interface for managing prayer notifications
abstract class NotificationRepository {
  /// Initialize the notification system
  Future<void> initialize();

  /// Request notification permissions from the user
  Future<bool> requestPermissions();

  /// Check if notification permissions are granted
  Future<bool> hasPermissions();

  /// Schedule notifications for a specific prayer
  /// [prayerName] - Name of the prayer (e.g., 'Fajr', 'Dhuhr')
  /// [prayerTime] - DateTime when the prayer should be notified
  /// [settings] - Notification settings for this prayer
  /// [locationName] - User's location to display in notification
  Future<void> schedulePrayerNotification({
    required String prayerName,
    required String prayerNameArabic,
    required DateTime prayerTime,
    required PrayerNotificationSettings settings,
    String? locationName,
  });

  /// Schedule notifications for all five daily prayers
  /// [prayerTimes] - Map of prayer names to their times
  /// [settings] - Complete notification settings
  /// [locationName] - User's location to display in notification
  Future<void> scheduleAllPrayerNotifications({
    required Map<String, DateTime> prayerTimes,
    required NotificationSettingsModel settings,
    String? locationName,
  });

  /// Cancel a specific prayer notification
  Future<void> cancelPrayerNotification(String prayerName);

  /// Cancel all scheduled prayer notifications
  Future<void> cancelAllNotifications();

  /// Check if there are active notifications
  Future<bool> hasActiveNotifications();

  /// Get list of all scheduled notification IDs
  Future<List<int>> getScheduledNotificationIds();

  /// Show persistent notification with next prayer info
  /// This notification stays in the notification bar until dismissed
  Future<void> showPersistentNotification({
    required String nextPrayerName,
    required String nextPrayerNameArabic,
    required DateTime nextPrayerTime,
    String? locationName,
  });

  /// Hide/remove the persistent notification
  Future<void> hidePersistentNotification();

  /// Schedule weekly fasting reminder notification for Monday or Thursday
  /// [dayName] - 'Monday' or 'Thursday'
  /// [notificationTime] - Time in "HH:mm" format (24-hour)
  /// [enabled] - Whether the notification is enabled
  /// [vibration] - Whether to vibrate on notification
  Future<void> scheduleFastingNotification({
    required String dayName,
    required String dayNameArabic,
    required String notificationTime,
    required bool enabled,
    required bool vibration,
  });

  /// Cancel fasting notification for specific day
  Future<void> cancelFastingNotification(String dayName);

  /// Schedule all fasting notifications based on settings
  /// [mondayEnabled] - Whether Monday fasting notification is enabled
  /// [thursdayEnabled] - Whether Thursday fasting notification is enabled
  /// [notificationTime] - Time in "HH:mm" format for both notifications
  /// [vibration] - Whether to vibrate on notification
  Future<void> scheduleAllFastingNotifications({
    required bool mondayEnabled,
    required bool thursdayEnabled,
    required String notificationTime,
    required bool vibration,
  });
}
