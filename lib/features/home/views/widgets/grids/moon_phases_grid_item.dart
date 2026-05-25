import 'package:flutter/material.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/features/moon_phases/data/moon_phase.dart';
import 'package:wadhakir/features/moon_phases/views/widgets/moon_painter.dart';
import 'package:wadhakir/features/moon_phases/views/widgets/moon_phase_labels.dart';

/// Home grid tile that opens the moon phases calendar. The tile itself
/// previews today's moon phase so users get a glanceable indicator of
/// where we are in the lunar cycle — useful for spotting Hilal nights.
class MoonPhasesGridItem extends StatelessWidget {
  const MoonPhasesGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = PlatformUtils.isDesktop;

    final padding = isDesktop ? 16.0 : 12.0;
    final verticalPadding = isDesktop ? 12.0 : 10.0;
    final iconSize = isDesktop ? 38.0 : 34.0;
    final spacing = isDesktop ? 12.0 : 10.0;

    final today = MoonPhaseCalculator.forDate(DateTime.now());

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () =>
            Navigator.of(context).pushNamed(AppConstants.moonPhasesRoute),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Live moon disc as the leading visual — far more evocative
              // than a generic icon, and shifts shape day by day. The
              // backplate uses the app's primary blue so the tile reads as
              // part of the wider design system instead of an off-theme
              // black inset.
              Container(
                width: iconSize + 12,
                height: iconSize + 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.78),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: MoonDisc(
                  size: iconSize,
                  phaseFraction: today.phaseFraction,
                  illumination: today.illumination,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n?.translate('home.moon_phases') ?? 'أطوار القمر',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: isDesktop ? 16 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MoonPhaseLabels.phaseName(today.phase, l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
