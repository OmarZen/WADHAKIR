import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/core/widgets/number_stepper_field.dart';

import '../../cubit/tasbih_cubit.dart';
import '../../data/tasbih_models.dart';
import '../tasbih_look.dart';
import '../tasbih_strings.dart';
import 'tasbih_reset_dialog.dart';

/// The tasbih's settings, in the app's bottom-sheet shape (see
/// `salah_status_sheet.dart`).
Future<void> showTasbihSettingsSheet(BuildContext context, TasbihCubit cubit) {
  final theme = Theme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: theme.colorScheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
    ),
    isScrollControlled: true,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const TasbihSettingsSheet()),
  );
}

class TasbihSettingsSheet extends StatefulWidget {
  const TasbihSettingsSheet({super.key});

  @override
  State<TasbihSettingsSheet> createState() => _TasbihSettingsSheetState();
}

class _TasbihSettingsSheetState extends State<TasbihSettingsSheet> {
  /// The «مخصص» chip was tapped, even if the target is still a preset.
  bool _customOpen = false;

  /// What the stepper holds. Applied only on «تطبيق»: typing "1000" passes
  /// through "1", "10" and "100" on the way, and each of those as a live
  /// target would reset the count.
  int? _draft;

  Future<void> _confirmLifetimeReset(int total) async {
    final cubit = context.read<TasbihCubit>();
    final ok = await confirmTasbihReset(
      context,
      title: TasbihStrings.tr(context, 'tasbih.reset_total_title'),
      body: TasbihStrings.tr(context, 'tasbih.reset_total_body', {'n': total}),
    );
    if (ok) cubit.resetLifetime();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cubit = context.read<TasbihCubit>();
    final feedback = cubit.feedback;
    final state = context.watch<TasbihCubit>().state;
    final prefs = state.prefs;
    final target = state.selected.target;
    final isPreset = TasbihTargets.presets.contains(target);
    final custom = _customOpen || !isPreset;
    final draft = _draft ?? target;
    final muted = cs.onSurface.withValues(alpha: 0.62);

    Widget toggle({
      required IconData icon,
      required String titleKey,
      String? subtitleKey,
      required bool value,
      required ValueChanged<bool> onChange,
    }) => FItem(
      prefix: Icon(icon),
      title: Text(TasbihStrings.tr(context, titleKey)),
      subtitle: subtitleKey == null
          ? null
          : Text(TasbihStrings.tr(context, subtitleKey)),
      suffix: FSwitch(value: value, onChange: onChange),
      onPress: () => onChange(!value),
    );

    final toggles = <Widget>[
      if (feedback.supportsHaptics)
        toggle(
          icon: Icons.vibration_rounded,
          titleKey: 'tasbih.vibrate',
          value: prefs.vibrate,
          onChange: cubit.setVibrate,
        ),
      if (feedback.supportsSound)
        toggle(
          icon: Icons.volume_up_rounded,
          titleKey: 'tasbih.sound',
          subtitleKey: 'tasbih.sound_hint',
          value: prefs.sound,
          onChange: cubit.setSound,
        ),
      toggle(
        // Mirrors itself in RTL, so it points the way the next dhikr lies.
        icon: Icons.arrow_forward_rounded,
        titleKey: 'tasbih.auto_advance',
        value: prefs.autoAdvance,
        onChange: cubit.setAutoAdvance,
      ),
      if (feedback.supportsKeepScreenOn)
        toggle(
          icon: Icons.brightness_high_rounded,
          titleKey: 'tasbih.keep_screen_on',
          subtitleKey: 'tasbih.keep_screen_on_hint',
          value: prefs.keepScreenOn,
          onChange: cubit.setKeepScreenOn,
        ),
    ];

    // The keyboard opens over a modal sheet rather than pushing it up, so the
    // sheet pads itself by the keyboard's height; otherwise «تطبيق» would sit
    // under the keys of the very keyboard it is waiting on.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.xs,
            Spacing.xl,
            Spacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                TasbihStrings.tr(context, 'tasbih.settings_title'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Spacing.xxs),
              Text(
                TasbihStrings.tr(context, 'tasbih.target_for', {
                  'dhikr': state.dhikr.text,
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: TasbihLook.uiFont,
                  color: muted,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  for (final preset in TasbihTargets.presets) ...[
                    Expanded(
                      child: _TargetChip(
                        label: '$preset',
                        selected: !custom && target == preset,
                        onTap: () {
                          setState(() {
                            _customOpen = false;
                            _draft = null;
                          });
                          cubit.setTarget(preset);
                        },
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                  ],
                  Expanded(
                    child: _TargetChip(
                      label: TasbihStrings.tr(context, 'tasbih.target_custom'),
                      selected: custom,
                      onTap: () => setState(() => _customOpen = true),
                    ),
                  ),
                ],
              ),
              if (custom) ...[
                const SizedBox(height: Spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: NumberStepperField(
                        value: draft,
                        min: TasbihTargets.min,
                        max: TasbihTargets.max,
                        onChanged: (v) => setState(() => _draft = v),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    FButton(
                      mainAxisSize: MainAxisSize.min,
                      onPress: draft == target
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              cubit.setTarget(draft);
                            },
                      child: Text(TasbihStrings.tr(context, 'tasbih.apply')),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: Spacing.lg),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: Radii.all(Radii.md),
                ),
                child: ClipRRect(
                  borderRadius: Radii.all(Radii.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < toggles.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        toggles[i],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TasbihStrings.tr(context, 'tasbih.lifetime_total'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: muted,
                          ),
                        ),
                        Text(
                          '${state.lifetimeTotal}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  FButton(
                    variant: FButtonVariant.ghost,
                    mainAxisSize: MainAxisSize.min,
                    onPress: state.lifetimeTotal == 0
                        ? null
                        : () => _confirmLifetimeReset(state.lifetimeTotal),
                    child: Text(
                      TasbihStrings.tr(context, 'tasbih.reset_total_action'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppAccent.of(context);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: FTappable(
        onPress: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xs,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: isDark ? 0.22 : 0.12)
                : cs.onSurface.withValues(alpha: 0.05),
            borderRadius: Radii.all(Radii.sm),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: TasbihLook.uiFont,
                color: selected ? accent : cs.onSurface,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
