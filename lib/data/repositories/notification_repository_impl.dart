import 'package:flutter/material.dart';
import '../models/notification_settings_model.dart';
import '../../domain/repositories/notification_repository.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  static const String _channelKeyFajr = 'fajr_channel';
  static const String _channelKeyPrayers = 'prayers_channel';
  static const String _channelKeyPersistent = 'persistent_prayer_channel';
  static const String _channelGroupKey = 'prayer_notifications';

  // Notification IDs for each prayer
  static const int _fajrId = 100;
  static const int _dhuhrId = 101;
  static const int _asrId = 102;
  static const int _maghribId = 103;
  static const int _ishaId = 104;
  static const int _persistentId = 999; // ID for persistent notification

  @override
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // Use default app icon
      [
        // Fajr channel - Maximum importance
        NotificationChannel(
          channelKey: _channelKeyFajr,
          channelName: 'صلاة الفجر',
          channelDescription: 'تنبيهات صلاة الفجر',
          importance: NotificationImportance.Max,
          defaultColor: const Color(0xFF20497D),
          ledColor: Colors.blue,
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
        ),
        // Other prayers channel - High importance
        NotificationChannel(
          channelKey: _channelKeyPrayers,
          channelName: 'أوقات الصلاة',
          channelDescription: 'تنبيهات الصلوات الخمس',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFFDAA520),
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
        ),
        // Persistent notification channel - Default importance (no sound)
        NotificationChannel(
          channelKey: _channelKeyPersistent,
          channelName: 'تنبيه دائم لأوقات الصلاة',
          channelDescription: 'إشعار دائم يعرض موعد الصلاة القادمة',
          importance: NotificationImportance.Default,
          defaultColor: const Color(0xFF20497D),
          playSound: false,
          enableVibration: false,
          channelShowBadge: false,
          locked: true, // Prevent user from dismissing
          onlyAlertOnce: true,
          icon: 'resource://mipmap/ic_launcher',
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: _channelGroupKey,
          channelGroupName: 'تنبيهات الصلاة',
        ),
      ],
    );
  }

  @override
  Future<bool> requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      return await AwesomeNotifications()
          .requestPermissionToSendNotifications();
    }
    return true;
  }

  @override
  Future<bool> hasPermissions() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  @override
  Future<void> schedulePrayerNotification({
    required String prayerName,
    required String prayerNameArabic,
    required DateTime prayerTime,
    required PrayerNotificationSettings settings,
    String? locationName,
  }) async {
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
      return;
    }

    final int notificationId = _getNotificationId(prayerName);
    final String channelKey = prayerName.toLowerCase() == 'fajr'
        ? _channelKeyFajr
        : _channelKeyPrayers;

    // Format time for display
    final String formattedTime = _formatTime(prayerTime);
    final String location = locationName ?? '';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: channelKey,
        groupKey: _channelGroupKey,
        title: '🕌 حان وقت صلاة $prayerNameArabic$timingText',
        body: '$formattedTime${location.isNotEmpty ? ' • $location' : ''}',
        notificationLayout: NotificationLayout.Default,
        payload: {
          'prayer': prayerName,
          'time': prayerTime.toIso8601String(),
          'soundPath': settings.customSoundPath ?? '', // Include sound path
        },
        wakeUpScreen: true,
        category: NotificationCategory.Alarm,
        criticalAlert: prayerName.toLowerCase() == 'fajr',
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISMISS',
          label: 'تم',
          actionType: ActionType.DismissAction,
        ),
      ],
      schedule: NotificationCalendar.fromDate(
        date: notificationTime,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }

  @override
  Future<void> scheduleAllPrayerNotifications({
    required Map<String, DateTime> prayerTimes,
    required NotificationSettingsModel settings,
    String? locationName,
  }) async {
    // Cancel all existing notifications first
    debugPrint('🔔 ═══════════════════════════════════════════════════');
    debugPrint('🔔 Starting notification scheduling process');
    debugPrint('🔔 ═══════════════════════════════════════════════════');

    await cancelAllNotifications();
    debugPrint('❌ Old notification schedules cancelled');

    if (!settings.masterEnabled) {
      debugPrint(
          '⚠️  Master notification toggle is OFF - no notifications scheduled');
      debugPrint('🔔 ═══════════════════════════════════════════════════');
      return;
    }

    debugPrint('\n📅 Original Prayer Times:');
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

    debugPrint('\n⏰ Notification Times After Applying Settings:');

    for (final entry in prayerSettings.entries) {
      final prayerName = entry.key;
      final prayerSetting = entry.value.$1;
      final prayerNameArabic = entry.value.$2;
      final prayerTime = prayerTimes[prayerName];

      if (prayerTime != null) {
        // Calculate what the notification time will be
        DateTime notificationTime = prayerTime;
        String timingDescription = '';

        if (prayerSetting.enabled) {
          switch (prayerSetting.timing) {
            case NotificationTiming.before5Min:
              notificationTime =
                  prayerTime.subtract(const Duration(minutes: 5));
              timingDescription = ' (5 minutes before)';
              break;
            case NotificationTiming.before10Min:
              notificationTime =
                  prayerTime.subtract(const Duration(minutes: 10));
              timingDescription = ' (10 minutes before)';
              break;
            case NotificationTiming.before15Min:
              notificationTime =
                  prayerTime.subtract(const Duration(minutes: 15));
              timingDescription = ' (15 minutes before)';
              break;
            case NotificationTiming.onTime:
              timingDescription = ' (on time)';
              break;
          }

          if (notificationTime.isBefore(DateTime.now())) {
            debugPrint(
                '   ⏭️  $prayerName ($prayerNameArabic): SKIPPED (time has passed)');
          } else {
            debugPrint(
                '   ✅ $prayerName ($prayerNameArabic): $notificationTime$timingDescription');
          }
        } else {
          debugPrint('   ⚪ $prayerName ($prayerNameArabic): DISABLED');
        }

        await schedulePrayerNotification(
          prayerName: prayerName,
          prayerNameArabic: prayerNameArabic,
          prayerTime: prayerTime,
          settings: prayerSetting,
          locationName: locationName,
        );
      }
    }

    debugPrint('\n✅ Notification scheduling completed successfully');
    debugPrint('🔔 ═══════════════════════════════════════════════════\n');
  }

  @override
  Future<void> cancelPrayerNotification(String prayerName) async {
    final notificationId = _getNotificationId(prayerName);
    await AwesomeNotifications().cancel(notificationId);
  }

  @override
  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  @override
  Future<bool> hasActiveNotifications() async {
    final scheduledNotifications =
        await AwesomeNotifications().listScheduledNotifications();
    return scheduledNotifications.isNotEmpty;
  }

  @override
  Future<List<int>> getScheduledNotificationIds() async {
    final scheduledNotifications =
        await AwesomeNotifications().listScheduledNotifications();
    return scheduledNotifications.map((n) => n.content!.id!).toList();
  }

  // Helper method to get notification ID for a prayer
  int _getNotificationId(String prayerName) {
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
        return 0;
    }
  }

  // Helper method to format time for display
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحاً';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Future<void> showPersistentNotification({
    required String nextPrayerName,
    required String nextPrayerNameArabic,
    required DateTime nextPrayerTime,
    String? locationName,
  }) async {
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

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _persistentId,
        channelKey: _channelKeyPersistent,
        title: '🕌 الصلاة القادمة: $nextPrayerNameArabic',
        body: '⏰ الوقت: $formattedTime\n⏳ متبقي: $timeRemaining',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
        autoDismissible: false,
        locked: true,
        displayOnForeground: true,
        displayOnBackground: true,
        backgroundColor: const Color(0xFF20497D),
        color: Colors.white,
        icon: 'resource://mipmap/launcher_icon',
        largeIcon: 'resource://mipmap/launcher_icon',
      ),
    );
  }

  @override
  Future<void> hidePersistentNotification() async {
    await AwesomeNotifications().cancel(_persistentId);
  }
}
