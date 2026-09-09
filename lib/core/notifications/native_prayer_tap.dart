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
