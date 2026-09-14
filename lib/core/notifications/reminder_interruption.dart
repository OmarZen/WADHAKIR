/// Who is allowed to interrupt a Focus mode on iOS.
///
/// iOS 15 grades every notification by `UNNotificationInterruptionLevel`, and
/// `timeSensitive` is the one that breaks through Focus and Do Not Disturb.
/// awesome_notifications does not expose that level directly — it derives it,
/// in `NotificationBuilder.swift`, from two things this app controls:
///
///   * `setImportance` maps a channel importance of **High or Max** to
///     `.timeSensitive` (Default maps to `.active`, Low/Min to `.passive`); and
///   * `setWakeUpScreen` then forces `.timeSensitive` for **any** notification
///     with `wakeUpScreen: true`, whatever the importance said — it runs last.
///
/// Before R3 every reminder in the app tripped both: azkar, wird, fasting and
/// the daily inspiration all shipped `High` channels and `wakeUpScreen: true`.
/// So a fasting advance notice nine days out interrupted a Focus session with
/// exactly the same authority as the adhan. That is both the "scorekeeper"
/// posture PRODUCT.md refuses and a real App Review risk: Apple expects
/// Time-Sensitive to be reserved for things that genuinely cannot wait.
///
/// The adhan can genuinely not wait, and keeps it. Nothing else does.
///
/// **Both helpers are Android no-ops.** `isIOS: false` returns exactly the
/// values these services used before, so Android keeps its heads-up banner and
/// its screen wake. The narrowing is iOS-only and behaviour-preserving
/// elsewhere — which is what makes it safe to apply in one sweep.
library;

import 'package:awesome_notifications/awesome_notifications.dart';

/// The channel importance for a reminder that is **not** one of the five
/// prayers.
///
/// Android: `High`, unchanged — IMPORTANCE_HIGH is what makes a reminder peek
/// as a heads-up banner, and losing that would be a visible regression for a
/// feature the user deliberately switched on.
///
/// iOS: `Default`, so the plugin resolves `.active` rather than
/// `.timeSensitive`. Channels are a plugin-side fiction on iOS — they exist to
/// carry settings like this one — so lowering it there costs nothing else.
NotificationImportance reminderChannelImportance({required bool isIOS}) =>
    isIOS ? NotificationImportance.Default : NotificationImportance.High;

/// Whether a non-prayer reminder should ask to wake the screen.
///
/// Android: `true`, unchanged — it does what it says, and a reminder that
/// lights the screen is the point.
///
/// iOS: `false`. There it does not wake anything; it only reaches
/// `setWakeUpScreen`, whose sole effect is to stamp `.timeSensitive` on the
/// notification. Leaving it true would quietly undo
/// [reminderChannelImportance], because that method runs after `setImportance`
/// and overwrites it.
bool reminderWakeUpScreen({required bool isIOS}) => !isIOS;
