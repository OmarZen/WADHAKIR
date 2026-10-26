import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/views/qibla_look.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_dial.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_location_gate.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_location_label.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_status_chip.dart';

/// The Sun/Moon tab: point the top of the phone at the sun (or the moon) and
/// the arrow shows the qibla. No compass needed; the positions come from the
/// cubit's 15-second tick.
class QiblaCelestialTab extends StatelessWidget {
  const QiblaCelestialTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QiblaCubit, QiblaState>(
      buildWhen: (a, b) =>
          a.fix != b.fix ||
          a.sun != b.sun ||
          a.moon != b.moon ||
          a.body != b.body ||
          a.moonNight != b.moonNight ||
          a.moonIllumination != b.moonIllumination ||
          a.qiblaBearing != b.qiblaBearing,
      builder: (context, state) {
        if (state.fix == null) return const QiblaLocationGate();
        return LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.lg,
              Spacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _CelestialBody(
                  state: state,
                  dialSize: QiblaDial.sizeFor(
                    constraints.maxWidth,
                    maxHeight: constraints.maxHeight,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CelestialBody extends StatelessWidget {
  final QiblaState state;
  final double dialSize;

  const _CelestialBody({required this.state, required this.dialSize});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QiblaCubit>();
    final cs = Theme.of(context).colorScheme;
    final isSun = state.body == CelestialBody.sun;
    final position = state.selectedBodyPosition;
    final visible = position != null && position.isAboveHorizon;
    final relative = state.qiblaFromBody;
    final ref = isSun
        ? QiblaStrings.tr(context, 'qibla.celestial.sun_ref', 'الشمس')
        : QiblaStrings.tr(context, 'qibla.celestial.moon_ref', 'القمر');

    return Column(
      children: [
        const QiblaLocationLabel(),
        _BodySwitch(selected: state.body, onChanged: cubit.selectBody),
        const SizedBox(height: Spacing.lg),
        QiblaDial(
          size: dialSize,
          referenceBearing: position?.azimuth ?? 0,
          qiblaBearing: visible ? state.qiblaBearing : null,
          top: isSun ? QiblaDialTop.sun : QiblaDialTop.moon,
          answerArrow: true,
          muted: !visible,
        ),
        const SizedBox(height: Spacing.lg),
        if (visible && relative != null) ...[
          ExcludeSemantics(
            child: Text(
              QiblaFormat.degrees(relative.abs()),
              textDirection: TextDirection.ltr,
              style: QiblaLook.readout(context, cs.onSurface),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            QiblaFormat.relative(context, relative, ref),
            textAlign: TextAlign.center,
            style: QiblaLook.body(
              context,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            isSun
                ? QiblaStrings.tr(
                    context,
                    'qibla.celestial.aim_sun',
                    'وجّه علامة الشمس نحو الشمس، ثم اتبع السهم إلى القبلة',
                  )
                : QiblaStrings.tr(
                    context,
                    'qibla.celestial.aim_moon',
                    'وجّه علامة القمر نحو القمر، ثم اتبع السهم إلى القبلة',
                  ),
            textAlign: TextAlign.center,
            style: QiblaLook.body(
              context,
            ).copyWith(color: QiblaLook.muted(context)),
          ),
          const SizedBox(height: Spacing.md),
        ],
        if (position != null) _statusChip(context, position, isSun, visible),
        if (!isSun && visible && state.moonFaint) ...[
          const SizedBox(height: Spacing.sm),
          QiblaStatusChip(
            label: QiblaStrings.tr(
              context,
              'qibla.celestial.moon_faint',
              'الهلال رفيع وقد لا يُرى الآن',
            ),
            color: QiblaLook.warning(context),
            icon: Icons.info_outline_rounded,
          ),
        ],
        if (isSun) ...[
          const SizedBox(height: Spacing.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_off_rounded,
                size: 16,
                color: QiblaLook.muted(context),
              ),
              const SizedBox(width: Spacing.xs + Spacing.xxs),
              Flexible(
                child: Text(
                  QiblaStrings.tr(
                    context,
                    'qibla.celestial.eye_safety',
                    'لا تحدّق في الشمس مباشرة',
                  ),
                  style: QiblaLook.body(
                    context,
                  ).copyWith(color: QiblaLook.muted(context), fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _statusChip(
    BuildContext context,
    HorizontalPosition position,
    bool isSun,
    bool visible,
  ) {
    final altitude = position.altitude.round();
    if (isSun) {
      return visible
          ? QiblaStatusChip(
              label: QiblaStrings.fill(
                QiblaStrings.tr(
                  context,
                  'qibla.celestial.sun_visible',
                  'الشمس ظاهرة · ارتفاعها {n}°',
                ),
                {'n': altitude},
              ),
              color: QiblaLook.success(context),
            )
          : QiblaStatusChip(
              label: QiblaStrings.tr(
                context,
                'qibla.celestial.sun_below',
                'الشمس تحت الأفق الآن',
              ),
              color: QiblaLook.muted(context),
            );
    }
    if (!visible) {
      return QiblaStatusChip(
        label: QiblaStrings.tr(
          context,
          'qibla.celestial.moon_below',
          'القمر تحت الأفق الآن',
        ),
        color: QiblaLook.muted(context),
      );
    }
    final night = state.moonNight;
    return QiblaStatusChip(
      label: night == null
          ? QiblaStrings.fill(
              QiblaStrings.tr(
                context,
                'qibla.celestial.moon_visible_plain',
                'القمر ظاهر · ارتفاعه {n}°',
              ),
              {'n': altitude},
            )
          : QiblaStrings.fill(
              QiblaStrings.tr(
                context,
                'qibla.celestial.moon_visible',
                'القمر ظاهر · ليلة {night} من الشهر · ارتفاعه {n}°',
              ),
              {'night': night, 'n': altitude},
            ),
      color: QiblaLook.success(context),
    );
  }
}

/// الشمس | القمر: a two-segment switch, the chosen side lifted onto the
/// surface in the brand colour.
class _BodySwitch extends StatelessWidget {
  final CelestialBody selected;
  final ValueChanged<CelestialBody> onChanged;

  const _BodySwitch({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.xs),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.06),
        borderRadius: Radii.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final body in CelestialBody.values)
            Flexible(
              child: _Segment(
                label: body == CelestialBody.sun
                    ? QiblaStrings.tr(context, 'qibla.celestial.sun', 'الشمس')
                    : QiblaStrings.tr(context, 'qibla.celestial.moon', 'القمر'),
                selected: body == selected,
                onPress: () => onChanged(body),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPress;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Semantics(
      selected: selected,
      child: FTappable(
        onPress: onPress,
        selected: selected,
        semanticsLabel: label,
        excludeSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 72),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? (dark ? theme.cardColor : cs.surface)
                : Colors.transparent,
            borderRadius: Radii.pillBorder,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          // Shrinks rather than wrapping: a two-line segment would break the
          // pill.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected
                    ? AppAccent.of(context)
                    : cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
