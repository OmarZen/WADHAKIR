import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

/// Schedules the daily "Verse/Dua of the Day" notification.
///
/// Mirrors [WirdNotificationService]: a singleton with an idempotent
/// [initialize] that registers the channel via `setChannel(forceUpdate:false)`
/// (never `AwesomeNotifications().initialize`, which would wipe other services'
/// channels). The channel is ALSO registered in the eager
/// `_MobileNotificationRepositoryImpl.initialize()` so a cold start that runs
/// that first does not drop this channel.
///
/// Because `NotificationCalendar(repeats:true)` keeps the same body every day,
/// callers re-schedule with today's body at cold start and on resume/day-change.
class DailyInspirationNotificationService {
  static final DailyInspirationNotificationService _instance =
      DailyInspirationNotificationService._internal();

  factory DailyInspirationNotificationService() => _instance;

  DailyInspirationNotificationService._internal();

  // Must match `_MobileNotificationRepositoryImpl._channelKeyDailyInspiration`.
  static const String channelKey = 'daily_inspiration_channel';
  static const String _channelName = 'Daily Inspiration';
  static const String _channelDescription =
      'Daily ayah / dua / hadith reminder';

  // Fresh id range (prayers 100-104, persistent 999, fasting 5xxx, wird 60xx).
  static const int _reminderId = 7000;
  static const int _testId = 7099;

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

  Future<void> initialize() async {
    if (_initialized) return;
    _localTimeZone = await _resolveTimeZone();
    try {
      await AwesomeNotifications().setChannel(
        NotificationChannel(
          channelKey: channelKey,
          channelName: _channelName,
          channelDescription: _channelDescription,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      );
    } catch (e) {
      log(
        '🟡 DailyInspirationNotificationService.initialize: setChannel failed '
        '(channel likely already registered): $e',
      );
    } finally {
      _initialized = true;
    }
  }

  /// (Re)schedule the daily notification with today's [body]. Cancels first;
  /// schedules a daily-repeating notification only when [enabled].
  Future<void> scheduleDaily({
    required bool enabled,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await initialize();
    await cancel();
    if (!enabled) return;

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _reminderId,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          autoDismissible: true,
          payload: const {'type': 'daily_inspiration'},
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
        '🟢 DailyInspirationNotificationService: scheduled daily at $hour:$minute',
      );
    } catch (e) {
      log('🟥 DailyInspirationNotificationService.scheduleDaily error: $e');
    }
  }

  Future<void> cancel() async {
    try {
      await AwesomeNotifications().cancelNotificationsByChannelKey(channelKey);
    } catch (_) {}
    try {
      await AwesomeNotifications().cancelSchedulesByChannelKey(channelKey);
    } catch (_) {}
  }

  /// Fire a test notification now so the channel/permission flow can be checked.
  Future<bool> sendTestNotification({
    required String title,
    required String body,
  }) async {
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
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
        ),
      );
      return true;
    } catch (e) {
      log('sendTestNotification (daily inspiration) error: $e');
      return false;
    }
  }
}
