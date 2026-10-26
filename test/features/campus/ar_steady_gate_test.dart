import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/features/campus/ar/ar_steady_gate.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 25, 12);

  /// Feeds [pitch] (a constant or a function of the sample index) every
  /// [step] for [duration], starting [offset] after t0.
  double feed(
    ArSteadyGate gate, {
    required double Function(int i) pitch,
    required Duration duration,
    Duration offset = Duration.zero,
    Duration step = const Duration(milliseconds: 20),
  }) {
    var progress = gate.progress;
    final n = duration.inMicroseconds ~/ step.inMicroseconds;
    for (var i = 0; i <= n; i++) {
      progress = gate.add(
        pitchDegrees: pitch(i),
        at: t0.add(offset + step * i),
      );
    }
    return progress;
  }

  test('fills over 1.5 s while held still at a floor angle', () {
    final gate = ArSteadyGate();
    final early = feed(
      gate,
      pitch: (_) => 45,
      duration: const Duration(milliseconds: 1400),
    );
    expect(early, closeTo(1400 / 1500, 0.02));
    expect(gate.isSteady, isFalse);
    expect(gate.hint, ArSteadyHint.ok);

    feed(
      gate,
      pitch: (_) => 45,
      duration: const Duration(milliseconds: 200),
      offset: const Duration(milliseconds: 1420),
    );
    expect(gate.progress, 1);
    expect(gate.isSteady, isTrue);
  });

  test('looking too far ahead does not fill and says tilt down', () {
    final gate = ArSteadyGate();
    expect(
      feed(gate, pitch: (_) => 20, duration: const Duration(seconds: 2)),
      0,
    );
    expect(gate.hint, ArSteadyHint.tiltDown);
  });

  test('looking almost straight down does not fill and says tilt up', () {
    final gate = ArSteadyGate();
    expect(
      feed(gate, pitch: (_) => 80, duration: const Duration(seconds: 2)),
      0,
    );
    expect(gate.hint, ArSteadyHint.tiltUp);
  });

  test('the 30° and 75° limits themselves count as in range', () {
    for (final pitch in [30.0, 75.0]) {
      final gate = ArSteadyGate();
      feed(gate, pitch: (_) => pitch, duration: const Duration(seconds: 2));
      expect(gate.isSteady, isTrue, reason: '$pitch°');
    }
  });

  test('a shaking phone does not fill and says hold still', () {
    final gate = ArSteadyGate();
    final progress = feed(
      gate,
      pitch: (i) => i.isEven ? 45 : 47,
      duration: const Duration(seconds: 2),
    );
    expect(progress, 0);
    expect(gate.hint, ArSteadyHint.holdStill);
  });

  test('a slow drift under 1.5° per 300 ms still fills', () {
    final gate = ArSteadyGate();
    // 3°/s is 0.9° over the window.
    feed(
      gate,
      pitch: (i) => 40 + i * 0.06,
      duration: const Duration(seconds: 2),
    );
    expect(gate.isSteady, isTrue);
  });

  test('progress drains when the phone leaves the range', () {
    final gate = ArSteadyGate();
    final half = feed(
      gate,
      pitch: (_) => 45,
      duration: const Duration(milliseconds: 750),
    );
    expect(half, closeTo(0.5, 0.02));
    final drained = feed(
      gate,
      pitch: (_) => 10,
      duration: const Duration(milliseconds: 300),
      offset: const Duration(milliseconds: 770),
    );
    expect(drained, lessThan(half));
    expect(drained, closeTo(0.5 - 320 / 1500, 0.03));
  });

  test('once full it stays full until reset', () {
    final gate = ArSteadyGate();
    feed(gate, pitch: (_) => 45, duration: const Duration(seconds: 2));
    expect(gate.isSteady, isTrue);
    feed(
      gate,
      pitch: (_) => 5,
      duration: const Duration(seconds: 1),
      offset: const Duration(seconds: 3),
    );
    expect(gate.progress, 1);
    expect(gate.hint, ArSteadyHint.ok);

    gate.reset();
    expect(gate.progress, 0);
    expect(gate.isSteady, isFalse);
  });

  test('one late sample after a gap cannot fill the gate at once', () {
    final gate = ArSteadyGate()
      ..add(pitchDegrees: 45, at: t0)
      ..add(pitchDegrees: 45, at: t0.add(const Duration(seconds: 10)));
    expect(gate.progress, closeTo(200 / 1500, 1e-6));
  });
}
