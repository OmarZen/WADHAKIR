import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:wadhakir/data/models/azkar_reminder_settings_model.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';

/// Schedules the daily azkar reminders.
///
/// Mirrors [WirdNotificationService]: a singleton with an idempotent
/// [initialize] that registers the channel via `setChannel` (never
/// `AwesomeNotifications().initialize`, which would wipe the other services'
/// channels). The channel is ALSO registered centrally in
/// `_MobileNotificationRepositoryImpl.initialize()`.
///
/// Two scheduling entry points keep the two reminder families separate so they
/// never fight over notification IDs:
///   - [applyRepeating]      — morning, evening, witr, sleep, Friday Al-Kahf,
///                             and fixed-mode Qiyam (daily/weekly repeating).
///   - [applyPrayerDriven]   — after-each-prayer, Duha, and last-third Qiyam
///                             (one-shots derived from the day's prayer times).
class AzkarNotificationService {
  static final AzkarNotificationService _instance =
      AzkarNotificationService._internal();

  factory AzkarNotificationService() => _instance;

  AzkarNotificationService._internal();

  // Must match `_MobileNotificationRepositoryImpl._channelKeyAzkar`.
  static const String channelKey = 'azkar_reminders_channel';
  static const String _channelName = 'تذكير الأذكار';
  static const String _channelDescription =
      'تذكيرات الأذكار اليومية (الصباح، المساء، بعد الصلاة، قيام الليل)';

  // ID range 7100-7199 (daily inspiration uses 7000/7099, nudges use 7200+).
  static const int _morningId = 7100;
  static const int _eveningId = 7101;
  static const int _qiyamFixedId = 7110; // owned by applyRepeating
  static const int _qiyamLastThirdId = 7111; // owned by applyPrayerDriven
  static const int _afterFajrId = 7120;
  static const int _afterDhuhrId = 7121;
  static const int _afterAsrId = 7122;
  static const int _afterMaghribId = 7123;
  static const int _afterIshaId = 7124;
  static const int _fridayKahfId = 7130;
  static const int _witrId = 7131;
  static const int _duhaId = 7132;
  static const int _sleepId = 7133;
  static const int _testId = 7199;

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
        '🟡 AzkarNotificationService.initialize: setChannel failed '
        '(channel likely already registered): $e',
      );
    } finally {
      _initialized = true;
    }
  }

  /// (Re)schedule the repeating reminders. Cancels their specific IDs first so a
  /// disabled reminder is cleared. Skips scheduling (but still cancels) when the
  /// user hasn't granted notification permission — never prompts here.
  Future<void> applyRepeating(AzkarReminderSettingsModel s) async {
    await initialize();
    await _cancel([
      _morningId,
      _eveningId,
      _qiyamFixedId,
      _fridayKahfId,
      _witrId,
      _sleepId,
    ]);

    if (!await AwesomeNotifications().isNotificationAllowed()) return;

    if (s.morningEnabled) {
      await _scheduleDaily(
        id: _morningId,
        hour: s.morningHour,
        minute: s.morningMinute,
        title: 'أذكار الصباح',
        body: 'ابدأ يومك بذكر الله — حان وقت أذكار الصباح',
        type: 'azkar_morning',
      );
    }
    if (s.eveningEnabled) {
      await _scheduleDaily(
        id: _eveningId,
        hour: s.eveningHour,
        minute: s.eveningMinute,
        title: 'أذكار المساء',
        body: 'اختم يومك بذكر الله — حان وقت أذكار المساء',
        type: 'azkar_evening',
      );
    }
    if (s.witrEnabled) {
      await _scheduleDaily(
        id: _witrId,
        hour: s.witrHour,
        minute: s.witrMinute,
        title: 'صلاة الوتر',
        body: 'لا تنم حتى توتر — صلِّ ركعة الوتر',
        type: 'azkar_witr',
      );
    }
    if (s.sleepEnabled) {
      await _scheduleDaily(
        id: _sleepId,
        hour: s.sleepHour,
        minute: s.sleepMinute,
        title: 'أذكار النوم',
        body: 'اقرأ أذكار النوم قبل أن تنام',
        type: 'azkar_sleep',
      );
    }
    if (s.fridayKahfEnabled) {
      await _scheduleWeekly(
        id: _fridayKahfId,
        weekday: DateTime.friday,
        hour: s.fridayKahfHour,
        minute: s.fridayKahfMinute,
        title: 'سورة الكهف',
        body: 'يوم الجمعة: اقرأ سورة الكهف وأكثر من الصلاة على النبي ﷺ',
        type: 'azkar_kahf',
      );
    }
    if (s.qiyamEnabled && s.qiyamMode == QiyamMode.fixed) {
      await _scheduleDaily(
        id: _qiyamFixedId,
        hour: s.qiyamHour,
        minute: s.qiyamMinute,
        title: 'قيام الليل',
        body: 'قُم وتهجّد — هذا وقت إجابة الدعاء',
        type: 'azkar_qiyam',
      );
    }
  }

  /// (Re)schedule the prayer-time-driven reminders for [today]. Called from the
  /// prayer-times cubit on every load/refresh/midnight rollover so the times
  /// always match the freshly computed prayer times.
  Future<void> applyPrayerDriven(
    AzkarReminderSettingsModel s,
    PrayerTimesModel today,
  ) async {
    await initialize();
    await _cancel([
      _afterFajrId,
      _afterDhuhrId,
      _afterAsrId,
      _afterMaghribId,
      _afterIshaId,
      _duhaId,
      _qiyamLastThirdId,
    ]);

    if (!await AwesomeNotifications().isNotificationAllowed()) return;

    if (s.afterPrayerEnabled) {
      final delay = Duration(minutes: s.afterPrayerDelayMinutes);
      const title = 'أذكار بعد الصلاة';
      const body = 'لا تنسَ أذكار ما بعد الصلاة';
      await _scheduleOneShot(
        id: _afterFajrId,
        when: today.fajr.add(delay),
        title: title,
        body: body,
        type: 'azkar_after_prayer',
        extra: const {'prayer': 'Fajr'},
      );
      await _scheduleOneShot(
        id: _afterDhuhrId,
        when: today.dhuhr.add(delay),
        title: title,
        body: body,
        type: 'azkar_after_prayer',
        extra: const {'prayer': 'Dhuhr'},
      );
      await _scheduleOneShot(
        id: _afterAsrId,
        when: today.asr.add(delay),
        title: title,
        body: body,
        type: 'azkar_after_prayer',
        extra: const {'prayer': 'Asr'},
      );
      await _scheduleOneShot(
        id: _afterMaghribId,
        when: today.maghrib.add(delay),
        title: title,
        body: body,
        type: 'azkar_after_prayer',
        extra: const {'prayer': 'Maghrib'},
      );
      await _scheduleOneShot(
        id: _afterIshaId,
        when: today.isha.add(delay),
        title: title,
        body: body,
        type: 'azkar_after_prayer',
        extra: const {'prayer': 'Isha'},
      );
    }

    if (s.duhaEnabled) {
      await _scheduleOneShot(
        id: _duhaId,
        when: today.sunrise.add(Duration(minutes: s.duhaOffsetMinutes)),
        title: 'صلاة الضحى',
        body: 'حان وقت صلاة الضحى — صلِّ ركعتين',
        type: 'azkar_duha',
      );
    }

    if (s.qiyamEnabled && s.qiyamMode == QiyamMode.lastThird) {
      await _scheduleOneShot(
        id: _qiyamLastThirdId,
        when: today.lastThirdOfTheNight,
        title: 'قيام الليل',
        body: 'دخل الثلث الأخير من الليل — قُم وتهجّد',
        type: 'azkar_qiyam',
      );
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          autoDismissible: true,
          payload: {'type': type},
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
    } catch (e) {
      log('🟥 AzkarNotificationService._scheduleDaily($type) error: $e');
    }
  }

  Future<void> _scheduleWeekly({
    required int id,
    required int weekday, // Dart weekday (Mon=1..Sun=7)
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String type,
  }) async {
    // awesome_notifications uses a different weekday convention; this mapping
    // matches FastingNotificationService._scheduleWeeklyFastingDay.
    final awesomeWeekday = weekday == DateTime.monday ? 7 : weekday - 1;
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          autoDismissible: true,
          payload: {'type': type},
        ),
        schedule: NotificationCalendar(
          weekday: awesomeWeekday,
          hour: hour,
          minute: minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          timeZone: _localTimeZone,
        ),
      );
    } catch (e) {
      log('🟥 AzkarNotificationService._scheduleWeekly($type) error: $e');
    }
  }

  Future<void> _scheduleOneShot({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String type,
    Map<String, String?> extra = const {},
  }) async {
    if (when.isBefore(DateTime.now())) return; // already passed today
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          autoDismissible: true,
          payload: {'type': type, ...extra},
        ),
        schedule: NotificationCalendar(
          year: when.year,
          month: when.month,
          day: when.day,
          hour: when.hour,
          minute: when.minute,
          second: 0,
          timeZone: _localTimeZone,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
    } catch (e) {
      log('🟥 AzkarNotificationService._scheduleOneShot($type) error: $e');
    }
  }

  Future<void> _cancel(List<int> ids) async {
    for (final id in ids) {
      try {
        await AwesomeNotifications().cancel(id);
      } catch (_) {}
    }
  }

  /// Cancel every azkar reminder (e.g. for a full reset).
  Future<void> cancelAll() async {
    try {
      await AwesomeNotifications().cancelNotificationsByChannelKey(channelKey);
    } catch (_) {}
    try {
      await AwesomeNotifications().cancelSchedulesByChannelKey(channelKey);
    } catch (_) {}
  }

  /// Fire a test reminder now so the channel/permission flow can be verified.
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
          channelKey: channelKey,
          title: 'اختبار تذكير الأذكار',
          body: 'هذا تنبيه تجريبي لتذكيرات الأذكار.',
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
        ),
      );
      return true;
    } catch (e) {
      log('sendTestNotification (azkar) error: $e');
      return false;
    }
  }
}
