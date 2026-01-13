import 'package:flutter/material.dart';
import '../models/notification_settings_model.dart';
import '../../domain/repositories/notification_repository.dart';
import 'package:windows_notification/windows_notification.dart';
import 'package:windows_notification/notification_message.dart';

/// Windows-specific implementation of NotificationRepository
/// Uses windows_notification package for native Windows toast notifications
class NotificationRepositoryImplWindows implements NotificationRepository {
  late final WindowsNotification _winNotifyPlugin;
  bool _isInitialized = false;

  // Track scheduled notifications
  final Map<int, Map<String, dynamic>> _scheduledNotifications = {};

  // Notification IDs for each prayer
  static const String _fajrId = 'fajr_100';
  static const String _dhuhrId = 'dhuhr_101';
  static const String _asrId = 'asr_102';
  static const String _maghribId = 'maghrib_103';
  static const String _ishaId = 'isha_104';
  static const String _persistentId = 'persistent_999';

  // Fasting notification IDs
  static const String _mondayFastingId = 'monday_200';
  static const String _thursdayFastingId = 'thursday_201';

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize WindowsNotification
      // Setting applicationId to null allows Windows to use the app's own icon
      // This will show the Flutter app icon instead of PowerShell icon
      _winNotifyPlugin = WindowsNotification(applicationId: null);

      _isInitialized = true;
      debugPrint('✅ Windows Notification Service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Windows Notification Service: $e');
      rethrow;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    // Windows doesn't require explicit permission request for notifications
    // They're always allowed by default
    debugPrint('✅ Windows notifications don\'t require permission request');
    return true;
  }

  @override
  Future<bool> hasPermissions() async {
    // Windows notifications are always allowed
    debugPrint('✅ Windows notifications are always permitted');
    return true;
  }

  @override
  Future<void> schedulePrayerNotification({
    required String prayerName,
    required String prayerNameArabic,
    required DateTime prayerTime,
    required PrayerNotificationSettings settings,
    String? locationName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!settings.enabled) {
      await cancelPrayerNotification(prayerName);
      return;
    }

    // Calculate notification time based on timing setting
    DateTime notificationTime = prayerTime;
    String timingText = '';

    switch (settings.timing) {
      case NotificationTiming.before5Min:
        notificationTime = prayerTime.subtract(const Duration(minutes: 5));
        timingText = ' (بعد 5 دقائق)';
        break;
      case NotificationTiming.before10Min:
        notificationTime = prayerTime.subtract(const Duration(minutes: 10));
        timingText = ' (بعد 10 دقائق)';
        break;
      case NotificationTiming.before15Min:
        notificationTime = prayerTime.subtract(const Duration(minutes: 15));
        timingText = ' (بعد 15 دقيقة)';
        break;
      case NotificationTiming.onTime:
        timingText = '';
        break;
    }

    // Skip if notification time is in the past
    if (notificationTime.isBefore(DateTime.now())) {
      debugPrint('⏭️  Skipping $prayerName notification - time has passed');
      return;
    }

    final String notificationId = _getNotificationId(prayerName);
    final String formattedTime = _formatTime(prayerTime);
    final String location = locationName ?? '';

    // Check if notification should be shown immediately (within 5 seconds)
    final delay = notificationTime.difference(DateTime.now());
    if (delay.inSeconds <= 5) {
      // Show immediately for test notifications
      debugPrint('📬 Showing immediate notification for $prayerName');
      await _showWindowsNotification(
        id: notificationId,
        title: '🕌 حان وقت صلاة $prayerNameArabic$timingText',
        body: '$formattedTime${location.isNotEmpty ? ' • $location' : ''}',
        group: 'prayer_notifications',
      );
      return;
    }

    // Store scheduled notification info
    final int hashCode = notificationId.hashCode;
    _scheduledNotifications[hashCode] = {
      'id': notificationId,
      'prayerName': prayerName,
      'prayerNameArabic': prayerNameArabic,
      'time': notificationTime,
      'settings': settings,
      'locationName': locationName,
    };

    // Schedule notification using Future.delayed
    Future.delayed(delay, () {
      if (_scheduledNotifications.containsKey(hashCode)) {
        _showWindowsNotification(
          id: notificationId,
          title: '🕌 حان وقت صلاة $prayerNameArabic$timingText',
          body: '$formattedTime${location.isNotEmpty ? ' • $location' : ''}',
          group: 'prayer_notifications',
        );
      }
    });

    debugPrint(
      '⏰ Scheduled Windows notification for $prayerName at $notificationTime',
    );
  }

  @override
  Future<void> scheduleAllPrayerNotifications({
    required Map<String, DateTime> prayerTimes,
    required NotificationSettingsModel settings,
    String? locationName,
  }) async {
    debugPrint('🔔 ═══════════════════════════════════════════════════');
    debugPrint('🔔 Starting Windows notification scheduling process');
    debugPrint('🔔 ═══════════════════════════════════════════════════');

    await cancelAllNotifications();
    debugPrint('❌ Old notification schedules cancelled');

    if (!settings.masterEnabled) {
      debugPrint(
        '⚠️  Master notification toggle is OFF - no notifications scheduled',
      );
      debugPrint('🔔 ═══════════════════════════════════════════════════');
      return;
    }

    debugPrint('\n📅 Prayer Times:');
    prayerTimes.forEach((prayer, time) {
      debugPrint('   $prayer: $time');
    });

    final prayerSettings = {
      'Fajr': (settings.fajrSettings, 'الفجر'),
      'Dhuhr': (settings.dhuhrSettings, 'الظهر'),
      'Asr': (settings.asrSettings, 'العصر'),
      'Maghrib': (settings.maghribSettings, 'المغرب'),
      'Isha': (settings.ishaSettings, 'العشاء'),
    };

    debugPrint('\n⏰ Scheduling Notifications:');

    for (final entry in prayerSettings.entries) {
      final prayerName = entry.key;
      final prayerSetting = entry.value.$1;
      final prayerNameArabic = entry.value.$2;
      final prayerTime = prayerTimes[prayerName];

      if (prayerTime != null) {
        await schedulePrayerNotification(
          prayerName: prayerName,
          prayerNameArabic: prayerNameArabic,
          prayerTime: prayerTime,
          settings: prayerSetting,
          locationName: locationName,
        );
      }
    }

    debugPrint('\n✅ Windows notification scheduling completed successfully');
    debugPrint('🔔 ═══════════════════════════════════════════════════\n');
  }

  @override
  Future<void> cancelPrayerNotification(String prayerName) async {
    final String notificationId = _getNotificationId(prayerName);

    // Remove from scheduled notifications
    _scheduledNotifications.removeWhere(
      (key, value) => value['id'] == notificationId,
    );

    // Remove from Windows Action Center
    try {
      await _winNotifyPlugin.removeNotificationId(
        notificationId,
        'prayer_notifications',
      );
      debugPrint('🗑️  Cancelled notification for $prayerName');
    } catch (e) {
      debugPrint('⚠️  Error cancelling notification for $prayerName: $e');
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    // Clear scheduled notifications map
    _scheduledNotifications.clear();

    // Clear all notifications from Windows Action Center
    try {
      await _winNotifyPlugin.clearNotificationHistory();
      debugPrint('🗑️  Cleared all Windows notifications from Action Center');
    } catch (e) {
      debugPrint('⚠️  Error clearing notifications: $e');
    }
  }

  @override
  Future<bool> hasActiveNotifications() async {
    return _scheduledNotifications.isNotEmpty;
  }

  @override
  Future<List<int>> getScheduledNotificationIds() async {
    return _scheduledNotifications.keys.toList();
  }

  @override
  Future<void> showPersistentNotification({
    required String nextPrayerName,
    required String nextPrayerNameArabic,
    required DateTime nextPrayerTime,
    String? locationName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final now = DateTime.now();
    final difference = nextPrayerTime.difference(now);

    String timeRemaining = '';
    if (difference.inHours > 0) {
      timeRemaining =
          '${difference.inHours} ساعة و ${difference.inMinutes.remainder(60)} دقيقة';
    } else if (difference.inMinutes > 0) {
      timeRemaining = '${difference.inMinutes} دقيقة';
    } else {
      timeRemaining = 'الآن';
    }

    final formattedTime = _formatTime(nextPrayerTime);

    await _showWindowsNotification(
      id: _persistentId,
      title: '🕌 الصلاة القادمة: $nextPrayerNameArabic',
      body: '⏰ الوقت: $formattedTime\n⏳ متبقي: $timeRemaining',
      group: 'persistent_prayer',
    );

    debugPrint('📌 Persistent notification shown for $nextPrayerNameArabic');
  }

  @override
  Future<void> hidePersistentNotification() async {
    try {
      await _winNotifyPlugin.removeNotificationId(
        _persistentId,
        'persistent_prayer',
      );
      debugPrint('🗑️  Persistent notification removed');
    } catch (e) {
      debugPrint('⚠️  Error removing persistent notification: $e');
    }
  }

  @override
  Future<void> scheduleFastingNotification({
    required String dayName,
    required String dayNameArabic,
    required String notificationTime,
    required bool enabled,
    required bool vibration,
  }) async {
    final String notificationId = dayName.toLowerCase() == 'monday'
        ? _mondayFastingId
        : _thursdayFastingId;

    if (!enabled) {
      await cancelFastingNotification(dayName);
      return;
    }

    // Parse time
    final timeParts = notificationTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Calculate next occurrence
    final now = DateTime.now();
    final targetWeekday = dayName.toLowerCase() == 'monday'
        ? DateTime.monday
        : DateTime.thursday;

    int daysUntilTarget = targetWeekday - now.weekday;
    if (daysUntilTarget <= 0) {
      daysUntilTarget += 7;
    }

    // Check if today is target and time hasn't passed
    if (daysUntilTarget == 7) {
      final todayAtTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (todayAtTime.isAfter(now)) {
        daysUntilTarget = 0;
      }
    }

    final nextNotificationDate = DateTime(
      now.year,
      now.month,
      now.day + daysUntilTarget,
      hour,
      minute,
    );

    debugPrint(
      '🍽️  Scheduling fasting notification for $dayName at $nextNotificationDate',
    );

    // Schedule using Future.delayed and repeat weekly
    _scheduleFastingNotificationRecurring(
      notificationId: notificationId,
      dayName: dayName,
      dayNameArabic: dayNameArabic,
      hour: hour,
      minute: minute,
      targetWeekday: targetWeekday,
    );
  }

  void _scheduleFastingNotificationRecurring({
    required String notificationId,
    required String dayName,
    required String dayNameArabic,
    required int hour,
    required int minute,
    required int targetWeekday,
  }) {
    final now = DateTime.now();
    int daysUntilTarget = targetWeekday - now.weekday;
    if (daysUntilTarget <= 0) {
      daysUntilTarget += 7;
    }

    final todayAtTime = DateTime(now.year, now.month, now.day, hour, minute);
    if (daysUntilTarget == 7 && todayAtTime.isAfter(now)) {
      daysUntilTarget = 0;
    }

    final nextNotificationDate = DateTime(
      now.year,
      now.month,
      now.day + daysUntilTarget,
      hour,
      minute,
    );

    final delay = nextNotificationDate.difference(DateTime.now());

    Future.delayed(delay, () {
      _showWindowsNotification(
        id: notificationId,
        title: '🌙 تذكير بصيام $dayNameArabic',
        body: 'غدًا يوم $dayNameArabic، لا تنسى نية الصيام 🤲',
        group: 'fasting_reminders',
      );

      // Schedule next occurrence (7 days later)
      _scheduleFastingNotificationRecurring(
        notificationId: notificationId,
        dayName: dayName,
        dayNameArabic: dayNameArabic,
        hour: hour,
        minute: minute,
        targetWeekday: targetWeekday,
      );
    });
  }

  @override
  Future<void> cancelFastingNotification(String dayName) async {
    final String notificationId = dayName.toLowerCase() == 'monday'
        ? _mondayFastingId
        : _thursdayFastingId;

    try {
      await _winNotifyPlugin.removeNotificationId(
        notificationId,
        'fasting_reminders',
      );
      debugPrint('🗑️  Cancelled fasting notification for $dayName');
    } catch (e) {
      debugPrint('⚠️  Error cancelling fasting notification: $e');
    }
  }

  @override
  Future<void> scheduleAllFastingNotifications({
    required bool mondayEnabled,
    required bool thursdayEnabled,
    required String notificationTime,
    required bool vibration,
  }) async {
    debugPrint('🍽️  Scheduling all fasting notifications');
    debugPrint('🍽️  Monday: $mondayEnabled, Thursday: $thursdayEnabled');

    await scheduleFastingNotification(
      dayName: 'Monday',
      dayNameArabic: 'الإثنين',
      notificationTime: notificationTime,
      enabled: mondayEnabled,
      vibration: vibration,
    );

    await scheduleFastingNotification(
      dayName: 'Thursday',
      dayNameArabic: 'الخميس',
      notificationTime: notificationTime,
      enabled: thursdayEnabled,
      vibration: vibration,
    );

    debugPrint('✅ All fasting notifications scheduled successfully');
  }

  // Helper: Show Windows notification
  Future<void> _showWindowsNotification({
    required String id,
    required String title,
    required String body,
    required String group,
  }) async {
    try {
      final message = NotificationMessage.fromPluginTemplate(id, title, body);

      await _winNotifyPlugin.showNotificationPluginTemplate(message);
      debugPrint('📬 Windows notification sent: $title');
    } catch (e) {
      debugPrint('❌ Error showing Windows notification: $e');
    }
  }

  // Helper: Get notification ID for prayer
  String _getNotificationId(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
      case 'الفجر':
        return _fajrId;
      case 'dhuhr':
      case 'الظهر':
        return _dhuhrId;
      case 'asr':
      case 'العصر':
        return _asrId;
      case 'maghrib':
      case 'المغرب':
        return _maghribId;
      case 'isha':
      case 'العشاء':
        return _ishaId;
      default:
        return 'unknown_0';
    }
  }

  // Helper: Format time for display
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحاً';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
