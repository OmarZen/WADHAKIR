import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/zakat/services/zakat_calculator.dart';
import 'package:wadhakir/features/zakat/services/zakat_format.dart';

const Color _heroTop = Color(0xFF20497D); // Brand blue.
const Color _heroBottom = Color(0xFF356FB3);
const Color _dueGreen = Color(0xFF27AE60);

/// Eye-catching gradient banner that headlines the computed zakat: a big live
/// amount when due, or a friendly "below Nisab" state otherwise. Decorative
/// light-orbs give it a modern, glassy feel.
class ZakatHeroCard extends StatelessWidget {
  final ZakatResult result;
  final String currencyLabel;

  const ZakatHeroCard({
    super.key,
    required this.result,
    required this.currencyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cur = currencyLabel.trim();
    final isDue = result.isDue;

    String money(double v) {
      final amount = ZakatFormat.formatAmount(v, arabic: isArabic);
      return cur.isEmpty ? amount : '$amount $cur';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xs,
      ),
      child: ClipRRect(
        borderRadius: Radii.all(Radii.lg),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [_heroTop, _heroBottom],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x3320497D),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative light-orbs.
              Positioned(
                top: -34,
                right: -20,
                child: _orb(120, Colors.white.withValues(alpha: 0.10)),
              ),
              Positioned(
                bottom: -40,
                left: -16,
                child: _orb(110, Colors.white.withValues(alpha: 0.07)),
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(Spacing.sm),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                          child: const Icon(
                            Icons.volunteer_activism_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            l10n?.translate('zakat.zakat_amount') ??
                                'مقدار الزكاة',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _statusPill(context, isDue),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),
                    if (isDue)
                      Text(
                        money(result.zakatDue),
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      )
                    else
                      Text(
                        l10n?.translate('zakat.not_due') ??
                            'لم تبلغ النصاب — لا زكاة',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      isDue
                          ? (l10n?.translate('zakat.rate_note') ??
                                '٢٫٥٪ من صافي مالك الزكوي')
                          : (result.nisabValue > 0
                                ? '${l10n?.translate('zakat.nisab_threshold') ?? 'حد النصاب'}: ${money(result.nisabValue)}'
                                : (l10n?.translate('zakat.enter_price_hint') ??
                                      'أدخل سعر المعدن')),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(BuildContext context, bool isDue) {
    final l10n = context.l10n;
    final color = isDue ? _dueGreen : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDue
            ? _dueGreen.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.16),
        borderRadius: Radii.pillBorder,
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDue ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: Spacing.xs),
          Text(
            isDue
                ? (l10n?.translate('zakat.due_short') ?? 'واجبة')
                : (l10n?.translate('zakat.not_due_short') ?? 'دون النصاب'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
