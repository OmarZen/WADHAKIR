import 'dart:ui' show FramePhase;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Whether the app has a surface on screen right now — what an offscreen
/// render (home_widget's `renderFlutterWidget`, `RenderRepaintBoundary.toImage`)
/// must have before it runs.
///
/// ## The crash it prevents
///
/// A snapshot taken while the engine has no surface does not fail quietly. In
/// Flutter 3.44 `DoMakeRasterSnapshot` then calls
/// `AndroidSurfaceGLImpeller::CreateSnapshotSurface`, which builds a throwaway
/// pbuffer surface and a whole new `AiksContext`; on Impeller's OpenGL ES
/// backend the `ContentContext` constructor's first buffer-to-texture upload
/// segfaults (`BlitCopyBufferToTextureCommandGLES::Encode`). That was the
/// app's top crash on Play, about 60% of crash events on 3.4.3, on phones where
/// Flutter skips Vulkan (MediaTek below Android 12, cheap 32-bit devices). The
/// glass prayer widgets triggered it: they are rendered from the prayer-times
/// load, which also runs with the app in the background (the GPS refresh lands
/// late) and with `main()` running headless for audio_service.
///
/// ## How it knows
///
/// Dart is never told about the surface. A [FrameTiming] is the proof: the
/// engine reports one only for a frame it rasterized onto a surface
/// (`Rasterizer::DoDraw` returns before `OnFrameRasterized` when there is
/// none). So the gate opens on the first timing while the app is in the
/// foreground, and closes the moment the lifecycle leaves `resumed`. Timings
/// are only listened for while the gate is closed, so an open gate costs
/// nothing per frame.
///
/// A narrow race remains: the app can leave in the milliseconds between the
/// check and the snapshot reaching the raster thread. Dart cannot close that;
/// everything else it can.
class OnscreenGate with WidgetsBindingObserver {
  OnscreenGate._() {
    WidgetsBinding.instance.addObserver(this);
    _listen();
  }

  static OnscreenGate? _instance;

  static OnscreenGate get instance => _instance ??= OnscreenGate._();

  /// Starts watching. [main] calls it right after the binding exists, so the
  /// gate has seen the first frame by the time anything asks.
  static void start() => instance;

  bool _onscreen = false;
  bool _listening = false;
  final List<VoidCallback> _waiting = [];

  /// Wall-clock microseconds of the last return to the foreground; 0 until the
  /// first one, so a cold start accepts any frame.
  int _foregroundSinceUs = 0;

  /// True while the app is in the foreground and has put a frame on screen
  /// since it got there.
  bool get isOnscreen => _onscreen;

  /// Runs [action] now if the app is on screen, otherwise the next time it is.
  void whenOnscreen(VoidCallback action) {
    if (_onscreen) {
      action();
      return;
    }
    _waiting.add(action);
    _listen();
  }

  /// `null` counts: it is the cold start before the first lifecycle message
  /// (a timing still proves the surface) or a headless engine (no timing ever
  /// arrives, so the gate stays shut).
  bool get _inForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  void _listen() {
    if (_listening || _onscreen || !_inForeground) return;
    _listening = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    // Something has to be rasterized for a timing to arrive.
    SchedulerBinding.instance.scheduleFrame();
  }

  void _stopListening() {
    if (!_listening) return;
    _listening = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    // Timings are batched, up to a second late in release. One that lands
    // after the app has left proves nothing about now, and nor does one for a
    // frame drawn before the app last came back: that was the old surface.
    if (!_inForeground) return;
    final drawnSinceReturn = timings.any(
      (t) =>
          t.timestampInMicroseconds(FramePhase.rasterFinishWallTime) >=
          _foregroundSinceUs,
    );
    if (!drawnSinceReturn) return;
    _onscreen = true;
    _stopListening();
    final actions = List.of(_waiting);
    _waiting.clear();
    for (final action in actions) {
      action();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foregroundSinceUs = DateTime.now().microsecondsSinceEpoch;
      _listen();
    } else {
      _onscreen = false;
      _stopListening();
    }
  }

  @visibleForTesting
  void debugReportTimings(List<FrameTiming> timings) => _onTimings(timings);

  @visibleForTesting
  bool get debugIsListening => _listening;

  @visibleForTesting
  static void resetForTest() {
    final gate = _instance;
    if (gate == null) return;
    gate._stopListening();
    WidgetsBinding.instance.removeObserver(gate);
    _instance = null;
  }
}
