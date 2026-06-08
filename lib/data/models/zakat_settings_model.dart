import 'package:equatable/equatable.dart';
import 'package:wadhakir/features/zakat/services/zakat_calculator.dart';

// Sentinel to distinguish "not provided" from "explicitly set to null" in
// copyWith (mirrors the pattern in notification_settings_model.dart).
const Object _undefined = Object();

/// Persisted inputs for the Zakat Calculator so the user's last entry (amounts,
/// metal prices, basis, currency) survives app restarts.
class ZakatSettingsModel extends Equatable {
  final double cash;
  final double goldGrams;
  final double goldPricePerGram;
  final double silverGrams;
  final double silverPricePerGram;
  final double otherAssets;
  final double liabilities;
  final NisabBasis nisabBasis;

  /// Optional Nisab weight override in grams; null = use the basis default.
  final double? customNisabGrams;

  /// Cosmetic currency label shown next to amounts (e.g. "ر.س", "$").
  final String currencyLabel;

  const ZakatSettingsModel({
    required this.cash,
    required this.goldGrams,
    required this.goldPricePerGram,
    required this.silverGrams,
    required this.silverPricePerGram,
    required this.otherAssets,
    required this.liabilities,
    required this.nisabBasis,
    required this.customNisabGrams,
    required this.currencyLabel,
  });

  factory ZakatSettingsModel.defaultSettings() {
    return const ZakatSettingsModel(
      cash: 0,
      goldGrams: 0,
      goldPricePerGram: 0,
      silverGrams: 0,
      silverPricePerGram: 0,
      otherAssets: 0,
      liabilities: 0,
      // Silver basis is the more inclusive default.
      nisabBasis: NisabBasis.silver,
      customNisabGrams: null,
      currencyLabel: '',
    );
  }

  ZakatSettingsModel copyWith({
    double? cash,
    double? goldGrams,
    double? goldPricePerGram,
    double? silverGrams,
    double? silverPricePerGram,
    double? otherAssets,
    double? liabilities,
    NisabBasis? nisabBasis,
    Object? customNisabGrams = _undefined,
    String? currencyLabel,
  }) {
    return ZakatSettingsModel(
      cash: cash ?? this.cash,
      goldGrams: goldGrams ?? this.goldGrams,
      goldPricePerGram: goldPricePerGram ?? this.goldPricePerGram,
      silverGrams: silverGrams ?? this.silverGrams,
      silverPricePerGram: silverPricePerGram ?? this.silverPricePerGram,
      otherAssets: otherAssets ?? this.otherAssets,
      liabilities: liabilities ?? this.liabilities,
      nisabBasis: nisabBasis ?? this.nisabBasis,
      customNisabGrams: customNisabGrams == _undefined
          ? this.customNisabGrams
          : customNisabGrams as double?,
      currencyLabel: currencyLabel ?? this.currencyLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cash': cash,
      'goldGrams': goldGrams,
      'goldPricePerGram': goldPricePerGram,
      'silverGrams': silverGrams,
      'silverPricePerGram': silverPricePerGram,
      'otherAssets': otherAssets,
      'liabilities': liabilities,
      'nisabBasis': nisabBasis.index,
      'customNisabGrams': customNisabGrams,
      'currencyLabel': currencyLabel,
    };
  }

  factory ZakatSettingsModel.fromJson(Map<String, dynamic> json) {
    double d(Object? v) => (v as num?)?.toDouble() ?? 0.0;
    final basisIndex = json['nisabBasis'] as int? ?? NisabBasis.silver.index;
    return ZakatSettingsModel(
      cash: d(json['cash']),
      goldGrams: d(json['goldGrams']),
      goldPricePerGram: d(json['goldPricePerGram']),
      silverGrams: d(json['silverGrams']),
      silverPricePerGram: d(json['silverPricePerGram']),
      otherAssets: d(json['otherAssets']),
      liabilities: d(json['liabilities']),
      nisabBasis: NisabBasis.values[basisIndex.clamp(
        0,
        NisabBasis.values.length - 1,
      )],
      customNisabGrams: (json['customNisabGrams'] as num?)?.toDouble(),
      currencyLabel: json['currencyLabel'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    cash,
    goldGrams,
    goldPricePerGram,
    silverGrams,
    silverPricePerGram,
    otherAssets,
    liabilities,
    nisabBasis,
    customNisabGrams,
    currencyLabel,
  ];
}
