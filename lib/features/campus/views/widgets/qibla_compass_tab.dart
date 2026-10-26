import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/views/qibla_look.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_calibration_card.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_dial.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_location_gate.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_location_label.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_status_chip.dart';

/// The Compass tab: the dial, the heading in large type, «استدر N° لليمين»,
/// the green «أنت الآن في اتجاه القبلة» or the accuracy chip, and the
/// calibration card when the magnetometer asks for it.
class QiblaCompassTab extends StatelessWidget {
  const QiblaCompassTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QiblaCubit, QiblaState>(
      buildWhen: (a, b) =>
          a.fix != b.fix ||
          a.qiblaBearing != b.qiblaBearing ||
          // With no fix only the location card is up; the compass runs
          // anyway and would rebuild it at sensor rate.
          (b.fix != null && a.heading != b.heading) ||
          a.headingStatus != b.headingStatus ||
          a.aligned != b.aligned ||
          a.accuracy != b.accuracy ||
          a.calibrationDismissed != b.calibrationDismissed ||
          a.distanceKm != b.distanceKm,
      builder: (context, state) {
        if (state.headingStatus == QiblaHeadingStatus.unavailable) {
          return const _CompassUnavailable();
        }
        if (state.fix == null) {
          return QiblaLocationGate(
            locatingHint: QiblaStrings.tr(
              context,
              'qibla.compass.locating_hint',
              'نحدد موقعك لحساب اتجاه القبلة بدقة',
            ),
          );
        }
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
                child: _CompassBody(
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

class _CompassBody extends StatelessWidget {
  final QiblaState state;
  final double dialSize;

  const _CompassBody({required this.state, required this.dialSize});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QiblaCubit>();
    final accent = AppAccent.of(context);
    final cs = Theme.of(context).colorScheme;

    if (state.atKaaba) {
      return Column(
        children: [
          const QiblaLocationLabel(),
          const SizedBox(height: Spacing.xl),
          HugeIcon(
            icon: HugeIcons.strokeRoundedKaaba01,
            color: accent,
            size: 72,
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            QiblaStrings.tr(
              context,
              'qibla.compass.at_kaaba',
              'أنت عند الكعبة المشرفة',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      );
    }

    final heading = state.heading;
    final bearing = state.qiblaBearing;
    final offset = state.qiblaOffset;
    final live = heading != null;
    final lowAccuracy = state.accuracy == CompassAccuracyLevel.low;

    // The number: where the phone points, or once facing the qibla, the
    // qibla's own bearing in the accent.
    final readout = state.aligned && bearing != null
        ? QiblaFormat.degrees(bearing)
        : (live ? QiblaFormat.degrees(heading) : '—');
    final readoutColor = state.aligned ? accent : cs.onSurface;

    final String guidance;
    if (!live) {
      guidance = QiblaStrings.tr(
        context,
        'qibla.compass.waiting',
        'ننتظر قراءة البوصلة…',
      );
    } else if (state.aligned && bearing != null) {
      guidance = QiblaStrings.fill(
        QiblaStrings.tr(
          context,
          'qibla.compass.from_here',
          'اتجاه القبلة من موقعك: {n}°',
        ),
        {'n': QiblaFormat.wholeDegrees(bearing)},
      );
    } else {
      guidance = _turnText(context, offset ?? 0);
    }

    return Column(
      children: [
        const QiblaLocationLabel(),
        Semantics(
          // Spoken in 5° steps, so a trembling hand does not make TalkBack
          // read a new number every half second.
          label: live ? _turnText(context, offset ?? 0, step: 5) : guidance,
          excludeSemantics: true,
          child: QiblaDial(
            size: dialSize,
            referenceBearing: heading ?? 0,
            qiblaBearing: bearing,
            aligned: state.aligned,
            muted: !live || lowAccuracy,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        ExcludeSemantics(
          child: Text(
            readout,
            textDirection: TextDirection.ltr,
            style: QiblaLook.readout(context, readoutColor),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          guidance,
          textAlign: TextAlign.center,
          style: QiblaLook.body(context),
        ),
        if (live && lowAccuracy && !state.showCalibration) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            QiblaStrings.tr(
              context,
              'qibla.compass.unreliable',
              'القراءة غير دقيقة حاليًا',
            ),
            textAlign: TextAlign.center,
            style: QiblaLook.body(
              context,
            ).copyWith(color: QiblaLook.warning(context), fontSize: 13),
          ),
        ],
        const SizedBox(height: Spacing.md),
        if (state.aligned)
          QiblaStatusChip.aligned(context)
        else
          QiblaStatusChip.accuracy(context, state.accuracy),
        if (state.showCalibration) ...[
          const SizedBox(height: Spacing.lg),
          QiblaCalibrationCard(
            level: state.accuracy,
            onSkip: cubit.dismissCalibration,
          ),
        ],
      ],
    );
  }

  /// «استدر 46° لليمين لتواجه القبلة», rounded to [step] degrees.
  static String _turnText(BuildContext context, double offset, {int step = 1}) {
    final n = ((offset.abs() / step).round() * step).clamp(0, 180);
    final template = offset >= 0
        ? QiblaStrings.tr(
            context,
            'qibla.compass.turn_right',
            'استدر {n}° لليمين لتواجه القبلة',
          )
        : QiblaStrings.tr(
            context,
            'qibla.compass.turn_left',
            'استدر {n}° لليسار لتواجه القبلة',
          );
    return QiblaStrings.fill(template, {'n': n});
  }
}

/// No compass on this phone: say so, and offer the two ways that need none.
class _CompassUnavailable extends StatelessWidget {
  const _CompassUnavailable();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QiblaCubit>();
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCompass01,
                  color: cs.onSurface.withValues(alpha: 0.4),
                  size: 64,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                QiblaStrings.tr(
                  context,
                  'qibla.compass.unavailable_title',
                  'البوصلة غير متاحة',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                QiblaStrings.tr(
                  context,
                  'qibla.compass.unavailable_body',
                  'لم نتمكن من قراءة مستشعر البوصلة في هذا الجهاز. ما زال بإمكانك معرفة القبلة من الخريطة أو من الشمس.',
                ),
                textAlign: TextAlign.center,
                style: QiblaLook.body(
                  context,
                ).copyWith(color: QiblaLook.muted(context)),
              ),
              const SizedBox(height: Spacing.xl),
              FButton(
                onPress: () => cubit.selectTab(QiblaTab.map),
                child: QiblaButtonLabel(
                  QiblaStrings.tr(
                    context,
                    'qibla.compass.use_map',
                    'استخدم الخريطة',
                  ),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              FButton(
                variant: FButtonVariant.outline,
                onPress: () => cubit.selectTab(QiblaTab.celestial),
                child: QiblaButtonLabel(
                  QiblaStrings.tr(
                    context,
                    'qibla.compass.use_sun',
                    'استخدم الشمس',
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
