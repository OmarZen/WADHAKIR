/// Screen-width breakpoints used to switch layout density.
///
/// xs/sm cover phones, md tablets, lg desktops. Designs should prefer
/// content reflow over a hard layout switch; reach for these only when the
/// information density truly needs to change.
class Breakpoints {
  Breakpoints._();

  static const double xs = 360;
  static const double sm = 600;
  static const double md = 840;
  static const double lg = 1200;

  static bool isCompact(double width) => width < sm;
  static bool isMedium(double width) => width >= sm && width < md;
  static bool isExpanded(double width) => width >= md;
}
