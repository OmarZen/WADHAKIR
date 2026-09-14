import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/features/zakat/services/zakat_calculator.dart';
import 'package:wadhakir/features/zakat/services/zakat_format.dart';

void main() {
  group('ZakatCalculator.compute', () {
    test('below Nisab → not due, zakat is 0', () {
      // Silver basis: nisab value = 595g × 1 = 595. Net wealth 100 < 595.
      final r = ZakatCalculator.compute(
        cash: 100,
        goldGrams: 0,
        goldPricePerGram: 0,
        silverGrams: 0,
        silverPricePerGram: 1, // gives a valid nisab value
        otherAssets: 0,
        liabilities: 0,
        nisabBasis: NisabBasis.silver,
      );
      expect(r.nisabValue, 595);
      expect(r.isDue, isFalse);
      expect(r.zakatDue, 0);
    });

    test('above Nisab → due, zakat is 2.5% of net wealth', () {
      final r = ZakatCalculator.compute(
        cash: 10000,
        goldGrams: 0,
        goldPricePerGram: 0,
        silverGrams: 0,
        silverPricePerGram: 1, // nisab value = 595
        otherAssets: 0,
        liabilities: 0,
        nisabBasis: NisabBasis.silver,
      );
      expect(r.isDue, isTrue);
      expect(r.netZakatable, 10000);
      expect(r.zakatDue, closeTo(250, 1e-9));
    });

    test('liabilities exceeding assets → net clamps to 0, not due', () {
      final r = ZakatCalculator.compute(
        cash: 1000,
        goldGrams: 0,
        goldPricePerGram: 0,
        silverGrams: 0,
        silverPricePerGram: 1,
        otherAssets: 0,
        liabilities: 5000,
        nisabBasis: NisabBasis.silver,
      );
      expect(r.netZakatable, 0);
      expect(r.isDue, isFalse);
      expect(r.zakatDue, 0);
    });

    test('gold vs silver basis use different thresholds', () {
      // Same prices for both metals (10/g). Net wealth = 5000.
      // Gold nisab = 85 × 10 = 850 → due. Silver nisab = 595 × 10 = 5950 → not.
      params() => {
        'cash': 5000.0,
        'goldGrams': 0.0,
        'goldPricePerGram': 10.0,
        'silverGrams': 0.0,
        'silverPricePerGram': 10.0,
        'otherAssets': 0.0,
        'liabilities': 0.0,
      };
      final gold = ZakatCalculator.compute(
        cash: params()['cash']!,
        goldGrams: params()['goldGrams']!,
        goldPricePerGram: params()['goldPricePerGram']!,
        silverGrams: params()['silverGrams']!,
        silverPricePerGram: params()['silverPricePerGram']!,
        otherAssets: params()['otherAssets']!,
        liabilities: params()['liabilities']!,
        nisabBasis: NisabBasis.gold,
      );
      final silver = ZakatCalculator.compute(
        cash: params()['cash']!,
        goldGrams: params()['goldGrams']!,
        goldPricePerGram: params()['goldPricePerGram']!,
        silverGrams: params()['silverGrams']!,
        silverPricePerGram: params()['silverPricePerGram']!,
        otherAssets: params()['otherAssets']!,
        liabilities: params()['liabilities']!,
        nisabBasis: NisabBasis.silver,
      );
      expect(gold.nisabValue, 850);
      expect(gold.isDue, isTrue);
      expect(silver.nisabValue, 5950);
      expect(silver.isDue, isFalse);
    });

    test('custom Nisab grams override the basis default', () {
      final r = ZakatCalculator.compute(
        cash: 0,
        goldGrams: 0,
        goldPricePerGram: 100, // gold basis price
        silverGrams: 0,
        silverPricePerGram: 0,
        otherAssets: 1000,
        liabilities: 0,
        nisabBasis: NisabBasis.gold,
        customNisabGrams: 5, // 5g × 100 = 500 threshold
      );
      expect(r.nisabGrams, 5);
      expect(r.nisabValue, 500);
      expect(r.isDue, isTrue); // 1000 ≥ 500
    });

    test('no price for chosen basis → nisab unknown → not due', () {
      final r = ZakatCalculator.compute(
        cash: 100000,
        goldGrams: 0,
        goldPricePerGram: 0, // gold basis chosen but no gold price entered
        silverGrams: 0,
        silverPricePerGram: 0,
        otherAssets: 0,
        liabilities: 0,
        nisabBasis: NisabBasis.gold,
      );
      expect(r.nisabValue, 0);
      expect(r.isDue, isFalse);
      expect(r.zakatDue, 0);
    });

    test('gold + silver holdings contribute to total assets', () {
      final r = ZakatCalculator.compute(
        cash: 1000,
        goldGrams: 10,
        goldPricePerGram: 200, // 2000
        silverGrams: 100,
        silverPricePerGram: 2, // 200
        otherAssets: 500,
        liabilities: 100,
        nisabBasis: NisabBasis.silver,
      );
      // 1000 + 2000 + 200 + 500 = 3700; net = 3600
      expect(r.totalAssets, 3700);
      expect(r.netZakatable, 3600);
    });
  });

  group('ZakatFormat.parseAmount', () {
    test('parses plain and grouped numbers', () {
      expect(ZakatFormat.parseAmount('1234.56'), closeTo(1234.56, 1e-9));
      expect(ZakatFormat.parseAmount('1,234.56'), closeTo(1234.56, 1e-9));
      expect(ZakatFormat.parseAmount('  '), 0);
    });

    test('treats comma as decimal separator when no dot present', () {
      expect(ZakatFormat.parseAmount('12,5'), closeTo(12.5, 1e-9));
    });

    test('parses Arabic-Indic digits', () {
      expect(ZakatFormat.parseAmount('٢٥٠'), 250);
      expect(ZakatFormat.parseAmount('١٢٣٤٫٥'), closeTo(1234.5, 1e-9));
    });
  });

  group('ZakatFormat.formatAmount', () {
    test('groups thousands and trims trailing zeros', () {
      expect(ZakatFormat.formatAmount(1234.5, arabic: false), '1,234.5');
      expect(ZakatFormat.formatAmount(1000, arabic: false), '1,000');
      expect(ZakatFormat.formatAmount(250, arabic: false), '250');
    });

    test('converts to Arabic-Indic digits when requested', () {
      expect(ZakatFormat.formatAmount(250, arabic: true), '٢٥٠');
    });
  });
}
