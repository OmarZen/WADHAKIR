import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart'
    show kOverlayStyleLightIcons;
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/core/ui/islamic_decorations.dart';
import 'package:wadhakir/core/widgets/branded_header.dart';
import 'package:wadhakir/data/repositories/qibla_repository_impl.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/services/qibla_ar_camera_service.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_ar_tab.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_celestial_tab.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_compass_tab.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_location_label.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_map_tab.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_shadow_tab.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_tab_selector.dart';

/// اتجاه القبلة: five ways to find the qibla (fewer where the device cannot
/// do them), behind one header and one tab strip.
///
/// The screen owns the [QiblaCubit] for its lifetime and tells it when the
/// app goes to the background and comes back; the cubit decides what that
/// means for location and sensors (see its docs). Only the active tab is
/// mounted, so a tab's sensors, camera and map tiles exist only while it is
/// on screen.
class QiblaScreen extends StatefulWidget {
  /// Builds the cubit. Tests pass one over a fake repository; the app uses
  /// the platform repository.
  final QiblaCubit Function()? createCubit;

  /// Off in widget tests, which must not fetch map tiles.
  final bool enableTiles;

  /// The AR tab's camera, injectable as in [QiblaArCameraService].
  final Future<QiblaArCameraResult> Function() prepareCamera;

  const QiblaScreen({
    super.key,
    this.createCubit,
    this.enableTiles = true,
    this.prepareCamera = QiblaArCameraService.prepare,
  });

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with WidgetsBindingObserver {
  late final QiblaCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit =
        widget.createCubit?.call() ??
        QiblaCubit(repository: QiblaRepositoryImpl());
    unawaited(_cubit.start());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _cubit.onAppPaused();
      case AppLifecycleState.resumed:
        _cubit.onAppResumed();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // `inactive` is also a system dialog (the location prompt itself);
        // pausing there would drop the compass under every dialog.
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: _QiblaView(
        enableTiles: widget.enableTiles,
        prepareCamera: widget.prepareCamera,
      ),
    );
  }
}

class _QiblaView extends StatelessWidget {
  final bool enableTiles;
  final Future<QiblaArCameraResult> Function() prepareCamera;

  const _QiblaView({required this.enableTiles, required this.prepareCamera});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Light status-bar icons: the brand header (and the AR camera) under the
    // status bar are dark; inherited dark icons would vanish against them.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kOverlayStyleLightIcons,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            BlocBuilder<QiblaCubit, QiblaState>(
              buildWhen: (a, b) =>
                  a.fix != b.fix ||
                  a.placeName != b.placeName ||
                  a.locationStatus != b.locationStatus,
              builder: (context, state) {
                String? subtitle = qiblaPlaceText(context, state);
                if (subtitle == null &&
                    (state.locationStatus == QiblaLocationStatus.locating ||
                        state.locationStatus == QiblaLocationStatus.unknown)) {
                  subtitle = QiblaStrings.tr(
                    context,
                    'qibla.location.locating',
                    'جارٍ تحديد موقعك…',
                  );
                }
                return BrandedHeader(
                  title: QiblaStrings.tr(
                    context,
                    'qibla.title',
                    'اتجاه القبلة',
                  ),
                  subtitle: subtitle,
                );
              },
            ),
            Expanded(
              child: _TabArea(
                enableTiles: enableTiles,
                prepareCamera: prepareCamera,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The tab strip over the active tab. The strip floats over the tab rather
/// than sitting above it so the AR camera can run behind it; every other tab
/// is padded down by the strip's (computed) height.
class _TabArea extends StatelessWidget {
  final bool enableTiles;
  final Future<QiblaArCameraResult> Function() prepareCamera;

  const _TabArea({required this.enableTiles, required this.prepareCamera});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QiblaCubit>();
    final still = MediaQuery.disableAnimationsOf(context);

    return BlocBuilder<QiblaCubit, QiblaState>(
      buildWhen: (a, b) =>
          a.tab != b.tab ||
          a.availableTabs != b.availableTabs ||
          a.hasFix != b.hasFix,
      builder: (context, state) {
        final overCamera = state.tab == QiblaTab.ar && state.hasFix;
        return LayoutBuilder(
          builder: (context, constraints) {
            final stripHeight = QiblaTabSelector.heightFor(
              context,
              tabs: state.availableTabs,
              width: constraints.maxWidth,
            );
            final Widget body;
            if (state.tab == QiblaTab.ar) {
              body = QiblaArTab(
                stripHeight: stripHeight,
                prepareCamera: prepareCamera,
              );
            } else {
              body = MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.only(top: stripHeight),
                    child: _tabBody(state.tab),
                  ),
                ),
              );
            }

            return Stack(
              children: [
                if (!overCamera)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: IslamicPatternPainter(
                          color: AppAccent.of(context),
                          opacity: 0.05,
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: still ? Duration.zero : Motion.base,
                    switchInCurve: Motion.standard,
                    switchOutCurve: Motion.standard,
                    layoutBuilder: (current, previous) => Stack(
                      fit: StackFit.expand,
                      children: [...previous, ?current],
                    ),
                    child: KeyedSubtree(key: ValueKey(state.tab), child: body),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: QiblaTabSelector(
                    tabs: state.availableTabs,
                    selected: state.tab,
                    overCamera: overCamera,
                    onSelected: cubit.selectTab,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _tabBody(QiblaTab tab) {
    switch (tab) {
      case QiblaTab.compass:
        return const QiblaCompassTab();
      case QiblaTab.map:
        return QiblaMapTab(enableTiles: enableTiles);
      case QiblaTab.shadow:
        return const QiblaShadowTab();
      case QiblaTab.celestial:
        return const QiblaCelestialTab();
      case QiblaTab.ar:
        // Built by the caller, which knows the strip height.
        return const SizedBox.shrink();
    }
  }
}
