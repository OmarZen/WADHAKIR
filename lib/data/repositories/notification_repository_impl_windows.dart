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

  /// There is no `AlarmManager` on Windows. See [NotificationRepository].
  @override
  bool get usesNativeAlarms => false;

  // Track scheduled notifications
  final Map<int, Map<String, dynamic>> _scheduledNotifications = {};

  // Notification IDs for each prayer
  static const String _fajrId = 'fajr_100';
  static const String _dhuhrId = 'dhuhr_101';
  static const String _asrId = 'asr_102';
  static const String _maghribId = 'maghrib_103';
  static const String _ishaId = 'isha_104';
  static const String _persistentId = 'persistent_999';

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
  Future<void> scheduleMultiDayPrayerNotifications({
    required Map<DateTime, Map<String, DateTime>> prayerTimesByDay,
    required NotificationSettingsModel settings,
    String? locationName,
  }) async {
    // Windows toasts are scheduled with in-process Future.delayed and only fire
    // while the app runs, so a multi-day horizon isn't meaningful here — arm the
    // nearest day (today) whose times are still in the future.
    if (prayerTimesByDay.isEmpty) return;
    final today = prayerTimesByDay.keys.toList()..sort();
    await scheduleAllPrayerNotifications(
      prayerTimes: prayerTimesByDay[today.first]!,
      settings: settings,
      locationName: locationName,
    );
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
  Future<void> cancelPrayerSchedules() async {
    // Windows toasts are tracked per-prayer in _scheduledNotifications and have
    // no multi-day fan-out (see scheduleMultiDayPrayerNotifications), so
    // cancelling the five prayer ids covers every prayer toast this repository
    // owns — and leaves any other feature's entries alone.
    for (final prayerName in const [
      'Fajr',
      'Dhuhr',
      'Asr',
      'Maghrib',
      'Isha',
    ]) {
      await cancelPrayerNotification(prayerName);
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

    // Format time remaining with seconds for better accuracy
    String timeRemaining = '';
    if (difference.inDays > 0) {
      // More than a day (Fajr tomorrow case)
      final hours = difference.inHours.remainder(24);
      final minutes = difference.inMinutes.remainder(60);
      timeRemaining = '${difference.inDays} يوم و $hours ساعة و $minutes دقيقة';
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      final seconds = difference.inSeconds.remainder(60);
      timeRemaining = '$hours ساعة، $minutes دقيقة، $seconds ثانية';
    } else if (difference.inMinutes > 0) {
      final minutes = difference.inMinutes;
      final seconds = difference.inSeconds.remainder(60);
      timeRemaining = '$minutes دقيقة و $seconds ثانية';
    } else if (difference.inSeconds > 0) {
      final seconds = difference.inSeconds;
      timeRemaining = '$seconds ثانية';
    } else {
      timeRemaining = 'الآن';
    }

    final formattedTime = _formatTime(nextPrayerTime);
    final locationText = locationName != null && locationName.isNotEmpty
        ? '\n📍 $locationName'
        : '';

    // Enhanced notification body with better formatting
    final String notificationBody = '''⏰ الموعد: $formattedTime
⏳ الوقت المتبقي: $timeRemaining$locationText''';

    await _showWindowsNotification(
      id: _persistentId,
      title: '🕌 الصلاة القادمة: $nextPrayerNameArabic',
      body: notificationBody,
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
