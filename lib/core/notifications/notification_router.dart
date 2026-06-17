import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/routes/app_router.dart';
import 'package:wadhakir/core/notifications/pending_notification_action.dart';
import 'package:wadhakir/features/fasting_reminders/cubit/fasting_reminders_cubit.dart';
import 'package:wadhakir/features/fasting_reminders/views/screens/fasting_calendar_screen.dart';

/// Central dispatcher that turns a tapped notification's payload into in-app
/// navigation, using the root [AppRouter.navigatorKey].
///
/// Every scheduled notification carries a `payload['type']`. Feature-discovery
/// nudges carry `type: 'feature_nudge'` plus a `target` pointing at the feature
/// they advertise — those defer to the same switch via [target].
class NotificationRouter {
  NotificationRouter._();

  /// Consume any payload captured before the navigator was ready (cold start).
  /// Called by the splash right after it pushes the home shell.
  static void consumePending() {
    final payload = PendingNotificationAction.consume();
    if (payload != null) dispatch(payload);
  }

  /// Navigate to the screen that corresponds to a tapped notification.
  static void dispatch(Map<String, String?> payload) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      // Navigator not mounted yet (still on splash). Re-queue; the splash
      // consumes it once the shell is pushed.
      PendingNotificationAction.capture(payload);
      return;
    }

    var type = payload['type'];
    // Feature-discovery nudges advertise another feature — route to it.
    if (type == 'feature_nudge') {
      type = payload['target'];
    }

    switch (type) {
      // ── Existing reminders ────────────────────────────────────────────
      case 'wird_reminder':
      case 'open_wird':
        navigator.pushNamed(AppConstants.wirdRoute);
        break;
      case 'prayer':
      case 'azkar_qiyam':
      case 'azkar_witr':
      case 'azkar_duha':
        navigator.pushNamed(AppConstants.prayerTimesRoute);
        break;
      case 'daily_inspiration':
      case 'open_daily_inspiration':
        navigator.pushNamed(AppConstants.dailyInspirationSettingsRoute);
        break;
      case 'fasting_reminder':
      case 'weekly_fasting':
      case 'open_fasting':
        _openFastingCalendar(navigator);
        break;

      // ── New azkar reminders ───────────────────────────────────────────
      case 'azkar_morning':
      case 'azkar_evening':
        navigator.pushNamed(
          AppConstants.azkarCategoryDetailsRoute,
          arguments: AppConstants.azkarMorningEveningCategory,
        );
        break;
      case 'azkar_sleep':
        navigator.pushNamed(
          AppConstants.azkarCategoryDetailsRoute,
          arguments: AppConstants.azkarSleepCategory,
        );
        break;
      case 'azkar_after_prayer':
        navigator.pushNamed(AppConstants.afterPrayerAdhkarRoute);
        break;
      case 'azkar_kahf':
        navigator.pushNamed(AppConstants.quranRoute);
        break;
      case 'open_azkar_reminders':
        navigator.pushNamed(AppConstants.azkarRemindersSettingsRoute);
        break;

      // ── Feature-discovery nudge destinations ──────────────────────────
      case 'open_zakat':
        navigator.pushNamed(AppConstants.zakatRoute);
        break;
      case 'open_backgrounds':
        navigator.pushNamed(AppConstants.islamicBackgroundsRoute);
        break;
      case 'open_prayer_settings':
        navigator.pushNamed(AppConstants.settingsRoute);
        break;

      default:
        // Unknown type — leave the user on the home shell.
        break;
    }
  }

  /// The fasting calendar is a dialog (not a route). [FastingRemindersCubit] is
  /// a top-level eager provider, so it resolves from the navigator's context.
  static void _openFastingCalendar(NavigatorState navigator) {
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<FastingRemindersCubit>(),
        child: const FastingCalendarScreen(),
      ),
    );
  }
}
