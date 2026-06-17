import 'dart:developer';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:wadhakir/core/notifications/pending_notification_action.dart';
import 'package:wadhakir/features/pray_times/services/adhan_player_service.dart';

/// The single `awesome_notifications` listener registration site for the whole
/// app. `setListeners` only honours ONE set of handlers (last caller wins), so
/// these live here and are registered once from `main()` — never from a feature
/// service, which would silently steal the handlers.
///
/// The handlers are static, top-level `@pragma('vm:entry-point')` callbacks:
/// they may run in a context-less isolate, so they must not touch a
/// `BuildContext`. Navigation is bridged through [PendingNotificationAction];
/// adhan playback is handled inline (no UI needed).
class AppNotificationListeners {
  AppNotificationListeners._();

  static void register() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceived,
      onNotificationCreatedMethod: onCreated,
      onNotificationDisplayedMethod: onDisplayed,
      onDismissActionReceivedMethod: onDismiss,
    );
  }

  /// A notification was tapped (or an action button pressed). Stop any adhan
  /// playback and hand the payload to the router via the pending holder.
  @pragma('vm:entry-point')
  static Future<void> onActionReceived(ReceivedAction receivedAction) async {
    log('Notification action received: ${receivedAction.actionType}');
    AdhanPlayerService().stopAdhan();
    PendingNotificationAction.capture(receivedAction.payload);
  }

  @pragma('vm:entry-point')
  static Future<void> onCreated(ReceivedNotification received) async {
    log('Notification created: ${received.id}');
  }

  /// A notification was displayed. For prayer notifications configured with a
  /// custom adhan, play it (the channel itself is silent in that mode).
  @pragma('vm:entry-point')
  static Future<void> onDisplayed(ReceivedNotification received) async {
    log('Notification displayed: ${received.id}');

    final soundPath = received.payload?['soundPath'];
    final useCustomAdhan = received.payload?['useCustomAdhan'] == 'true';
    final prayerName = received.payload?['prayer'];

    if (useCustomAdhan && soundPath != null && soundPath.isNotEmpty) {
      log('Playing custom adhan for $prayerName');
      AdhanPlayerService().playAdhan(
        soundPath: soundPath,
        onComplete: () => log('Adhan playback completed for $prayerName'),
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onDismiss(ReceivedAction receivedAction) async {
    log('Notification dismissed: ${receivedAction.id}');
    AdhanPlayerService().stopAdhan();
  }
}
