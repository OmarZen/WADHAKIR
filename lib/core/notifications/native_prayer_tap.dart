import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wadhakir/core/notifications/pending_notification_action.dart';
import 'package:wadhakir/features/pray_times/services/native_prayer_alarm_gateway.dart';

/// Collects a tap on an adhan notification that the native alarm path posted.
///
/// ## Why this is not the plugin's job
///
/// `awesome_notifications` reports taps on notifications *it* posted, through
/// `setListeners` and `getInitialNotificationAction`. The native alarm path
/// posts its own notification from a `BroadcastReceiver` with no Flutter engine
/// alive, so the plugin never sees it and neither of those fires. The tap
/// arrives as an ordinary activity intent instead.
///
/// Kotlin cannot hand it straight to Dart either: on a cold start the intent is
/// delivered long before the engine exists. So `MainActivity` parks the payload
/// in its own SharedPreferences and Dart collects it here — once at startup for
/// the cold case, and on every resume for the warm one.
///
/// Both paths end at [PendingNotificationAction], the same holder the plugin
/// path feeds, so routing stays in one place.
/// Whether the native side is holding a "this schedule is stale" flag.
///
/// Raised when Android reports a timezone change under an armed schedule. The
/// alarms deliberately keep firing — going silent on someone who has just
/// landed is the failure this release exists to prevent — but their instants
/// were computed for the previous city, and no broadcast receiver can fix that:
/// prayer times are geodetic as well as zone-dependent, `adhan_dart` runs in
/// Dart, and the cached location is now wrong.
///
/// So the native side marks the plan stale and tells the user once. This is how
/// the app finds out, on its next launch or resume, that it owes them a re-plan
/// against a fresh location.
class NativePrayerScheduleStale {
  NativePrayerScheduleStale._();

  /// Whether the native ledger is currently marked stale.
  ///
  /// A peek. Reading does NOT clear — see [clear].
  static Future<bool> isSet() async {
    if (!Platform.isAndroid) return false;

    try {
      return await MethodChannelAlarmBridge.channel.invokeMethod<bool>(
            'isLocationStale',
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('Could not read the stale-schedule flag: $e');
      return false;
    }
  }

  /// Clears the flag, and must only be called once the native ledger has
  /// actually been rewritten.
  ///
  /// Separate from [isSet] on purpose. Clearing on read would drop the flag the
  /// moment the app asks about it, while everything that answers it can still
  /// fail — no location fix available, or the reschedule listener skipping
  /// because settings had not finished loading. The user would then be left on
  /// the wrong city's prayer times with nothing left to tell anyone about it.
  /// Clearing here instead means a failure anywhere in between simply costs a
  /// retry on the next resume.
  static Future<void> clear() async {
    if (!Platform.isAndroid) return;

    try {
      await MethodChannelAlarmBridge.channel.invokeMethod<void>(
        'clearLocationStale',
      );
    } on MissingPluginException {
      // Nothing to clear.
    } on PlatformException catch (e) {
      debugPrint('Could not clear the stale-schedule flag: $e');
    }
  }
}

class NativePrayerTap {
  NativePrayerTap._();

  /// Takes the pending tap, if any, and hands it to the router.
  ///
  /// Safe to call when the native bridge is absent — iOS, Windows, or an
  /// Android build without the Kotlin side — and safe to call repeatedly: the
  /// native side clears the payload as it hands it over, so a second call in
  /// the same resume finds nothing.
  static Future<void> drain() async {
    if (!Platform.isAndroid) return;

    try {
      final payload = await MethodChannelAlarmBridge.channel
          .invokeMapMethod<String, String>('consumePendingTap');
      if (payload == null || payload.isEmpty) return;
      PendingNotificationAction.capture(payload);
    } on MissingPluginException {
      // A build without the native side. Nothing to collect.
    } on PlatformException catch (e) {
      debugPrint('Could not read a pending prayer tap: $e');
    }
  }
}
