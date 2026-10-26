import 'package:flutter/widgets.dart';

/// The bottom-bar tabs of [ScaffoldWithNavBar], in bar order.
enum AppTab { home, quran, azkar, settings }

/// The bottom-bar shell as seen from outside the widget tree.
///
/// The notification router runs from a plugin callback with no `BuildContext`,
/// and two of its jobs need the shell: switching tab ("morning azkar" opens the
/// Azkar tab, then the category on top), and knowing whether the shell is on
/// screen at all. Before it is — the splash, onboarding — anything pushed onto
/// the root navigator lands on top of the splash and is then replaced by the
/// splash's own `pushReplacement`, which is how a tapped notification used to
/// open the home page instead of its screen.
class AppShell {
  AppShell._();

  /// The selected tab. [ScaffoldWithNavBar] renders it and writes taps to it.
  static final ValueNotifier<AppTab> tab = ValueNotifier(AppTab.home);

  static Route<dynamic>? _route;

  /// The shell's own route while it is mounted; null on the splash and
  /// onboarding. The router pops back to it before opening a destination.
  static Route<dynamic>? get route => _route;

  static bool get isMounted => _route != null;

  static void attach(Route<dynamic> route) => _route = route;

  static void detach(Route<dynamic> route) {
    if (identical(_route, route)) _route = null;
  }
}
