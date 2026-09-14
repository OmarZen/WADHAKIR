/// Consistent spacing scale used across the app.
///
/// Follows a 4/8dp rhythm so visual relationships are predictable. Use these
/// instead of hardcoded literals like `EdgeInsets.all(12)` so the whole app
/// breathes the same way and tablet/desktop densities can be tuned in one
/// place.
class Spacing {
  Spacing._();

  /// Hairline — used for very tight icon/text gaps.
  static const double xxs = 2.0;

  /// Tight gap inside compact components (chips, badges).
  static const double xs = 4.0;

  /// Default small gap between related elements.
  static const double sm = 8.0;

  /// Standard inner padding for compact cards / list items.
  static const double md = 12.0;

  /// Standard card padding and section gutter.
  static const double lg = 16.0;

  /// Larger gap between distinct UI groups.
  static const double xl = 24.0;

  /// Section break — significant vertical/horizontal separation.
  static const double xxl = 32.0;

  /// Page-level top padding under hero sections.
  static const double xxxl = 48.0;
}
