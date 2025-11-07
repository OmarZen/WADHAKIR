import 'package:flutter/material.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/widgets/scaffold_with_nav_bar.dart';
import 'package:wadhakir/features/home/views/screens/home_screen.dart';
import 'package:wadhakir/features/radio/views/screens/radio_screen.dart';
import 'package:wadhakir/features/campus/views/screens/qibla_screen.dart';
import 'package:wadhakir/features/settings/view/screens/settings_screen.dart';
import 'package:wadhakir/features/pray_times/views/screens/prayer_times_screen.dart';

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

      // Add other routes as they are implemented

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found!'))),
        );
    }
  }
}
