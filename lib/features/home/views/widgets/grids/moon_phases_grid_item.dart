import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/moon_phases/data/moon_phase.dart';
import 'package:wadhakir/features/moon_phases/views/widgets/moon_painter.dart';
import 'package:wadhakir/features/moon_phases/views/widgets/moon_phase_labels.dart';

/// Home grid tile for the moon phases feature. Shows today's actual moon disc
/// with the current phase name underneath (instead of a generic icon), then
/// opens the moon-phases calendar on tap.
class MoonPhasesGridItem extends StatelessWidget {
  const MoonPhasesGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    final info = MoonPhaseCalculator.forDate(DateTime.now());

    return FTappable(
      onPress: () =>
          Navigator.of(context).pushNamed(AppConstants.moonPhasesRoute),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MoonDisc(
                size: 38,
                phaseFraction: info.phaseFraction,
                illumination: info.illumination,
              ),
              const SizedBox(height: 8),
              Text(
                MoonPhaseLabels.phaseName(info.phase, l10n),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
