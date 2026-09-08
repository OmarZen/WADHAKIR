import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';
import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_cubit.dart';
import 'package:wadhakir/features/salah_tracker/views/widgets/salah_status_ui.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';

/// Per-fard outstanding qada (make-up) debt with +/- controls. The − button
/// pays one down (قضيتها); + adds legacy debt.
class SalahMakeUpCard extends StatelessWidget {
  final SalahLogModel log;

  const SalahMakeUpCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: Radii.all(Radii.md),
        border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.md,
              Spacing.lg,
              Spacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n?.translate('salah_tracker.make_up_hint') ??
                        'الصلوات الفائتة التي عليك قضاؤها',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final slot in PrayerSlot.values)
            _MakeUpRow(slot: slot, count: log.makeUpFor(slot)),
          const SizedBox(height: Spacing.sm),
        ],
      ),
    );
  }
}

class _MakeUpRow extends StatelessWidget {
  final PrayerSlot slot;
  final int count;

  const _MakeUpRow({required this.slot, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cubit = context.read<SalahTrackerCubit>();
    final hasDebt = count > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              SalahStatusUi.slotLabel(context, slot),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: hasDebt ? null : cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          _RoundButton(
            icon: Icons.remove_rounded,
            enabled: hasDebt,
            onTap: () => cubit.makeUpOne(slot),
          ),
          SizedBox(
            width: 36,
            child: Center(
              child: Text(
                WirdFormat.toArabicDigits(count),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: hasDebt ? cs.error : cs.onSurface,
                ),
              ),
            ),
          ),
          _RoundButton(
            icon: Icons.add_rounded,
            enabled: true,
            onTap: () => cubit.adjustMakeUp(slot, 1),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: enabled
          ? cs.primary.withValues(alpha: 0.10)
          : cs.onSurface.withValues(alpha: 0.05),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        // 44×44 hit target — these +/- steppers are tapped repeatedly, so the
        // tap area must meet the WCAG / Material touch-target minimum.
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
