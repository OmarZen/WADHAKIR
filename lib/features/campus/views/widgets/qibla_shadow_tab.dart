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

/// The Shadow tab: the qibla from a stick's shadow, no compass needed.
///
/// A vertical stick's shadow points away from the sun (sun azimuth + 180°).
/// The dial is drawn with that shadow at the top, so a user who turns the
/// phone until its small needle lies along the real shadow has the big arrow
/// pointing at the qibla. Works while the sun is 5°–80° high; outside that
/// it says why and offers the moon.
class QiblaShadowTab extends StatelessWidget {
  const QiblaShadowTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QiblaCubit, QiblaState>(
      buildWhen: (a, b) =>
          a.fix != b.fix ||
          a.sun != b.sun ||
          a.qiblaBearing != b.qiblaBearing ||
          a.distanceKm != b.distanceKm,
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
                child: _ShadowBody(
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

class _ShadowBody extends StatelessWidget {
  final QiblaState state;
  final double dialSize;

  const _ShadowBody({required this.state, required this.dialSize});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QiblaCubit>();
    final cs = Theme.of(context).colorScheme;
    final status = state.shadowStatus;
    final usable = status == QiblaShadowStatus.usable;
    final shadow = state.shadowAzimuth;
    final relative = state.qiblaFromShadow;
    final sun = state.sun;

    final ref = QiblaStrings.tr(context, 'qibla.shadow.ref', 'ظل العود');

    return Column(
      children: [
        const QiblaLocationLabel(),
        QiblaDial(
          size: dialSize,
          referenceBearing: shadow ?? 0,
          qiblaBearing: usable ? state.qiblaBearing : null,
          top: QiblaDialTop.shadowNeedle,
          answerArrow: true,
          muted: !usable,
        ),
        const SizedBox(height: Spacing.lg),
        if (usable && relative != null) ...[
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
          const SizedBox(height: Spacing.md),
        ],
        Text(
          QiblaStrings.tr(
            context,
            'qibla.shadow.instructions',
            'ضع عودًا قائمًا على الأرض في الشمس، ثم ضع الهاتف مستويًا وأدِره حتى يوازي المؤشرُ الصغير ظلَّ العود؛ عندها يشير السهم الكبير إلى القبلة.',
          ),
          textAlign: TextAlign.center,
          style: QiblaLook.body(
            context,
          ).copyWith(color: QiblaLook.muted(context)),
        ),
        const SizedBox(height: Spacing.md),
        if (sun != null)
          switch (status) {
            QiblaShadowStatus.usable => QiblaStatusChip(
              label: QiblaStrings.fill(
                QiblaStrings.tr(
                  context,
                  'qibla.shadow.sun_at',
                  'الشمس الآن في {dir} · ارتفاعها {n}°',
                ),
                {
                  'dir': QiblaFormat.compassPoint(context, sun.azimuth),
                  'n': sun.altitude.round(),
                },
              ),
              color: AppAccent.of(context),
              icon: Icons.wb_sunny_rounded,
            ),
            QiblaShadowStatus.sunTooLow => QiblaStatusChip(
              label: QiblaStrings.tr(
                context,
                'qibla.shadow.daytime_only',
                'تعمل نهارًا فقط، فالشمس الآن منخفضة أو تحت الأفق',
              ),
              color: QiblaLook.muted(context),
              icon: Icons.nights_stay_rounded,
            ),
            QiblaShadowStatus.sunTooHigh => QiblaStatusChip(
              label: QiblaStrings.tr(
                context,
                'qibla.shadow.too_high',
                'الشمس قريبة من سمت الرأس والظل قصير جدًا',
              ),
              color: QiblaLook.warning(context),
              icon: Icons.wb_sunny_rounded,
            ),
            QiblaShadowStatus.unavailable => const SizedBox.shrink(),
          },
        // Only when the sun is down: then the moon is the real alternative.
        // Shown on any "not usable" it also appeared before the first sun
        // position and at noon, and pressing it pins the moon as the user's
        // choice, so the Sun/Moon tab kept the moon all day.
        if (status == QiblaShadowStatus.sunTooLow &&
            state.availableTabs.contains(QiblaTab.celestial)) ...[
          const SizedBox(height: Spacing.md),
          FButton(
            variant: FButtonVariant.outline,
            mainAxisSize: MainAxisSize.min,
            onPress: () {
              cubit.selectBody(CelestialBody.moon);
              cubit.selectTab(QiblaTab.celestial);
            },
            child: QiblaButtonLabel(
              QiblaStrings.tr(context, 'qibla.shadow.try_moon', 'جرّب القمر'),
            ),
          ),
        ],
      ],
    );
  }
}
