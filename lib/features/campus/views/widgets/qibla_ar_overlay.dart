import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/views/qibla_look.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';
import 'package:wadhakir/features/campus/views/widgets/ar/prayer_rug_painter.dart';
import 'package:wadhakir/features/campus/views/widgets/ar/qibla_ar_result_panel.dart';
import 'package:wadhakir/features/campus/views/widgets/ar/qibla_ar_steady_step.dart';

/// What the rug layer needs, so it rebuilds only when the pose or the phase
/// changes (the tilt arrives at about 50 Hz).
@immutable
class _RugPose {
  final double? pitch;
  final double? roll;
  final double? yaw;
  final QiblaArPhase phase;

  const _RugPose(this.pitch, this.roll, this.yaw, this.phase);

  @override
  bool operator ==(Object other) =>
      other is _RugPose &&
      other.pitch == pitch &&
      other.roll == roll &&
      other.yaw == yaw &&
      other.phase == phase;

  @override
  int get hashCode => Object.hash(pitch, roll, yaw, phase);
}

/// The rug, painted in the camera preview's own frame. The AR screen builds
/// this INSIDE the `FittedBox(cover)` that scales the preview, so [frame] is
/// the unscaled preview size and the rug and the floor share one coordinate
/// system.
class QiblaArRugLayer extends StatelessWidget {
  final Size frame;

  const QiblaArRugLayer({super.key, required this.frame});

  @override
  Widget build(BuildContext context) {
    final color = QiblaLook.cameraAccent(context);
    return BlocSelector<QiblaCubit, QiblaState, _RugPose>(
      selector: (s) => _RugPose(s.pitch, s.roll, s.qiblaOffset, s.arPhase),
      builder: (context, pose) {
        final pitch = pose.pitch;
        final yaw = pose.yaw;
        if (pose.phase == QiblaArPhase.steadying ||
            pitch == null ||
            yaw == null) {
          return const SizedBox.shrink();
        }
        return RepaintBoundary(
          child: CustomPaint(
            size: frame,
            painter: PrayerRugPainter(
              pitchDegrees: pitch,
              rollDegrees: pose.roll ?? 0,
              yawDegrees: yaw,
              aligned: pose.phase == QiblaArPhase.aligned,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

/// What the HUD shows; the turn angle is rounded to whole degrees so the
/// text does not rebuild on every tremor.
@immutable
class _HudModel {
  final QiblaArPhase phase;
  final double progress;
  final ArSteadyHint hint;
  final int? turn;
  final double? bearing;
  final double? distanceKm;

  const _HudModel({
    required this.phase,
    required this.progress,
    required this.hint,
    required this.turn,
    required this.bearing,
    required this.distanceKm,
  });

  factory _HudModel.of(QiblaState s) {
    final offset = s.qiblaOffset;
    return _HudModel(
      phase: s.arPhase,
      progress: (s.arProgress * 50).round() / 50,
      hint: s.arHint,
      turn: offset?.round(),
      bearing: s.qiblaBearing,
      distanceKm: s.distanceKm,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _HudModel &&
      other.phase == phase &&
      other.progress == progress &&
      other.hint == hint &&
      other.turn == turn &&
      other.bearing == bearing &&
      other.distanceKm == distanceKm;

  @override
  int get hashCode =>
      Object.hash(phase, progress, hint, turn, bearing, distanceKm);
}

/// The screen-space layer over the camera: the honest note, the steady
/// step, the turn arrow and edge pill, or the result panel.
class QiblaArHud extends StatelessWidget {
  const QiblaArHud({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<QiblaCubit, QiblaState, _HudModel>(
      selector: _HudModel.of,
      builder: (context, hud) {
        final cubit = context.read<QiblaCubit>();
        final turn = hud.turn;
        final guiding = hud.phase == QiblaArPhase.guiding;

        final Widget bottom;
        switch (hud.phase) {
          case QiblaArPhase.steadying:
            bottom = QiblaArSteadyStep(progress: hud.progress, hint: hud.hint);
          case QiblaArPhase.guiding:
            bottom = _CameraPill(text: _turnText(context, turn));
          case QiblaArPhase.aligned:
            bottom = QiblaArResultPanel(
              bearing: hud.bearing,
              distanceKm: hud.distanceKm,
              onReset: cubit.resetAr,
            );
        }

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                children: [
                  _CameraPill(
                    text: QiblaStrings.tr(
                      context,
                      'qibla.ar.honest_note',
                      'السجادة دليل مرسوم وفق البوصلة، وليست مثبتة على الأرض.',
                    ),
                    small: true,
                  ),
                  const SizedBox(height: Spacing.md),
                  if (guiding && turn != null && turn != 0)
                    ExcludeSemantics(
                      child: SizedBox(
                        width: 140,
                        height: 56,
                        child: CustomPaint(
                          painter: QiblaTurnArrowPainter(
                            right: turn > 0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (hud.phase == QiblaArPhase.aligned && hud.bearing != null)
                    _QiblaPill(bearing: hud.bearing!),
                  // The panel sits at the bottom and scrolls rather than
                  // overflowing on a small phone at a large text size.
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: SingleChildScrollView(child: bottom),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (guiding && turn != null && turn != 0)
              Align(
                // Physical side, on purpose: «القبلة →» sits on the side the
                // user must turn toward, in Arabic and English alike.
                alignment: turn > 0
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: _EdgePill(right: turn > 0),
              ),
          ],
        );
      },
    );
  }

  static String _turnText(BuildContext context, int? turn) {
    if (turn == null) {
      return QiblaStrings.tr(
        context,
        'qibla.compass.waiting',
        'ننتظر قراءة البوصلة…',
      );
    }
    final template = turn >= 0
        ? QiblaStrings.tr(
            context,
            'qibla.ar.turn_right',
            'استدر {n}° لليمين حتى تتجه السجادة إلى القبلة',
          )
        : QiblaStrings.tr(
            context,
            'qibla.ar.turn_left',
            'استدر {n}° لليسار حتى تتجه السجادة إلى القبلة',
          );
    return QiblaStrings.fill(template, {'n': turn.abs()});
  }
}

/// White text on a flat dark pill: readable on any floor without a blur.
class _CameraPill extends StatelessWidget {
  final String text;
  final bool small;

  const _CameraPill({required this.text, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: small ? Spacing.xs + Spacing.xxs : Spacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: small ? 0.42 : 0.58),
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Almarai',
          fontSize: small ? 12 : 15,
          fontWeight: small ? FontWeight.w400 : FontWeight.w700,
          height: 1.4,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// «القبلة 136°» above the aligned rug.
class _QiblaPill extends StatelessWidget {
  final double bearing;

  const _QiblaPill({required this.bearing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: dark ? theme.cardColor : theme.colorScheme.surface,
        borderRadius: Radii.pillBorder,
      ),
      child: Text(
        QiblaStrings.fill(
          QiblaStrings.tr(context, 'qibla.ar.qibla_pill', 'القبلة {n}°'),
          {'n': QiblaFormat.wholeDegrees(bearing)},
        ),
        style: TextStyle(
          fontFamily: 'Almarai',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppAccent.of(context),
        ),
      ),
    );
  }
}

/// «القبلة →» at the screen edge the qibla lies beyond. Built as a
/// left-to-right row so the arrow stays on the outside edge in both
/// languages; an RTL row would put it on the wrong side and flip it.
class _EdgePill extends StatelessWidget {
  final bool right;

  const _EdgePill({required this.right});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = QiblaStrings.tr(context, 'qibla.ar.qibla_word', 'القبلة');
    final arrow = Icon(
      right ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
      color: Colors.white,
      size: 18,
    );
    final text = Text(
      label,
      style: const TextStyle(
        fontFamily: 'Almarai',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: Radii.pillBorder,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: right
                ? [text, const SizedBox(width: Spacing.xs), arrow]
                : [arrow, const SizedBox(width: Spacing.xs), text],
          ),
        ),
      ),
    );
  }
}
