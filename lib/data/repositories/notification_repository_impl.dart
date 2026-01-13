import 'dart:io';
import 'package:flutter/material.dart';
import 'notification_repository_impl_windows.dart';
import '../models/notification_settings_model.dart';
import '../../domain/repositories/notification_repository.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

/// Factory class to return the appropriate notification repository implementation
/// based on the current platform
class NotificationRepositoryImpl implements NotificationRepository {
  // Singleton pattern
  static NotificationRepositoryImpl? _instance;

  // Delegate to platform-specific implementation
  late final NotificationRepository _platformRepository;

  factory NotificationRepositoryImpl() {
    _instance ??= NotificationRepositoryImpl._internal();
    return _instance!;
  }

  NotificationRepositoryImpl._internal() {
    // Platform detection: Use Windows implementation on Windows, mobile implementation otherwise
    if (Platform.isWindows) {
      debugPrint('🪟 Using Windows Notification Repository');
      _platformRepository = NotificationRepositoryImplWindows();
    } else {
      debugPrint(
        '📱 Using Mobile Notification Repository (awesome_notifications)',
      );
      _platformRepository = _MobileNotificationRepositoryImpl();
    }
  }

  @override
  Future<void> initialize() => _platformRepository.initialize();

  @override
  Future<bool> requestPermissions() => _platformRepository.requestPermissions();

  @override
  Future<bool> hasPermissions() => _platformRepository.hasPermissions();

  @override
  Future<void> schedulePrayerNotification({
    required String prayerName,
    required String prayerNameArabic,
    required DateTime prayerTime,
    required PrayerNotificationSettings settings,
    String? locationName,
  }) => _platformRepository.schedulePrayerNotification(
    prayerName: prayerName,
    prayerNameArabic: prayerNameArabic,
    prayerTime: prayerTime,
    settings: settings,
    locationName: locationName,
  );

  @override
  Future<void> scheduleAllPrayerNotifications({
    required Map<String, DateTime> prayerTimes,
    required NotificationSettingsModel settings,
    String? locationName,
  }) => _platformRepository.scheduleAllPrayerNotifications(
    prayerTimes: prayerTimes,
    settings: settings,
    locationName: locationName,
  );

  @override
  Future<void> cancelPrayerNotification(String prayerName) =>
      _platformRepository.cancelPrayerNotification(prayerName);

  @override
  Future<void> cancelAllNotifications() =>
      _platformRepository.cancelAllNotifications();

  @override
  Future<bool> hasActiveNotifications() =>
      _platformRepository.hasActiveNotifications();

  @override
  Future<List<int>> getScheduledNotificationIds() =>
      _platformRepository.getScheduledNotificationIds();

  @override
  Future<void> showPersistentNotification({
    required String nextPrayerName,
    required String nextPrayerNameArabic,
    required DateTime nextPrayerTime,
    String? locationName,
  }) => _platformRepository.showPersistentNotification(
    nextPrayerName: nextPrayerName,
    nextPrayerNameArabic: nextPrayerNameArabic,
    nextPrayerTime: nextPrayerTime,
    locationName: locationName,
  );

  @override
  Future<void> hidePersistentNotification() =>
      _platformRepository.hidePersistentNotification();

  @override
  Future<void> scheduleFastingNotification({
    required String dayName,
    required String dayNameArabic,
    required String notificationTime,
    required bool enabled,
    required bool vibration,
  }) => _platformRepository.scheduleFastingNotification(
    dayName: dayName,
    dayNameArabic: dayNameArabic,
    notificationTime: notificationTime,
    enabled: enabled,
    vibration: vibration,
  );

  @override
  Future<void> cancelFastingNotification(String dayName) =>
      _platformRepository.cancelFastingNotification(dayName);

  @override
  Future<void> scheduleAllFastingNotifications({
    required bool mondayEnabled,
    required bool thursdayEnabled,
    required String notificationTime,
    required bool vibration,
  }) => _platformRepository.scheduleAllFastingNotifications(
    mondayEnabled: mondayEnabled,
    thursdayEnabled: thursdayEnabled,
    notificationTime: notificationTime,
    vibration: vibration,
  );
}

/// Mobile implementation using awesome_notifications
/// This is the original implementation moved into a private class
class _MobileNotificationRepositoryImpl implements NotificationRepository {
  static const String _channelKeyFajr = 'fajr_channel';
  static const String _channelKeyPrayers = 'prayers_channel';
  static const String _channelKeyFajrDefault = 'fajr_channel_default_sound';
  static const String _channelKeyPrayersDefault =
      'prayers_channel_default_sound';
  static const String _channelKeyPersistent = 'persistent_prayer_channel';
  static const String _channelKeyFasting = 'fasting_channel';
  static const String _channelGroupKey = 'prayer_notifications';

  // Notification IDs for each prayer
  static const int _fajrId = 100;
  static const int _dhuhrId = 101;
  static const int _asrId = 102;
  static const int _maghribId = 103;
  static const int _ishaId = 104;
  static const int _persistentId = 999; // ID for persistent notification

  // Notification IDs for fasting reminders
  static const int _mondayFastingId = 200;
  static const int _thursdayFastingId = 201;

  @override
  Future<void> initialize() async {
    // First, remove old channels if they exist to force recreation
    try {
      await AwesomeNotifications().removeChannel(_channelKeyFajr);
      await AwesomeNotifications().removeChannel(_channelKeyPrayers);
      await AwesomeNotifications().removeChannel(_channelKeyFajrDefault);
      await AwesomeNotifications().removeChannel(_channelKeyPrayersDefault);
    } catch (e) {
      // Channels might not exist yet, ignore error
    }

    await AwesomeNotifications().initialize(
      'resource://drawable/ic_notification', // Use custom notification icon
      [
        // Fajr channel - Custom adhan (no notification sound)
        NotificationChannel(
          channelKey: _channelKeyFajr,
          channelName: 'صلاة الفجر (أذان)',
          channelDescription: 'تنبيهات صلاة الفجر مع الأذان المخصص',
          importance: NotificationImportance.Max,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          playSound: false,
          soundSource: null,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
        ),
        // Other prayers channel - Custom adhan (no notification sound)
        NotificationChannel(
          channelKey: _channelKeyPrayers,
          channelName: 'أوقات الصلاة (أذان)',
          channelDescription: 'تنبيهات الصلوات مع الأذان المخصص',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          playSound: false,
          soundSource: null,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
        ),
        // Fajr channel - Default notification sound (short beep)
        NotificationChannel(
          channelKey: _channelKeyFajrDefault,
          channelName: 'صلاة الفجر (صوت النظام)',
          channelDescription: 'تنبيهات صلاة الفجر بصوت النظام',
          importance: NotificationImportance.Max,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
        ),
        // Other prayers channel - Default notification sound (short beep)
        NotificationChannel(
          channelKey: _channelKeyPrayersDefault,
          channelName: 'أوقات الصلاة (صوت النظام)',
          channelDescription: 'تنبيهات الصلوات بصوت النظام',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
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
          icon: 'resource://drawable/ic_notification',
        ),
        // Fasting reminders channel - High importance with default sound
        NotificationChannel(
          channelKey: _channelKeyFasting,
          channelName: 'تذكير بالصيام',
          channelDescription: 'تنبيهات صيام الإثنين والخميس',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
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
    final bool isFajr = prayerName.toLowerCase() == 'fajr';
    final bool useCustomAdhan =
        settings.customSoundPath != null &&
        settings.customSoundPath!.isNotEmpty;

    // Select channel based on sound preference
    final String channelKey = useCustomAdhan
        ? (isFajr ? _channelKeyFajr : _channelKeyPrayers)
        : (isFajr ? _channelKeyFajrDefault : _channelKeyPrayersDefault);

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
          'soundPath': settings.customSoundPath ?? '',
          'useCustomAdhan': useCustomAdhan.toString(),
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
        '⚠️  Master notification toggle is OFF - no notifications scheduled',
      );
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
              notificationTime = prayerTime.subtract(
                const Duration(minutes: 5),
              );
              timingDescription = ' (5 minutes before)';
              break;
            case NotificationTiming.before10Min:
              notificationTime = prayerTime.subtract(
                const Duration(minutes: 10),
              );
              timingDescription = ' (10 minutes before)';
              break;
            case NotificationTiming.before15Min:
              notificationTime = prayerTime.subtract(
                const Duration(minutes: 15),
              );
              timingDescription = ' (15 minutes before)';
              break;
            case NotificationTiming.onTime:
              timingDescription = ' (on time)';
              break;
          }

          if (notificationTime.isBefore(DateTime.now())) {
            debugPrint(
              '   ⏭️  $prayerName ($prayerNameArabic): SKIPPED (time has passed)',
            );
          } else {
            debugPrint(
              '   ✅ $prayerName ($prayerNameArabic): $notificationTime$timingDescription',
            );
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
    final scheduledNotifications = await AwesomeNotifications()
        .listScheduledNotifications();
    return scheduledNotifications.isNotEmpty;
  }

  @override
  Future<List<int>> getScheduledNotificationIds() async {
    final scheduledNotifications = await AwesomeNotifications()
        .listScheduledNotifications();
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

  @override
  Future<void> scheduleFastingNotification({
    required String dayName,
    required String dayNameArabic,
    required String notificationTime,
    required bool enabled,
    required bool vibration,
  }) async {
    final notificationId = dayName.toLowerCase() == 'monday'
        ? _mondayFastingId
        : _thursdayFastingId;

    if (!enabled) {
      await AwesomeNotifications().cancel(notificationId);
      debugPrint('🍽️ Cancelled fasting notification for $dayName');
      return;
    }

    // Parse the time string (format: "HH:mm")
    final timeParts = notificationTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Calculate next occurrence of the day
    final now = DateTime.now();
    final targetWeekday = dayName.toLowerCase() == 'monday'
        ? DateTime.monday
        : DateTime.thursday;

    // Find next occurrence of the target day
    int daysUntilTarget = targetWeekday - now.weekday;
    if (daysUntilTarget <= 0) {
      // If today is the target day but time has passed, schedule for next week
      daysUntilTarget += 7;
    }

    // Check if today is the target day and time hasn't passed yet
    if (daysUntilTarget == 7) {
      final todayAtTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (todayAtTime.isAfter(now)) {
        daysUntilTarget = 0; // Schedule for today
      }
    }

    final nextNotificationDate = DateTime(
      now.year,
      now.month,
      now.day + daysUntilTarget,
      hour,
      minute,
    );

    debugPrint('🍽️ ═══════════════════════════════════════════════════');
    debugPrint('🍽️ Scheduling fasting notification for $dayName');
    debugPrint('🍽️ Notification time: $notificationTime');
    debugPrint('🍽️ Next occurrence: $nextNotificationDate');
    debugPrint('🍽️ Vibration: $vibration');

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: _channelKeyFasting,
        title: '🌙 تذكير بصيام $dayNameArabic',
        body: 'غدًا يوم $dayNameArabic، لا تنسى نية الصيام 🤲',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
        autoDismissible: true,
        displayOnForeground: true,
        displayOnBackground: true,
        backgroundColor: const Color(0xFF20497D),
        color: Colors.white,
        icon: 'resource://drawable/ic_notification',
        largeIcon: 'resource://mipmap/launcher_icon',
      ),
      schedule: NotificationCalendar(
        weekday: targetWeekday,
        hour: hour,
        minute: minute,
        second: 0,
        millisecond: 0,
        repeats: true, // Repeat weekly
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );

    debugPrint('✅ Fasting notification scheduled successfully for $dayName');
    debugPrint('🍽️ ═══════════════════════════════════════════════════\n');
  }

  @override
  Future<void> cancelFastingNotification(String dayName) async {
    final notificationId = dayName.toLowerCase() == 'monday'
        ? _mondayFastingId
        : _thursdayFastingId;

    await AwesomeNotifications().cancel(notificationId);
    debugPrint('🍽️ Cancelled fasting notification for $dayName');
  }

  @override
  Future<void> scheduleAllFastingNotifications({
    required bool mondayEnabled,
    required bool thursdayEnabled,
    required String notificationTime,
    required bool vibration,
  }) async {
    debugPrint('🍽️ ═══════════════════════════════════════════════════');
    debugPrint('🍽️ Scheduling all fasting notifications');
    debugPrint('🍽️ Monday enabled: $mondayEnabled');
    debugPrint('🍽️ Thursday enabled: $thursdayEnabled');
    debugPrint('🍽️ Notification time: $notificationTime');

    // Schedule Monday fasting notification
    await scheduleFastingNotification(
      dayName: 'Monday',
      dayNameArabic: 'الإثنين',
      notificationTime: notificationTime,
      enabled: mondayEnabled,
      vibration: vibration,
    );

    // Schedule Thursday fasting notification
    await scheduleFastingNotification(
      dayName: 'Thursday',
      dayNameArabic: 'الخميس',
      notificationTime: notificationTime,
      enabled: thursdayEnabled,
      vibration: vibration,
    );

    debugPrint('✅ All fasting notifications scheduled successfully');
    debugPrint('🍽️ ═══════════════════════════════════════════════════\n');
  }
}
