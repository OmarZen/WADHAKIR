import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/zakat_settings_model.dart';
import 'package:wadhakir/data/repositories/zakat_settings_repository_impl.dart';
import 'package:wadhakir/features/zakat/services/zakat_calculator.dart';
import 'package:wadhakir/features/zakat/services/zakat_format.dart';
import 'package:wadhakir/features/zakat/views/widgets/zakat_hero_card.dart';
import 'package:wadhakir/features/zakat/views/widgets/zakat_input_row.dart';
import 'package:wadhakir/features/zakat/views/widgets/zakat_result_card.dart';

/// Self-contained Zakat Calculator: computes zakat (2.5%) on net zakatable
/// wealth against the Nisab threshold, with all metal prices entered manually
/// (offline-first). Inputs persist via [ZakatSettingsRepositoryImpl].
class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  ZakatSettingsRepositoryImpl? _repo;
  bool _loaded = false;

  final _cash = TextEditingController();
  final _goldGrams = TextEditingController();
  final _goldPrice = TextEditingController();
  final _silverGrams = TextEditingController();
  final _silverPrice = TextEditingController();
  final _other = TextEditingController();
  final _liabilities = TextEditingController();
  final _customNisab = TextEditingController();
  final _currency = TextEditingController();
  NisabBasis _basis = NisabBasis.silver;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cash.dispose();
    _goldGrams.dispose();
    _goldPrice.dispose();
    _silverGrams.dispose();
    _silverPrice.dispose();
    _other.dispose();
    _liabilities.dispose();
    _customNisab.dispose();
    _currency.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = ZakatSettingsRepositoryImpl(prefs);
    final s = repo.getSettings();
    if (!mounted) return;
    _repo = repo;
    _basis = s.nisabBasis;
    _cash.text = _numText(s.cash);
    _goldGrams.text = _numText(s.goldGrams);
    _goldPrice.text = _numText(s.goldPricePerGram);
    _silverGrams.text = _numText(s.silverGrams);
    _silverPrice.text = _numText(s.silverPricePerGram);
    _other.text = _numText(s.otherAssets);
    _liabilities.text = _numText(s.liabilities);
    _customNisab.text = s.customNisabGrams == null
        ? ''
        : _numText(s.customNisabGrams!);
    _currency.text = s.currencyLabel;
    setState(() => _loaded = true);
  }

  /// Plain (un-grouped) editable representation; empty for 0 so the hint shows.
  String _numText(double v) {
    if (v == 0) return '';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  double? _customGramsOrNull() {
    final g = ZakatFormat.parseAmount(_customNisab.text);
    return g > 0 ? g : null;
  }

  ZakatResult _compute() {
    return ZakatCalculator.compute(
      cash: ZakatFormat.parseAmount(_cash.text),
      goldGrams: ZakatFormat.parseAmount(_goldGrams.text),
      goldPricePerGram: ZakatFormat.parseAmount(_goldPrice.text),
      silverGrams: ZakatFormat.parseAmount(_silverGrams.text),
      silverPricePerGram: ZakatFormat.parseAmount(_silverPrice.text),
      otherAssets: ZakatFormat.parseAmount(_other.text),
      liabilities: ZakatFormat.parseAmount(_liabilities.text),
      nisabBasis: _basis,
      customNisabGrams: _customGramsOrNull(),
    );
  }

  void _persist() {
    _repo?.saveSettings(
      ZakatSettingsModel(
        cash: ZakatFormat.parseAmount(_cash.text),
        goldGrams: ZakatFormat.parseAmount(_goldGrams.text),
        goldPricePerGram: ZakatFormat.parseAmount(_goldPrice.text),
        silverGrams: ZakatFormat.parseAmount(_silverGrams.text),
        silverPricePerGram: ZakatFormat.parseAmount(_silverPrice.text),
        otherAssets: ZakatFormat.parseAmount(_other.text),
        liabilities: ZakatFormat.parseAmount(_liabilities.text),
        nisabBasis: _basis,
        customNisabGrams: _customGramsOrNull(),
        currencyLabel: _currency.text.trim(),
      ),
    );
  }

  void _onChanged(String _) {
    setState(() {});
    _persist();
  }

  void _setBasis(NisabBasis basis) {
    setState(() => _basis = basis);
    _persist();
  }

  void _reset() {
    setState(() {
      for (final c in [
        _cash,
        _goldGrams,
        _goldPrice,
        _silverGrams,
        _silverPrice,
        _other,
        _liabilities,
        _customNisab,
        _currency,
      ]) {
        c.clear();
      }
      _basis = NisabBasis.silver;
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cur = _currency.text.trim();
    final grams = l10n?.translate('zakat.unit_grams') ?? 'جرام';
    final defaultNisabGrams = _basis == NisabBasis.gold
        ? kGoldNisabGrams
        : kSilverNisabGrams;
    final result = _compute();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.translate('zakat.title') ?? 'حاسبة الزكاة'),
        actions: [
          IconButton(
            tooltip: l10n?.translate('zakat.reset') ?? 'إعادة تعيين',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loaded ? _reset : null,
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: Spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Live result hero ----
                  ZakatHeroCard(result: result, currencyLabel: cur),

                  // ---- Assets ----
                  _section(
                    context,
                    title: l10n?.translate('zakat.assets') ?? 'الأموال',
                    icon: Icons.account_balance_wallet_rounded,
                    children: [
                      ZakatInputRow(
                        label:
                            l10n?.translate('zakat.cash') ?? 'النقد والمدخرات',
                        controller: _cash,
                        onChanged: _onChanged,
                        suffix: cur,
                        icon: Icons.payments_rounded,
                      ),
                      ZakatInputRow(
                        label:
                            l10n?.translate('zakat.gold_grams') ?? 'وزن الذهب',
                        controller: _goldGrams,
                        onChanged: _onChanged,
                        suffix: grams,
                        icon: Icons.diamond_rounded,
                      ),
                      ZakatInputRow(
                        label:
                            l10n?.translate('zakat.gold_price') ??
                            'سعر جرام الذهب',
                        controller: _goldPrice,
                        onChanged: _onChanged,
                        suffix: cur,
                      ),
                      ZakatInputRow(
                        label:
                            l10n?.translate('zakat.silver_grams') ??
                            'وزن الفضة',
                        controller: _silverGrams,
                        onChanged: _onChanged,
                        suffix: grams,
                        icon: Icons.brightness_1_rounded,
                      ),
                      ZakatInputRow(
                        label:
                            l10n?.translate('zakat.silver_price') ??
                            'سعر جرام الفضة',
                        controller: _silverPrice,
                        onChanged: _onChanged,
                        suffix: cur,
                      ),
                      ZakatInputRow(
                        label:
                            l10n?.translate('zakat.other_assets') ??
                            'أصول أخرى وعروض تجارة',
                        controller: _other,
                        onChanged: _onChanged,
                        suffix: cur,
                        icon: Icons.storefront_rounded,
                      ),
                    ],
                  ),

                  // ---- Deductions ----
                  _section(
                    context,
                    title: l10n?.translate('zakat.deductions') ?? 'الخصومات',
                    icon: Icons.remove_circle_outline_rounded,
                    children: [
                      ZakatInputRow(
                        label:
                            l10n?.translate('zakat.liabilities') ??
                            'الديون قصيرة الأجل',
                        controller: _liabilities,
                        onChanged: _onChanged,
                        suffix: cur,
                      ),
                    ],
                  ),

                  // ---- Nisab & currency ----
                  _section(
                    context,
                    title: l10n?.translate('zakat.nisab') ?? 'النصاب والعملة',
                    icon: Icons.tune_rounded,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.sm),
                        child: Text(
                          l10n?.translate('zakat.nisab_basis') ?? 'أساس النصاب',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _BasisSelector(
                        basis: _basis,
                        onChanged: _setBasis,
                        goldLabel:
                            l10n?.translate('zakat.basis_gold') ??
                            'ذهب (٨٥ جم)',
                        silverLabel:
                            l10n?.translate('zakat.basis_silver') ??
                            'فضة (٥٩٥ جم)',
                      ),
                      const SizedBox(height: Spacing.md),
                      ZakatInputRow(
                        label:
                            l10n?.translate('zakat.custom_nisab_grams') ??
                            'وزن النصاب (اختياري)',
                        controller: _customNisab,
                        onChanged: _onChanged,
                        suffix: grams,
                        hint: _numText(defaultNisabGrams),
                      ),
                      ZakatInputRow(
                        label: l10n?.translate('zakat.currency') ?? 'العملة',
                        controller: _currency,
                        onChanged: _onChanged,
                        icon: Icons.attach_money_rounded,
                        hint: l10n?.translate('zakat.currency_hint') ?? 'ر.س',
                      ),
                    ],
                  ),

                  // ---- Breakdown ----
                  _section(
                    context,
                    title: l10n?.translate('zakat.breakdown') ?? 'التفاصيل',
                    icon: Icons.receipt_long_rounded,
                    children: [
                      ZakatResultCard(
                        result: result,
                        currencyLabel: cur,
                        showHeadline: false,
                      ),
                    ],
                  ),

                  // ---- Hawl note ----
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    child: Text(
                      l10n?.translate('zakat.hawl_note') ??
                          'تُخرَج الزكاة بشرط بلوغ النصاب ومرور عام هجري كامل على المال.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    child: FButton(
                      onPress: _reset,
                      variant: FButtonVariant.outline,
                      child: Text(
                        l10n?.translate('zakat.reset') ?? 'إعادة تعيين',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDark
                      ? cs.onSurface.withValues(alpha: 0.85)
                      : cs.primary,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          ...children,
        ],
      ),
    );
  }
}

/// Two-option toggle selecting the Nisab basis (gold vs silver).
class _BasisSelector extends StatelessWidget {
  final NisabBasis basis;
  final ValueChanged<NisabBasis> onChanged;
  final String goldLabel;
  final String silverLabel;

  const _BasisSelector({
    required this.basis,
    required this.onChanged,
    required this.goldLabel,
    required this.silverLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _option(
            context,
            label: silverLabel,
            selected: basis == NisabBasis.silver,
            onTap: () => onChanged(NisabBasis.silver),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _option(
            context,
            label: goldLabel,
            selected: basis == NisabBasis.gold,
            onTap: () => onChanged(NisabBasis.gold),
          ),
        ),
      ],
    );
  }

  Widget _option(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return InkWell(
      borderRadius: Radii.all(Radii.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.14)
              : primary.withValues(alpha: 0.03),
          borderRadius: Radii.all(Radii.md),
          border: Border.all(
            color: selected ? primary : primary.withValues(alpha: 0.2),
            width: selected ? 1.6 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? primary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
