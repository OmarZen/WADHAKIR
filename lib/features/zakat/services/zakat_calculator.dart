import 'package:equatable/equatable.dart';

/// Which precious-metal standard defines the Nisab (the minimum wealth on which
/// zakat becomes due).
///
/// The gold basis uses 85g of gold; the silver basis uses 595g of silver.
/// Because silver yields a lower monetary threshold, more wealth qualifies, so
/// most scholars recommend the silver basis as the more cautious / inclusive
/// default.
enum NisabBasis { gold, silver }

/// Widely-used default Nisab weights in grams (the 85g / 595g figures; some
/// bodies use 87.48g / 612.36g — exposed as an overridable value in the UI).
const double kGoldNisabGrams = 85.0;
const double kSilverNisabGrams = 595.0;

/// The zakat rate on monetary wealth: 2.5%.
const double kZakatRate = 0.025;

/// Immutable outcome of a zakat computation. All monetary values are in the
/// user's chosen (cosmetic) currency unit.
class ZakatResult extends Equatable {
  /// Sum of all zakatable assets before deducting liabilities.
  final double totalAssets;

  /// Total short-term debts/liabilities deducted.
  final double totalLiabilities;

  /// `totalAssets - totalLiabilities`, clamped at 0.
  final double netZakatable;

  /// Effective Nisab weight in grams used for the threshold.
  final double nisabGrams;

  /// Monetary value of the Nisab threshold (`nisabGrams × price-per-gram` of the
  /// chosen basis). 0 when the price for the chosen basis was not provided.
  final double nisabValue;

  /// Whether zakat is due (a valid Nisab value exists and net wealth ≥ it).
  final bool isDue;

  /// The zakat owed (`netZakatable × 2.5%`), or 0 when not due.
  final double zakatDue;

  const ZakatResult({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netZakatable,
    required this.nisabGrams,
    required this.nisabValue,
    required this.isDue,
    required this.zakatDue,
  });

  @override
  List<Object?> get props => [
    totalAssets,
    totalLiabilities,
    netZakatable,
    nisabGrams,
    nisabValue,
    isDue,
    zakatDue,
  ];
}

/// Pure, dependency-free zakat math. Kept separate from the UI so it is trivial
/// to unit-test.
class ZakatCalculator {
  const ZakatCalculator._();

  /// Effective Nisab weight in grams: a positive [customGrams] override wins,
  /// otherwise the default for [basis].
  static double nisabGramsFor(NisabBasis basis, {double? customGrams}) {
    if (customGrams != null && customGrams > 0) return customGrams;
    return basis == NisabBasis.gold ? kGoldNisabGrams : kSilverNisabGrams;
  }

  /// Compute zakat from the raw inputs. Negative / non-finite inputs are treated
  /// as 0; liabilities exceeding assets clamp net wealth to 0 (never negative).
  static ZakatResult compute({
    required double cash,
    required double goldGrams,
    required double goldPricePerGram,
    required double silverGrams,
    required double silverPricePerGram,
    required double otherAssets,
    required double liabilities,
    required NisabBasis nisabBasis,
    double? customNisabGrams,
  }) {
    double clean(double v) => (v.isFinite && v > 0) ? v : 0.0;

    final c = clean(cash);
    final gg = clean(goldGrams);
    final gp = clean(goldPricePerGram);
    final sg = clean(silverGrams);
    final sp = clean(silverPricePerGram);
    final oa = clean(otherAssets);
    final li = clean(liabilities);

    final totalAssets = c + gg * gp + sg * sp + oa;
    final netZakatable = (totalAssets - li).clamp(0.0, double.infinity);

    final nisabGrams = nisabGramsFor(nisabBasis, customGrams: customNisabGrams);
    final pricePerGram = nisabBasis == NisabBasis.gold ? gp : sp;
    final nisabValue = nisabGrams * pricePerGram;

    // Due only when a valid (positive) Nisab value is known AND met.
    final isDue = nisabValue > 0 && netZakatable >= nisabValue;
    final zakatDue = isDue ? netZakatable * kZakatRate : 0.0;

    return ZakatResult(
      totalAssets: totalAssets,
      totalLiabilities: li,
      netZakatable: netZakatable,
      nisabGrams: nisabGrams,
      nisabValue: nisabValue,
      isDue: isDue,
      zakatDue: zakatDue,
    );
  }
}
