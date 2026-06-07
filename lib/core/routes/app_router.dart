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

class AppRouter {
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
          pageBuilder: (_, __, ___) => ShareScreen(payload: args),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
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
