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

  /// Schedule notifications across MULTIPLE days so the adhan keeps firing even
  /// if the user doesn't reopen the app for several days.
  /// [prayerTimesByDay] - Map of calendar-day → (prayer name → time). Each day
  /// is scheduled with its own, non-colliding notification ids.
  Future<void> scheduleMultiDayPrayerNotifications({
    required Map<DateTime, Map<String, DateTime>> prayerTimesByDay,
    required NotificationSettingsModel settings,
    String? locationName,
  });

  /// Cancel a specific prayer notification
  Future<void> cancelPrayerNotification(String prayerName);

  /// Cancel every scheduled PRAYER notification (all prayers, all days) and
  /// nothing else.
  ///
  /// Prefer this over [cancelAllNotifications] whenever the intent is "stop the
  /// adhan": azkar, wird, fasting, daily-inspiration and feature-nudge
  /// reminders are scheduled on the same plugin under their own ids, and they
  /// only re-arm on their own settings change or cold start — so a global
  /// cancel silently destroys them for days.
  Future<void> cancelPrayerSchedules();

  /// Cancel ALL scheduled notifications app-wide, across every feature.
  ///
  /// This is a blunt instrument — see [cancelPrayerSchedules] before reaching
  /// for it.
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
}
