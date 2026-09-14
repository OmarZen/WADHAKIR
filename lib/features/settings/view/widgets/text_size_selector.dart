import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';

/// In-app text size control.
///
/// The app previously honoured nothing — a repo-wide search for `textScaler`
/// returned zero hits across 60k lines — so an elder user was told to go change
/// their phone's global display setting. PRODUCT.md names that audience
/// explicitly and calls outdoor legibility non-negotiable, and competitors put
/// "بخط كبير" in their app *titles* because users keep asking.
///
/// Presented as seven discrete steps rather than a free slider: the steps map
/// to sizes that were actually checked against the app's fixed-height cards,
/// and a discrete control is far easier to hit than a continuous one for the
/// very users who need it most.
class TextSizeSelector extends StatelessWidget {
  final AppSettingsModel settings;
  final SettingsCubit cubit;

  const TextSizeSelector({
    super.key,
    required this.settings,
    required this.cubit,
  });

  /// 0.9 … 1.6. Kept in lockstep with AppSettingsModel's clamp bounds.
  static const List<double> steps = [0.9, 1.0, 1.1, 1.25, 1.4, 1.5, 1.6];

  int get _index {
    var best = 0;
    var bestDelta = double.infinity;
    for (var i = 0; i < steps.length; i++) {
      final delta = (steps[i] - settings.textScale).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = i;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    final index = _index;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_size, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n?.translate('settings.text_size') ?? 'حجم الخط',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${(steps[index] * 100).round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: index.toDouble(),
            min: 0,
            max: (steps.length - 1).toDouble(),
            divisions: steps.length - 1,
            label: '${(steps[index] * 100).round()}%',
            onChanged: (v) => cubit.setTextScale(steps[v.round()]),
          ),
          // A live sample, so the choice is judged on real Arabic text at the
          // real size rather than on an abstract percentage. Deliberately NOT
          // wrapped in the app-wide scaler — it previews its own step.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: steps[index],
              maxScaleFactor: steps[index],
              child: Text(
                l10n?.translate('settings.text_size_sample') ??
                    'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
