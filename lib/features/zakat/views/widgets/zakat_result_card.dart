import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/zakat/services/zakat_calculator.dart';
import 'package:wadhakir/features/zakat/services/zakat_format.dart';

const Color _dueColor = Color(0xFF27AE60); // Green — zakat is due.

/// Summary card showing the zakat breakdown and the final amount due.
class ZakatResultCard extends StatelessWidget {
  final ZakatResult result;
  final String currencyLabel;

  /// When false the due/not-due badge + headline amount are omitted (they live
  /// in the gradient hero), leaving only the breakdown rows.
  final bool showHeadline;

  const ZakatResultCard({
    super.key,
    required this.result,
    required this.currencyLabel,
    this.showHeadline = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final accent = result.isDue ? _dueColor : cs.primary;
    final cur = currencyLabel.trim();

    String money(double v) {
      final amount = ZakatFormat.formatAmount(v, arabic: isArabic);
      return cur.isEmpty ? amount : '$amount $cur';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: Radii.all(Radii.lg),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHeadline) ...[
              // Due / not-due status badge.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    result.isDue
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: accent,
                    size: 20,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    result.isDue
                        ? (l10n?.translate('zakat.due') ?? 'الزكاة واجبة')
                        : (l10n?.translate('zakat.not_due') ??
                              'لم تبلغ النصاب — لا زكاة'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (result.isDue) ...[
                const SizedBox(height: Spacing.md),
                Text(
                  l10n?.translate('zakat.zakat_amount') ?? 'مقدار الزكاة',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  money(result.zakatDue),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: Spacing.lg),
              Divider(color: accent.withValues(alpha: 0.2), height: 1),
              const SizedBox(height: Spacing.md),
            ],
            _row(
              context,
              l10n?.translate('zakat.total_assets') ?? 'إجمالي الأموال',
              money(result.totalAssets),
            ),
            _row(
              context,
              l10n?.translate('zakat.liabilities') ?? 'الديون والالتزامات',
              '- ${money(result.totalLiabilities)}',
            ),
            _row(
              context,
              l10n?.translate('zakat.net_zakatable') ?? 'صافي المال الزكوي',
              money(result.netZakatable),
              emphasize: true,
            ),
            _row(
              context,
              l10n?.translate('zakat.nisab_threshold') ?? 'حد النصاب',
              result.nisabValue > 0
                  ? money(result.nisabValue)
                  : (l10n?.translate('zakat.enter_price_hint') ??
                        'أدخل سعر المعدن'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: emphasize ? FontWeight.bold : FontWeight.w400,
      color: emphasize ? cs.onSurface : cs.onSurface.withValues(alpha: 0.8),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          const SizedBox(width: Spacing.md),
          Text(value, textDirection: TextDirection.ltr, style: style),
        ],
      ),
    );
  }
}
