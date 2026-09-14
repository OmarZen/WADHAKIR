import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/daily_inspiration_item.dart';
import 'package:wadhakir/features/daily_inspiration/cubit/daily_inspiration_cubit.dart';
import 'package:wadhakir/features/daily_inspiration/cubit/daily_inspiration_state.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';

/// Home dashboard card showing today's ayah/dua/hadith, with quick actions to
/// share it or open the daily-inspiration settings.
class DailyInspirationCard extends StatelessWidget {
  const DailyInspirationCard({super.key});

  String _typeLabel(BuildContext context, String type) {
    final l10n = context.l10n;
    switch (type) {
      case 'dua':
        return l10n?.translate('daily_inspiration.type_dua') ?? 'دعاء';
      case 'hadith':
        return l10n?.translate('daily_inspiration.type_hadith') ?? 'حديث';
      case 'ayah':
      default:
        return l10n?.translate('daily_inspiration.type_ayah') ?? 'آية';
    }
  }

  void _share(BuildContext context, DailyInspirationItem item) {
    Navigator.of(context).pushNamed(
      AppConstants.shareRoute,
      arguments: SharePayload(
        headline: item.arabic,
        categoryLabel: _typeLabel(context, item.type),
        reference: item.reference.isEmpty ? null : item.reference,
        secondaryText: item.translation.isEmpty ? null : item.translation,
        variant: ShareCardVariant.passage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<DailyInspirationCubit, DailyInspirationState>(
      builder: (context, state) {
        final item = state.todayItem;
        if (!state.loaded || item == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.sm,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: Radii.all(Radii.lg),
              border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(Spacing.sm),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary.withValues(
                            alpha: isDark ? 0.22 : 0.12,
                          ),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: isDark
                              ? cs.onSurface.withValues(alpha: 0.85)
                              : cs.primary,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          l10n?.translate('daily_inspiration.card_title') ??
                              'آية وذِكر اليوم',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.ios_share_rounded, size: 20),
                        tooltip:
                            l10n?.translate('daily_inspiration.share') ??
                            'مشاركة',
                        onPressed: () => _share(context, item),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.tune_rounded, size: 20),
                        tooltip:
                            l10n?.translate(
                              'daily_inspiration.settings_title',
                            ) ??
                            'إعدادات التذكير',
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppConstants.dailyInspirationSettingsRoute),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    item.arabic,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'ScheherazadeNew',
                      height: 1.9,
                    ),
                  ),
                  if (item.reference.isNotEmpty) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(
                      item.reference,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
