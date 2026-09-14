import 'dart:developer';
import 'dart:io' show Platform;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:wadhakir/core/notifications/reminder_interruption.dart';

/// The floor beneath every other reminder: a dead man's switch.
///
/// Every reminder this app schedules has an expiry. The prayer plan covers five
/// days on iOS, the fasting plan runs to the end of the Hijri month, and the
/// repeating ones only survive as long as the OS keeps them. A user who stops
/// opening the app eventually falls off the end of all of them and the app goes
/// **completely silent** — which, from the outside, is indistinguishable from an
/// app that is broken. On Android that also covers the OEM task-killer case
/// (see the probed autostart deep-links), where the alarm chain is torn down by
/// the vendor rather than by anything this app did.
///
/// So one notification is armed [_silenceDays] days out and **pushed forward
/// again on every resume**. A user who opens the app even once a week never
/// sees it — the fuse is reset long before it burns down. A user who vanishes
/// gets exactly one calm message telling them the app needs opening.
///
/// Deliberately NOT a weekly repeater. A repeater is the stronger guarantee and
/// is what the plan first asked for, but it reaches everyone forever, including
/// the overwhelming majority whose reminders are working perfectly — an
/// unconditional nag to solve a conditional problem. This costs one slot of
/// [IosNotificationBudget.floor] and, for a healthy user, fires zero times.
///
/// The trade it accepts: if it fires and the user still does not open the app,
/// there is no second attempt. That is the right failure — a person who ignored
/// the one message does not need it repeated weekly.
class ReminderFloorService {
  ReminderFloorService._();

  static final ReminderFloorService instance = ReminderFloorService._();

  /// Clear of every other range in the app — prayers 100-694, location 900,
  /// diagnostic 998, persistent 999, fasting 5001-5999, wird 6001/6099,
  /// azkar 7100+, app-lock 8011, floating dhikr 9011.
  static const int notificationId = 9500;

  static const String channelKey = 'reminder_floor_channel';

  /// How long the app may stay unopened before the floor speaks.
  ///
  /// Wider than the five-day iOS prayer horizon on purpose: firing at five days
  /// would reach people whose reminders had not actually stopped yet. Ten days
  /// means anything that hears from it has genuinely run dry.
  static const Duration _silence = Duration(days: 10);

  /// The hour of day the floor is allowed to speak at, 24h local.
  ///
  /// The fuse length is measured in days, but the CLOCK TIME is pinned here
  /// rather than inherited from `DateTime.now()`. Inheriting it was the
  /// original bug, and in this app of all apps: the most common late-night
  /// foreground is someone checking Fajr at 04:20, or Isha at 23:50. Ten days
  /// later that is exactly when a channel with `playSound: true` would have
  /// gone off — on iOS with no Doze and no deferral to soften it.
  ///
  /// Every other reminder in this app fires at a time the user chose or a time
  /// derived from a prayer. This one is the app's own idea, so it gets the
  /// politest hour available: mid-morning, long after Fajr and well before the
  /// afternoon. The exact hour matters less than it never being 4 a.m.
  static const int _politeHour = 10;

  /// When a fuse lit at [now] should burn down to.
  ///
  /// Pure and visible for testing, because the thing that went wrong here was
  /// not reachable by any device test: the original took `now.add(_silence)`
  /// wholesale and so inherited the MINUTE the user last opened the app.
  ///
  /// Returns [_silence] days later at [_politeHour] sharp. Deliberately not
  /// "10 days later, rounded" — a user who opens the app at 23:50 has their
  /// fuse land on the morning of day 11 rather than 10, and that is correct:
  /// the alternative is waking them at 10:00 on day 10 after only 9 days and
  /// 10 minutes of silence, or firing before the fuse is spent.
  @visibleForTesting
  static DateTime fireTimeFrom(DateTime now) {
    final due = now.add(_silence);
    final atPoliteHour = DateTime(due.year, due.month, due.day, _politeHour);
    return atPoliteHour.isAfter(due)
        ? atPoliteHour
        : atPoliteHour.add(const Duration(days: 1));
  }

  /// The zone every other scheduler in this app resolves explicitly.
  ///
  /// Mirrors `FastingNotificationService._resolveTimeZone`: ask the plugin, and
  /// fall back to a fixed `Etc/GMT` offset rather than letting it read
  /// `TimeZone.getDefault()` itself.
  Future<String> _resolveTimeZone() async {
    try {
      final tz = await AwesomeNotifications().getLocalTimeZoneIdentifier();
      if (tz.isNotEmpty) return tz;
    } catch (_) {}
    final hours = DateTime.now().timeZoneOffset.inHours;
    return hours == 0 ? 'UTC' : 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
  }

  /// (Re)arm the switch: cancel any pending one and set a fresh fuse.
  ///
  /// Safe to call on every resume — it is one cancel plus one create, and
  /// creating over the same id replaces rather than duplicates.
  Future<void> arm() async {
    try {
      final fireAt = fireTimeFrom(DateTime.now());
      await AwesomeNotifications().cancelSchedule(notificationId);
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: channelKey,
          title: 'تحديث مواقيت الصلاة',
          body:
              'مرّت فترة دون فتح التطبيق. افتحه لتحديث المواقيت '
              'والتذكيرات حتى تصلك في وقتها.',
          category: NotificationCategory.Reminder,
          // Never Time-Sensitive: this is the least urgent thing the app says.
          wakeUpScreen: reminderWakeUpScreen(isIOS: Platform.isIOS),
          autoDismissible: true,
          payload: const {'type': 'reminder_floor'},
        ),
        schedule: NotificationCalendar(
          year: fireAt.year,
          month: fireAt.month,
          day: fireAt.day,
          hour: fireAt.hour,
          minute: fireAt.minute,
          second: 0,
          // Every other NotificationCalendar in this app passes an explicitly
          // resolved zone, because some OEM Android builds NPE when the plugin
          // reads TimeZone.getDefault() on the Java side. This one was the only
          // exception; it is not any more.
          timeZone: await _resolveTimeZone(),
          // Not repeating — see the class docs. The fuse is reset by arm(),
          // not by the OS.
          repeats: false,
          // Deliberately NOT allowWhileIdle: a safety net that is a few hours
          // late has lost nothing, and this is the one notification in the app
          // with no claim on a doze exemption.
          allowWhileIdle: false,
        ),
      );
    } catch (e) {
      // Never let the safety net take the app down with it.
      log('🔕 ReminderFloorService.arm failed: $e');
    }
  }

  /// Disarm entirely — used when the user turns all reminders off.
  Future<void> disarm() async {
    try {
      await AwesomeNotifications().cancelSchedule(notificationId);
    } catch (e) {
      log('🔕 ReminderFloorService.disarm failed: $e');
    }
  }

  /// The channel, mirrored into `notification_repository_impl`'s channel list
  /// because `initialize()` REPLACES the whole set — a channel declared only
  /// here would be wiped at the next cold start and the floor silently dropped
  /// for having no channel to post to.
  static NotificationChannel channel() => NotificationChannel(
    channelKey: channelKey,
    channelName: 'تنبيه عند توقف التذكيرات',
    channelDescription:
        'رسالة واحدة هادئة إذا مرّت أيام دون فتح التطبيق وتوقفت التذكيرات',
    importance: NotificationImportance.Default,
    defaultColor: const Color(0xFF20497D),
    ledColor: const Color(0xFF20497D),
    playSound: true,
    enableVibration: true,
    channelShowBadge: false,
    locked: false,
    onlyAlertOnce: true,
    icon: 'resource://drawable/ic_notification',
  );
}
