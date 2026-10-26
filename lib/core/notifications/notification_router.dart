import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_library/quran_library.dart';
import 'package:wadhakir/core/app/restart_required.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/routes/app_router.dart';
import 'package:wadhakir/core/routes/app_shell.dart';
import 'package:wadhakir/core/notifications/pending_notification_action.dart';
import 'package:wadhakir/data/repositories/azkar_repository_impl.dart';
import 'package:wadhakir/features/azkar/views/screens/azkar_category_by_title_screen.dart';
import 'package:wadhakir/features/azkar/views/screens/azkar_category_details_screen.dart';
import 'package:wadhakir/features/fasting_reminders/cubit/fasting_reminders_cubit.dart';
import 'package:wadhakir/features/fasting_reminders/views/screens/fasting_calendar_screen.dart';

/// Where a tapped notification lands: a bottom-bar tab, and at most one screen
/// on top of it.
///
/// Decided from the payload alone, with no navigator, so the whole table can
/// be tested. The [tab] matters as much as the screen: it is where the first
/// back press lands, and Home is where the next one does before the app closes.
sealed class NotificationDestination {
  const NotificationDestination(this.tab);

  final AppTab tab;

  /// Every scheduled notification carries `payload['type']`. Feature-discovery
  /// nudges carry `type: 'feature_nudge'` plus the `target` they advertise.
  /// Null for a type nothing should open — the tap just brings the app up.
  static NotificationDestination? forPayload(Map<String, String?> payload) {
    var type = payload['type'];
    if (type == 'feature_nudge') type = payload['target'];

    return switch (type) {
      'wird_reminder' ||
      'open_wird' => const RouteDestination(AppConstants.wirdRoute),
      'prayer' ||
      'azkar_duha' => const RouteDestination(AppConstants.prayerTimesRoute),
      // The verse or dua the notification showed is on Home's card; its
      // settings page is what the feature-discovery nudge advertises.
      'daily_inspiration' => const TabDestination(AppTab.home),
      'open_daily_inspiration' => const RouteDestination(
        AppConstants.dailyInspirationSettingsRoute,
      ),
      'fasting_reminder' ||
      'weekly_fasting' ||
      'open_fasting' => const FastingCalendarDestination(),
      // Azkar open the way a tap on the category's card would: the Azkar tab,
      // with the category on top, ready to read.
      'azkar_morning' || 'azkar_evening' => const AzkarCategoryDestination(
        AppConstants.azkarMorningEveningCategory,
      ),
      'azkar_sleep' => const AzkarCategoryDestination(
        AppConstants.azkarSleepCategory,
      ),
      'azkar_witr' => const AzkarCategoryDestination(
        AppConstants.azkarWitrCategory,
      ),
      'azkar_qiyam' => const AzkarCategoryDestination(
        AppConstants.azkarWakingCategory,
      ),
      'azkar_after_prayer' => const RouteDestination(
        AppConstants.afterPrayerAdhkarRoute,
        tab: AppTab.azkar,
      ),
      'azkar_kahf' => const QuranSurahDestination(18),
      'open_azkar_reminders' => const RouteDestination(
        AppConstants.azkarRemindersSettingsRoute,
      ),
      'open_zakat' => const RouteDestination(AppConstants.zakatRoute),
      'open_backgrounds' => const RouteDestination(
        AppConstants.islamicBackgroundsRoute,
      ),
      'open_prayer_settings' => const TabDestination(AppTab.settings),
      // "Open the app so your reminders keep working" — opening it is the point.
      'reminder_floor' => const TabDestination(AppTab.home),
      _ => null,
    };
  }
}

/// Just a tab.
final class TabDestination extends NotificationDestination {
  const TabDestination(super.tab);
}

/// A named route from [AppRouter], pushed over [tab].
final class RouteDestination extends NotificationDestination {
  const RouteDestination(this.routeName, {AppTab tab = AppTab.home})
    : super(tab);

  final String routeName;
}

/// An azkar category, by its title in adhkar.json, over the Azkar tab.
final class AzkarCategoryDestination extends NotificationDestination {
  const AzkarCategoryDestination(this.title) : super(AppTab.azkar);

  final String title;
}

/// A surah, opened in the Quran tab.
final class QuranSurahDestination extends NotificationDestination {
  const QuranSurahDestination(this.surah) : super(AppTab.quran);

  final int surah;
}

/// The fasting calendar — a dialog, not a route — over Home.
final class FastingCalendarDestination extends NotificationDestination {
  const FastingCalendarDestination() : super(AppTab.home);
}

/// Turns a tapped notification's payload into in-app navigation, from outside
/// the widget tree, through [AppRouter.navigatorKey] and [AppShell].
class NotificationRouter {
  NotificationRouter._();

  /// Bumped by every routed tap.
  static int _generation = 0;

  /// Route a payload held from before the shell existed. Called by the shell
  /// on its first frame.
  static void consumePending() {
    final payload = PendingNotificationAction.consume();
    if (payload != null) dispatch(payload);
  }

  /// Navigate to the screen that corresponds to a tapped notification.
  static void dispatch(Map<String, String?> payload) {
    final navigator = AppRouter.navigatorKey.currentState;
    final shell = AppShell.route;
    if (navigator == null || shell == null) {
      // Splash or onboarding still up. Anything pushed now would sit on the
      // splash and be swept away by its pushReplacement; the shell routes it
      // instead, once it is mounted.
      PendingNotificationAction.hold(payload);
      return;
    }

    // A restored backup leaves the app waiting to be restarted, on a screen
    // that must not be left (see RestartRequired). Nothing routes from there.
    if (RestartRequired.isLatched) return;

    final destination = NotificationDestination.forPayload(payload);
    // Unknown type — leave the user where they are.
    if (destination == null) return;

    // Back to the shell first, so the stack is always tab + one screen: the
    // first back press lands on the tab, the next on Home, then out. popUntil
    // pops directly, past PopScope, so it stops at any screen that refuses to
    // be left — a backup mid-restore — and the tap then goes nowhere.
    var blocked = false;
    navigator.popUntil((route) {
      if (identical(route, shell) || route.isFirst) return true;
      if (route.popDisposition == RoutePopDisposition.doNotPop) {
        blocked = true;
        return true;
      }
      return false;
    });
    if (blocked) return;

    // Only the newest tap may finish an async open; see _openAzkarCategory.
    final generation = ++_generation;

    switch (destination) {
      case TabDestination(:final tab):
        AppShell.tab.value = tab;
      case RouteDestination(:final tab, :final routeName):
        AppShell.tab.value = tab;
        navigator.pushNamed(routeName);
      case AzkarCategoryDestination(:final title):
        AppShell.tab.value = AppTab.azkar;
        _openAzkarCategory(navigator, title, generation);
      case QuranSurahDestination(:final surah):
        _openSurah(surah);
      case FastingCalendarDestination():
        AppShell.tab.value = AppTab.home;
        _openFastingCalendar();
    }
  }

  /// Pushes the category the way the Azkar tab's own card does. The category
  /// is resolved before anything is pushed, so a title that is not in the data
  /// leaves the user on the Azkar tab rather than on an empty page.
  static Future<void> _openAzkarCategory(
    NavigatorState navigator,
    String title,
    int generation,
  ) async {
    final categories = await AzkarRepositoryImpl().getAllCategories();
    final category = AzkarCategoryByTitleScreen.find(categories, title);
    // The load is async: only push if no newer tap has been routed since
    // (two quick taps would otherwise stack two categories) and the user is
    // still where it sent them.
    if (generation != _generation ||
        category == null ||
        !navigator.mounted ||
        AppShell.route?.isCurrent != true ||
        AppShell.tab.value != AppTab.azkar) {
      return;
    }
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => AzkarCategoryDetailsScreen(category: category),
      ),
    );
  }

  /// With no reader on screen, quran_library's jump sets the page the reader
  /// will open on; with one, it jumps there. So: once before the Quran tab is
  /// built, and once after, for a reader that restores its last page on start.
  static void _openSurah(int surah) {
    _jumpToSurah(surah);
    AppShell.tab.value = AppTab.quran;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToSurah(surah));
      WidgetsBinding.instance.scheduleFrame();
    });
  }

  static void _jumpToSurah(int surah) {
    try {
      QuranLibrary().jumpToSurah(surah);
    } catch (e) {
      debugPrint('NotificationRouter: could not open surah $surah: $e');
    }
  }

  /// The fasting calendar is a dialog (not a route). [FastingRemindersCubit] is
  /// a top-level eager provider, so it resolves from the navigator's context.
  static void _openFastingCalendar() {
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
