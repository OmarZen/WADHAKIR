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
///    `AwesomeNotifications().getInitialNotificationAction(...)`, then the splash
///    calls [consume] right after it pushes the home shell — so the navigator
///    exists before we route.
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

  /// Take and clear the pending payload (null if none).
  static Map<String, String?>? consume() {
    final p = _pending;
    _pending = null;
    return p;
  }

  static bool get hasPending => _pending != null;
}
