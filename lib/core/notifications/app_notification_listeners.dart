import 'dart:developer';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:wadhakir/core/notifications/pending_notification_action.dart';

/// The single `awesome_notifications` listener registration site for the whole
/// app. `setListeners` only honours ONE set of handlers (last caller wins), so
/// these live here and are registered once from `main()` — never from a feature
/// service, which would silently steal the handlers.
///
/// The handlers are static, top-level `@pragma('vm:entry-point')` callbacks:
/// they may run in a context-less isolate, so they must not touch a
/// `BuildContext`. Navigation is bridged through [PendingNotificationAction].
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

  /// A notification was tapped (or an action button pressed). Hand the payload
  /// to the router via the pending holder.
  @pragma('vm:entry-point')
  static Future<void> onActionReceived(ReceivedAction receivedAction) async {
    log('Notification action received: ${receivedAction.actionType}');
    PendingNotificationAction.capture(receivedAction.payload);
  }

  @pragma('vm:entry-point')
  static Future<void> onCreated(ReceivedNotification received) async {
    log('Notification created: ${received.id}');
  }

  /// A notification was displayed.
  ///
  /// There is deliberately no adhan playback here: the sound is owned by the
  /// NOTIFICATION on both platforms.
  ///  * Android bakes the full mp3 into the per-adhan channel, so the OS plays
  ///    it even when the app is dead (see NotificationRepository).
  ///  * iOS plays the bundled ≤30s .aiff via `customSound`, in every lifecycle
  ///    including the foreground — AwnCore's `willPresent` returns
  ///    [.alert, .badge, .sound] (AwesomeNotifications.swift:632).
  ///
  /// An in-app player was tried here for the FULL adhan on iOS foreground, but
  /// it plays *on top of* the .aiff rather than instead of it: the plugin
  /// exposes no way to suppress the notification sound alone (`playSound:false`
  /// kills it when backgrounded too, and `displayOnForeground:false` also
  /// suppresses the banner and its STOP button). iOS foreground therefore caps
  /// at the 29s clip — a deliberate trade for a consistent, interruptible alert.
  @pragma('vm:entry-point')
  static Future<void> onDisplayed(ReceivedNotification received) async {
    log('Notification displayed: ${received.id}');
  }

  /// A notification was dismissed (including via the STOP_ADHAN button).
  ///
  /// Stopping the sound needs no Dart work: the plugin's native dismiss path
  /// cancels the notification (Android `NotificationActionReceiver` →
  /// `StatusBarManager.dismissNotification` → `NotificationManager.cancel`),
  /// and cancelling the notification that owns the in-flight channel sound
  /// stops that sound.
  @pragma('vm:entry-point')
  static Future<void> onDismiss(ReceivedAction receivedAction) async {
    log('Notification dismissed: ${receivedAction.id}');
  }
}
