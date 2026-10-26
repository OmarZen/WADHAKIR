import 'package:flutter/foundation.dart';

/// Bridges a notification tap to in-app navigation.
///
/// The `awesome_notifications` tap handler is a static, `@pragma('vm:entry-point')`
/// callback that runs without a live `BuildContext`/`Navigator`, so it cannot
/// navigate directly. Instead it only records the tapped notification's payload
/// here. Two consumers read it:
///
///  - **Warm tap** (app already running): the app shell listens on [notifier]
///    and dispatches the payload through [NotificationRouter].
///  - **Cold start** (app launched from a killed state by the tap): `main()`
///    captures the launching action via
///    `AwesomeNotifications().getInitialNotificationAction(...)`, and the home
///    shell routes it on its first frame — the first moment there is a shell
///    to route from. A warm tap that lands while the splash or onboarding is
///    still up is [hold]-ed for the same hand-off.
class PendingNotificationAction {
  PendingNotificationAction._();

  static Map<String, String?>? _pending;

  /// Fires on a tap while the app is alive so the live shell can route it.
  static final ValueNotifier<Map<String, String?>?> notifier =
      ValueNotifier<Map<String, String?>?>(null);

  /// Record a tapped notification's payload. Safe to call from the static
  /// entry-point handler. A fresh map instance is stored each time so
  /// [notifier] always reports a change (even for an identical payload).
  static void capture(Map<String, String?>? payload) {
    if (payload == null || payload.isEmpty) return;
    final copy = Map<String, String?>.from(payload);
    _pending = copy;
    notifier.value = copy;
  }

  /// Keep a payload for the shell without notifying [notifier].
  ///
  /// For the router, when a tap arrives before the shell is mounted (splash,
  /// onboarding). Notifying would hand it straight back to the live listener,
  /// which would dispatch it again on the next frame — every frame — until
  /// the shell appeared. The shell consumes it on its first frame instead.
  static void hold(Map<String, String?> payload) {
    _pending = Map<String, String?>.from(payload);
  }

  /// Take and clear the pending payload (null if none).
  static Map<String, String?>? consume() {
    final p = _pending;
    _pending = null;
    return p;
  }

  static bool get hasPending => _pending != null;

  /// The pending payload without taking it — for the shell to start on the
  /// tab it will be routed to.
  static Map<String, String?>? peek() => _pending;
}
