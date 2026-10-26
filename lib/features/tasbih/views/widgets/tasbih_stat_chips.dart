import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/design/design_tokens.dart';

import '../../cubit/tasbih_cubit.dart';
import '../tasbih_look.dart';
import '../tasbih_strings.dart';

/// «الدورة 1» and «مجموع اليوم 35», in quiet neutral pills.
///
/// Today's numbers only: the all-time total lives in the settings sheet. A
/// running lifetime figure on the counting surface is the scoreboard
/// PRODUCT.md rules out.
class TasbihStatChips extends StatelessWidget {
  const TasbihStatChips({super.key, required this.look});

  final TasbihLook look;

  @override
  Widget build(BuildContext context) {
    final (round, today) = context.select<TasbihCubit, (int, int)>(
      (c) => (c.state.selected.roundsToday + 1, c.state.todayTotal),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        _Chip(
          label: TasbihStrings.tr(context, 'tasbih.round'),
          value: round,
          look: look,
        ),
        _Chip(
          label: TasbihStrings.tr(context, 'tasbih.today_total'),
          value: today,
          look: look,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value, required this.look});

  final String label;
  final int value;
  final TasbihLook look;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$label $value',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: look.neutral.withValues(alpha: 0.06),
          borderRadius: Radii.pillBorder,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: look.muted),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '$value',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: TasbihLook.uiFont,
                  color: look.ink,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Focus mode's single line in place of the chips: «اضغط في أي مكان للعدّ ·
/// الشاشة تبقى مضاءة». The second half only where the screen really is held
/// on.
class TasbihFocusHint extends StatelessWidget {
  const TasbihFocusHint({
    super.key,
    required this.look,
    required this.screenStaysOn,
  });

  final TasbihLook look;
  final bool screenStaysOn;

  @override
  Widget build(BuildContext context) {
    final anywhere = TasbihStrings.tr(context, 'tasbih.hint_anywhere');
    final text = screenStaysOn
        ? '$anywhere · ${TasbihStrings.tr(context, 'tasbih.hint_screen_on')}'
        : anywhere;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: Radii.pillBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.sm,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: look.muted),
        ),
      ),
    );
  }
}
