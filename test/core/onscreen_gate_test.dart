import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/app/onscreen_gate.dart';

/// What the engine reports after rasterizing a frame onto a surface. Only the
/// raster-finish wall time matters to the gate; arriving at all is the signal.
List<FrameTiming> _frameDrawnAt(int wallTimeUs) => [
  FrameTiming(
    vsyncStart: 0,
    buildStart: 0,
    buildFinish: 0,
    rasterStart: 0,
    rasterFinish: 0,
    rasterFinishWallTime: wallTimeUs,
  ),
];

List<FrameTiming> _frameDrawnNow() =>
    _frameDrawnAt(DateTime.now().microsecondsSinceEpoch);

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  void lifecycle(AppLifecycleState state) =>
      binding.handleAppLifecycleStateChanged(state);

  void leave() {
    lifecycle(AppLifecycleState.inactive);
    lifecycle(AppLifecycleState.hidden);
    lifecycle(AppLifecycleState.paused);
  }

  void comeBack() {
    lifecycle(AppLifecycleState.hidden);
    lifecycle(AppLifecycleState.inactive);
    lifecycle(AppLifecycleState.resumed);
  }

  setUp(() {
    lifecycle(AppLifecycleState.resumed);
    OnscreenGate.resetForTest();
  });

  tearDown(() {
    OnscreenGate.resetForTest();
    lifecycle(AppLifecycleState.resumed);
  });

  test(
    'stays shut until a frame reaches the screen, then runs what waited',
    () {
      final gate = OnscreenGate.instance;
      var ran = 0;
      gate.whenOnscreen(() => ran++);

      expect(gate.isOnscreen, isFalse);
      expect(ran, 0);

      gate.debugReportTimings(_frameDrawnNow());

      expect(gate.isOnscreen, isTrue);
      expect(ran, 1);

      // Nothing runs twice.
      gate.debugReportTimings(_frameDrawnNow());
      expect(ran, 1);
    },
  );

  test('runs at once when the app is already on screen', () {
    final gate = OnscreenGate.instance..debugReportTimings(_frameDrawnNow());
    var ran = 0;

    gate.whenOnscreen(() => ran++);

    expect(ran, 1);
  });

  test(
    'leaving the foreground shuts it, and a late timing does not reopen it',
    () {
      final gate = OnscreenGate.instance..debugReportTimings(_frameDrawnNow());
      expect(gate.isOnscreen, isTrue);

      leave();
      expect(gate.isOnscreen, isFalse);

      var ran = 0;
      gate.whenOnscreen(() => ran++);

      // Timings are batched and can land after the app has gone; that frame
      // says nothing about whether there is a surface now.
      gate.debugReportTimings(_frameDrawnNow());
      expect(gate.isOnscreen, isFalse);
      expect(ran, 0);

      // Back in the foreground, the surface may not exist yet either...
      comeBack();
      expect(gate.isOnscreen, isFalse);
      expect(ran, 0);

      // ...until a frame has actually been rasterized onto it.
      gate.debugReportTimings(_frameDrawnNow());
      expect(gate.isOnscreen, isTrue);
      expect(ran, 1);
    },
  );

  test('a frame drawn before the app last came back does not open it', () {
    final gate = OnscreenGate.instance;
    // Drawn on the surface the app had before a quick leave-and-return; its
    // batch is delivered after the return, before the new surface exists.
    final beforeLeaving = DateTime.now().microsecondsSinceEpoch - 1;
    leave();
    comeBack();

    gate.debugReportTimings(_frameDrawnAt(beforeLeaving));
    expect(gate.isOnscreen, isFalse);

    gate.debugReportTimings(_frameDrawnNow());
    expect(gate.isOnscreen, isTrue);
  });

  test('inactive alone also shuts it', () {
    final gate = OnscreenGate.instance..debugReportTimings(_frameDrawnNow());

    lifecycle(AppLifecycleState.inactive);

    expect(gate.isOnscreen, isFalse);
  });

  test('listens for timings only while shut and in the foreground', () {
    final gate = OnscreenGate.instance;
    expect(gate.debugIsListening, isTrue);

    gate.debugReportTimings(_frameDrawnNow());
    expect(gate.debugIsListening, isFalse);

    lifecycle(AppLifecycleState.inactive);
    expect(gate.debugIsListening, isFalse);

    lifecycle(AppLifecycleState.resumed);
    expect(gate.debugIsListening, isTrue);
  });
}
