import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/features/feature_discovery/models/feature_nudge.dart';
import 'package:wadhakir/features/feature_discovery/services/feature_discovery_catalog.dart';

/// Schedules low-key re-engagement nudges that surface app features the user
/// hasn't enabled yet. Capped to at most one nudge per [_cadence] window, and
/// rotates through eligible features without repeating.
///
/// Uses a rebuild-on-start/resume model (not a repeating notification) so the
/// content can rotate; the cadence cap makes both call sites idempotent.
class FeatureDiscoveryService {
  FeatureDiscoveryService._();
  static final FeatureDiscoveryService instance = FeatureDiscoveryService._();

  // Must match `_MobileNotificationRepositoryImpl._channelKeyFeatureNudge`.
  static const String channelKey = 'feature_nudge_channel';
  static const String _channelName = 'اكتشف ميزات التطبيق';
  static const String _channelDescription =
      'تذكير لطيف بميزات التطبيق التي لم تجرّبها بعد';

  static const int _nudgeId = 7200;
  static const int _testId = 7299;

  /// Research-backed: discovery/promotional nudges spaced ~3 days keep
  /// re-engagement without driving opt-outs.
  static const Duration _cadence = Duration(days: 3);

  /// The friendly hour of day to deliver a nudge (24h).
  static const int _deliveryHour = 19;

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
          importance: NotificationImportance.Default,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      );
    } catch (e) {
      log(
        '🟡 FeatureDiscoveryService.initialize: setChannel failed '
        '(channel likely already registered): $e',
      );
    } finally {
      _initialized = true;
    }
  }

  /// Schedule the next nudge if the cadence window has elapsed and there's an
  /// eligible, not-recently-shown feature. Safe to call on every app
  /// start/resume — it's a no-op until the window opens.
  Future<void> maybeScheduleNext(SharedPreferences prefs) async {
    try {
      if (!(prefs.getBool(AppConstants.featureNudgeEnabledKey) ?? true)) return;

      // Never prompt for permission here — nudges are low priority.
      if (!await AwesomeNotifications().isNotificationAllowed()) return;

      final now = DateTime.now();
      final lastMs = prefs.getInt(AppConstants.featureNudgeLastShownKey) ?? 0;
      if (now.millisecondsSinceEpoch - lastMs < _cadence.inMilliseconds) return;

      var shown = prefs.getStringList(AppConstants.featureNudgeShownIdsKey) ?? [];
      var eligible = FeatureDiscoveryCatalog.nudges
          .where((n) => n.isEligible(prefs) && !shown.contains(n.id))
          .toList();

      if (eligible.isEmpty) {
        // Either everything is adopted, or we've cycled through all eligible
        // ones. Reset the rotation; if nothing is eligible at all, stop.
        final stillEligible = FeatureDiscoveryCatalog.nudges
            .where((n) => n.isEligible(prefs))
            .toList();
        if (stillEligible.isEmpty) {
          await prefs.remove(AppConstants.featureNudgeShownIdsKey);
          return;
        }
        shown = [];
        await prefs.setStringList(AppConstants.featureNudgeShownIdsKey, shown);
        eligible = stillEligible;
      }

      final next = eligible.first;
      final when = _nextDeliveryTime(now);

      await initialize();
      await _schedule(next, when);

      await prefs.setInt(
        AppConstants.featureNudgeLastShownKey,
        now.millisecondsSinceEpoch,
      );
      await prefs.setStringList(AppConstants.featureNudgeShownIdsKey, [
        ...shown,
        next.id,
      ]);
      log('🟢 FeatureDiscoveryService: scheduled nudge "${next.id}" for $when');
    } catch (e) {
      log('🟥 FeatureDiscoveryService.maybeScheduleNext error: $e');
    }
  }

  DateTime _nextDeliveryTime(DateTime now) {
    final todayAtHour = DateTime(now.year, now.month, now.day, _deliveryHour);
    final base = now.hour < _deliveryHour
        ? todayAtHour
        : todayAtHour.add(const Duration(days: 1));
    return base;
  }

  Future<void> _schedule(FeatureNudge nudge, DateTime when) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _nudgeId,
          channelKey: channelKey,
          title: nudge.titleAr,
          body: nudge.bodyAr,
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Recommendation,
          wakeUpScreen: false,
          autoDismissible: true,
          payload: {'type': 'feature_nudge', 'target': nudge.target},
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
        ),
      );
    } catch (e) {
      log('🟥 FeatureDiscoveryService._schedule error: $e');
    }
  }

  /// Cancel any pending nudge (e.g. when the user turns the feature off).
  Future<void> cancel() async {
    try {
      await AwesomeNotifications().cancel(_nudgeId);
    } catch (_) {}
  }

  /// Mark the wallpaper/backgrounds feature as used so its nudge stops.
  static Future<void> markBackgroundUsed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.islamicBackgroundUsedKey, true);
    } catch (_) {}
  }

  /// Fire a test nudge now so the channel/permission flow can be verified.
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
          title: 'اكتشف ميزات التطبيق',
          body: 'هذا تنبيه تجريبي لاقتراحات الميزات.',
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Recommendation,
          payload: const {'type': 'feature_nudge', 'target': 'open_zakat'},
        ),
      );
      return true;
    } catch (e) {
      log('sendTestNotification (feature nudge) error: $e');
      return false;
    }
  }
}
