import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/services/qibla_ar_camera_service.dart';
import 'package:wadhakir/features/campus/views/screens/qibla_ar_screen.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_ar_overlay.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_location_gate.dart';

/// The AR tab: [QiblaArScreen] embedded under the header, with the camera
/// running behind the (translucent) tab strip.
///
/// ## Insets
/// The tab sits below the branded header, which already paid for the status
/// bar, so the top padding the screen inherits is replaced (not added to)
/// by the strip's height: `MediaQuery.removePadding(removeTop)` plus
/// [stripHeight]. The AR screen's own `SafeArea`s then keep the safety
/// notice, the fallbacks and the guidance clear of the strip. The Families
/// policy requires that nothing covers the notice.
///
/// ## The cubit
/// Only this host talks to the cubit; the AR screen gets callbacks. The
/// camera going live calls `setArActive(true)`; switching tabs unmounts the
/// screen (releasing the camera) and the cubit stands AR down by itself in
/// `selectTab`, so nothing has to happen in a `dispose`.
class QiblaArTab extends StatelessWidget {
  final double stripHeight;
  final Future<QiblaArCameraResult> Function() prepareCamera;

  const QiblaArTab({
    super.key,
    required this.stripHeight,
    this.prepareCamera = QiblaArCameraService.prepare,
  });

  @override
  Widget build(BuildContext context) {
    final hasFix = context.select<QiblaCubit, bool>((c) => c.state.hasFix);
    final media = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Builder(
        builder: (context) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(top: stripHeight),
              viewPadding: mq.viewPadding.copyWith(top: stripHeight),
            ),
            child: hasFix
                ? _arScreen(context)
                : ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Padding(
                      padding: EdgeInsets.only(top: stripHeight),
                      child: const QiblaLocationGate(),
                    ),
                  ),
          );
        },
      ),
    );
    return media;
  }

  Widget _arScreen(BuildContext context) {
    final cubit = context.read<QiblaCubit>();
    return QiblaArScreen(
      embedded: true,
      prepareCamera: prepareCamera,
      onExit: () => cubit.selectTab(QiblaTab.compass),
      onArActiveChanged: cubit.setArActive,
      previewOverlayBuilder: (context, frame) => QiblaArRugLayer(frame: frame),
      overlayBuilder: (context) => const QiblaArHud(),
    );
  }
}
