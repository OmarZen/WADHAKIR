import 'package:flutter/material.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/widgets/scaffold_with_nav_bar.dart';
import 'package:wadhakir/features/home/views/screens/home_screen.dart';
import 'package:wadhakir/features/radio/views/screens/radio_screen.dart';
import 'package:wadhakir/features/campus/views/screens/qibla_screen.dart';
import 'package:wadhakir/features/settings/view/screens/settings_screen.dart';
import 'package:wadhakir/features/pray_times/views/screens/prayer_times_screen.dart';
import 'package:wadhakir/features/floating_dhikr/views/screens/floating_dhikr_settings_screen.dart';
import 'package:wadhakir/features/moon_phases/views/screens/moon_phases_calendar_screen.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';
import 'package:wadhakir/features/share/views/screens/share_screen.dart';
import 'package:wadhakir/features/wird/views/screens/wird_screen.dart';
import 'package:wadhakir/features/islamic_backgrounds/views/screens/islamic_backgrounds_screen.dart';
import 'package:wadhakir/features/zakat/views/screens/zakat_screen.dart';
import 'package:wadhakir/features/daily_inspiration/views/screens/daily_inspiration_settings_page.dart';
import 'package:wadhakir/features/quran/views/screens/quran_screen.dart';
import 'package:wadhakir/features/prayer_adhkar/views/prayer_adhkar_screen.dart';
import 'package:wadhakir/features/azkar/views/screens/azkar_category_by_title_screen.dart';
import 'package:wadhakir/features/azkar_reminders/views/screens/azkar_reminders_settings_page.dart';
import 'package:wadhakir/features/salah_tracker/views/screens/salah_tracker_screen.dart';

class AppRouter {
  /// Root navigator key — lets notification taps (handled outside the widget
  /// tree) drive in-app navigation via [NotificationRouter].
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.homeRoute:
        return MaterialPageRoute(builder: (_) => const ScaffoldWithNavBar());

      case AppConstants.homeScreenRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppConstants.prayerTimesRoute:
        return MaterialPageRoute(builder: (_) => const PrayerTimesScreen());

      case AppConstants.settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case AppConstants.campusRoute:
        return MaterialPageRoute(builder: (_) => const QiblaScreen());

      case AppConstants.radioRoute:
        return MaterialPageRoute(builder: (_) => const RadioScreen());

      case AppConstants.floatingDhikrSettingsRoute:
        return MaterialPageRoute(
          builder: (_) => const FloatingDhikrSettingsScreen(),
        );

      case AppConstants.moonPhasesRoute:
        return MaterialPageRoute(
          builder: (_) => const MoonPhasesCalendarScreen(),
        );

      case AppConstants.wirdRoute:
        return MaterialPageRoute(builder: (_) => const WirdScreen());

      case AppConstants.islamicBackgroundsRoute:
        return MaterialPageRoute(
          builder: (_) => const IslamicBackgroundsScreen(),
        );

      case AppConstants.zakatRoute:
        return MaterialPageRoute(builder: (_) => const ZakatScreen());

      case AppConstants.dailyInspirationSettingsRoute:
        return MaterialPageRoute(
          builder: (_) => const DailyInspirationSettingsPage(),
        );

      case AppConstants.quranRoute:
        return MaterialPageRoute(builder: (_) => const QuranScreen());

      case AppConstants.afterPrayerAdhkarRoute:
        return MaterialPageRoute(builder: (_) => const PrayerAdhkarScreen());

      case AppConstants.azkarRemindersSettingsRoute:
        return MaterialPageRoute(
          builder: (_) => const AzkarRemindersSettingsPage(),
        );

      case AppConstants.salahTrackerRoute:
        return MaterialPageRoute(builder: (_) => const SalahTrackerScreen());

      case AppConstants.azkarCategoryDetailsRoute:
        // Deep-link from azkar notifications: the argument is the category
        // title (a String); resolve it to the full category.
        final title = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => AzkarCategoryByTitleScreen(
            title: title is String
                ? title
                : AppConstants.azkarMorningEveningCategory,
          ),
        );

      case AppConstants.shareRoute:
        // The share screen always receives a SharePayload via arguments;
        // a missing/wrong type is a programmer error so we fail loud.
        final args = settings.arguments;
        if (args is! SharePayload) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Share payload missing')),
            ),
          );
        }
        return PageRouteBuilder(
          pageBuilder: (_, _, _) => ShareScreen(payload: args),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 320),
        );

      // Add other routes as they are implemented

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found!'))),
        );
    }
  }
}
