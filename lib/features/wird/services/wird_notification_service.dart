import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:wadhakir/data/models/wird/wird_plan_model.dart';

/// Schedules the daily Quran-wird reminder notification.
///
/// Mirrors FastingNotificationService: a singleton with an idempotent
/// [initialize] that registers the channel via `setChannel(forceUpdate:false)`
/// (never `AwesomeNotifications().initialize`, which would wipe the other
/// channels registered by the prayer/fasting services).
class WirdNotificationService {
  static final WirdNotificationService _instance =
      WirdNotificationService._internal();

  factory WirdNotificationService() => _instance;

  WirdNotificationService._internal();

  static const String _channelKey = 'wird_reminders_channel';
  static const String _channelName = 'Wird Reminders';
  static const String _channelDescription =
      'Daily Quran reading (wird) reminder';

  // Single fixed id — outside the fasting 5xxx range.
  static const int _reminderId = 6001;
  static const int _testId = 6099;

  // Pre-resolved IANA timezone — some OEM Android builds NPE if the plugin
  // resolves the device timezone itself. See FastingNotificationService.
  String _localTimeZone = 'UTC';
  bool _initialized = false;

  Future<String> _resolveTimeZone() async {
    try {
      final tz = await AwesomeNotifications().getLocalTimeZoneIdentifier();
      if (tz.isNotEmpty) return tz;
    } catch (_) {}
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;
    return hours == 0 ? 'UTC' : 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
  }

  /// Idempotent channel registration. Swallows the "channel already exists"
  /// error from setChannel — see FastingNotificationService for the rationale.
  Future<void> initialize() async {
    if (_initialized) return;
    _localTimeZone = await _resolveTimeZone();
    try {
      await AwesomeNotifications().setChannel(
        NotificationChannel(
          channelKey: _channelKey,
          channelName: _channelName,
          channelDescription: _channelDescription,
          defaultColor: const Color(0xFF26A69A),
          ledColor: const Color(0xFF26A69A),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      );
    } catch (e) {
      log(
        '🟡 WirdNotificationService.initialize: setChannel failed '
        '(channel likely already registered): $e',
      );
    } finally {
      _initialized = true;
    }
  }

  /// (Re)schedule the daily reminder based on [plan]. Cancels the existing
  /// reminder first, then schedules a daily-repeating notification when the
  /// plan is active and the reminder is enabled.
  Future<void> scheduleDailyReminder(WirdPlanModel plan) async {
    await initialize();
    await cancel();

    if (!plan.isActive || !plan.reminderEnabled) {
      log(
        '🟢 WirdNotificationService: plan inactive or reminder off — not scheduling',
      );
      return;
    }

    final parts = plan.reminderTime.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _reminderId,
          channelKey: _channelKey,
          title: 'ورد القرآن اليومي',
          body: 'حان وقت وردك اليومي من القرآن الكريم',
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          autoDismissible: true,
          payload: const {'type': 'wird_reminder'},
        ),
        schedule: NotificationCalendar(
          hour: hour,
          minute: minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          timeZone: _localTimeZone,
        ),
      );
      log(
        '🟢 WirdNotificationService: scheduled daily reminder at $hour:$minute',
      );
    } catch (e) {
      log('🟥 WirdNotificationService.scheduleDailyReminder error: $e');
    }
  }

  /// Cancel the wird reminder (notification + schedule).
  Future<void> cancel() async {
    try {
      await AwesomeNotifications().cancelNotificationsByChannelKey(_channelKey);
    } catch (_) {}
    try {
      await AwesomeNotifications().cancelSchedulesByChannelKey(_channelKey);
    } catch (_) {}
  }

  /// Fire a test reminder now (id 6099) so the channel/permission flow can be
  /// verified without waiting for the scheduled time.
  Future<bool> sendTestNotification() async {
    try {
      await initialize();
      final allowed = await AwesomeNotifications().isNotificationAllowed();
      if (!allowed) {
        final granted = await AwesomeNotifications()
            .requestPermissionToSendNotifications();
        if (!granted) return false;
      }
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _testId,
          channelKey: _channelKey,
          title: 'اختبار تذكير الورد',
          body: 'هذا تنبيه تجريبي لتذكير ورد القرآن.',
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
        ),
      );
      return true;
    } catch (e) {
      log('sendTestNotification (wird) error: $e');
      return false;
    }
  }
}
