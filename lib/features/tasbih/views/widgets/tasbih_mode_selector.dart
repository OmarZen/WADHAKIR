import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:wadhakir/core/design/design_tokens.dart';

import '../../cubit/tasbih_cubit.dart';
import '../../data/tasbih_models.dart';
import '../tasbih_look.dart';
import '../tasbih_strings.dart';

/// The four modes: الحبات / النقر / الحلقة / التركيز.
class TasbihModeSelector extends StatelessWidget {
  const TasbihModeSelector({super.key, required this.look});

  final TasbihLook look;

  static String labelKey(TasbihMode mode) => switch (mode) {
    TasbihMode.beads => 'tasbih.mode_beads',
    TasbihMode.tap => 'tasbih.mode_tap',
    TasbihMode.ring => 'tasbih.mode_ring',
    TasbihMode.focus => 'tasbih.mode_focus',
  };

  @override
  Widget build(BuildContext context) {
    final selected = context.select<TasbihCubit, TasbihMode>(
      (c) => c.state.mode,
    );

    final row = Row(
      children: [
        for (final mode in TasbihMode.values)
          Expanded(
            child: _ModeItem(
              mode: mode,
              selected: mode == selected,
              look: look,
              onPress: () => context.read<TasbihCubit>().setMode(mode),
            ),
          ),
      ],
    );

    if (!look.focus) return row;
    // Over the dark focus background the selector becomes a flat strip. No
    // BackdropFilter: the background is one flat colour, so a blur would
    // spend frames on nothing.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: Radii.all(Radii.lg),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: GlassTokens.borderOpacity(GlassIntensity.light),
          ),
          width: GlassTokens.borderWidth,
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(Spacing.xs), child: row),
    );
  }
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({
    required this.mode,
    required this.selected,
    required this.look,
    required this.onPress,
  });

  final TasbihMode mode;
  final bool selected;
  final TasbihLook look;
  final VoidCallback onPress;

  Widget _icon(Color color) {
    const size = 24.0;
    return switch (mode) {
      TasbihMode.beads => HugeIcon(
        icon: HugeIcons.strokeRoundedTasbih,
        color: color,
        size: size,
      ),
      TasbihMode.tap => Icon(Icons.touch_app_rounded, color: color, size: size),
      TasbihMode.ring => Icon(
        Icons.radio_button_unchecked_rounded,
        color: color,
        size: size,
      ),
      TasbihMode.focus => Icon(
        Icons.self_improvement_rounded,
        color: color,
        size: size,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? look.onSelected : look.muted;
    final label = TasbihStrings.tr(context, TasbihModeSelector.labelKey(mode));

    return Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: FTappable(
        onPress: onPress,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : Motion.fast,
          curve: Motion.standard,
          margin: const EdgeInsets.symmetric(horizontal: Spacing.xxs),
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xs,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? look.selectedTint : Colors.transparent,
            borderRadius: Radii.all(Radii.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _icon(color),
              const SizedBox(height: Spacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontFamily: TasbihLook.uiFont,
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
