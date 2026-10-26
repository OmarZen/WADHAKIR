import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/design/design_tokens.dart';

import '../../cubit/tasbih_cubit.dart';
import '../tasbih_look.dart';
import '../tasbih_strings.dart';
import 'tasbih_reset_dialog.dart';
import 'tasbih_settings_sheet.dart';

/// Settings · sound · vibration · reset, in one floating pill under the
/// counting surface.
///
/// The sound and vibration buttons are left out where the platform cannot do
/// them (desktop), rather than shown as switches that do nothing.
class TasbihActionPill extends StatelessWidget {
  const TasbihActionPill({super.key, required this.look});

  final TasbihLook look;

  Future<void> _confirmReset(BuildContext context) async {
    final cubit = context.read<TasbihCubit>();
    final state = cubit.state;
    final ok = await confirmTasbihReset(
      context,
      title: TasbihStrings.tr(context, 'tasbih.reset_title'),
      body: TasbihStrings.tr(context, 'tasbih.reset_body', {
        'count': state.selected.count,
        'dhikr': state.dhikr.text,
      }),
    );
    if (ok) cubit.resetCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TasbihCubit>();
    final feedback = cubit.feedback;
    final (
      sound,
      vibrate,
      clear,
    ) = context.select<TasbihCubit, (bool, bool, bool)>(
      (c) =>
          (c.state.prefs.sound, c.state.prefs.vibrate, c.state.selectedIsClear),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: look.surface,
        borderRadius: Radii.pillBorder,
        border: Border.all(color: look.neutral.withValues(alpha: 0.08)),
        boxShadow: look.focus
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PillButton(
              icon: Icons.tune_rounded,
              tooltip: TasbihStrings.tr(context, 'tasbih.settings'),
              look: look,
              onPressed: () => showTasbihSettingsSheet(context, cubit),
            ),
            if (feedback.supportsSound)
              _PillButton(
                icon: sound
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                tooltip: TasbihStrings.tr(context, 'tasbih.sound'),
                look: look,
                toggled: sound,
                onPressed: () => cubit.setSound(!sound),
              ),
            if (feedback.supportsHaptics)
              _PillButton(
                icon: vibrate
                    ? Icons.vibration_rounded
                    : Icons.mobile_off_rounded,
                tooltip: TasbihStrings.tr(context, 'tasbih.vibrate'),
                look: look,
                toggled: vibrate,
                onPressed: () => cubit.setVibrate(!vibrate),
              ),
            _PillButton(
              icon: Icons.restart_alt_rounded,
              tooltip: TasbihStrings.tr(context, 'tasbih.reset'),
              look: look,
              onPressed: clear ? null : () => _confirmReset(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.tooltip,
    required this.look,
    required this.onPressed,
    this.toggled,
  });

  final IconData icon;
  final String tooltip;
  final TasbihLook look;
  final VoidCallback? onPressed;

  /// Null for a plain action; true/false for a switch.
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final on = toggled ?? false;
    final enabled = onPressed != null;
    final color = !enabled
        ? look.neutral.withValues(alpha: 0.3)
        : on
        ? look.onSelected
        : look.muted;
    return Semantics(
      button: true,
      toggled: toggled,
      enabled: enabled,
      label: tooltip,
      excludeSemantics: true,
      onTap: onPressed,
      child: Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            onTap: onPressed,
            radius: 26,
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : Motion.fast,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? look.selectedTint : Colors.transparent,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
