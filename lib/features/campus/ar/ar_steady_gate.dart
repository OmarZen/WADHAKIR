import 'dart:collection';
import 'dart:math' as math;

/// Why the AR steady step is not filling, for its one line of guidance.
enum ArSteadyHint {
  /// Filling (or already done).
  ok,

  /// The camera looks too far ahead; point it more at the floor.
  tiltDown,

  /// The camera looks almost straight down; raise it a little.
  tiltUp,

  /// In range but moving; hold still.
  holdStill,
}

/// The "point the camera at the floor and hold still" step before the rug
/// appears.
///
/// It is honest about what it measures: only that the phone has been held at
/// a floor-viewing angle without shaking for [fillDuration]. There is no plane
/// detection behind it. What it buys is that the rug is first drawn from a
/// settled tilt and heading instead of whatever the sensors said while the
/// user was still raising the phone.
///
/// Progress fills while the pitch is within [minPitchDegrees]..[maxPitchDegrees]
/// and has wobbled by less than [maxJitterDegrees] over the last
/// [jitterWindow]; otherwise it drains at the same rate. Once full it stays
/// full until [reset]: a guide that vanished every time a hand trembled would
/// be unusable.
///
/// Roll is deliberately not part of "steady". Near the 75° limit the phone's
/// x and y gravity components are small, so the roll computed from them is
/// noisy, and counting it would tell someone holding perfectly still to hold
/// still.
class ArSteadyGate {
  final Duration fillDuration;
  final double minPitchDegrees;
  final double maxPitchDegrees;
  final double maxJitterDegrees;
  final Duration jitterWindow;

  /// A gap longer than this between samples (a paused app, a dropped sensor)
  /// counts as this much, so one late sample cannot fill the gate at once.
  final Duration maxStep;

  ArSteadyGate({
    this.fillDuration = const Duration(milliseconds: 1500),
    this.minPitchDegrees = 30,
    this.maxPitchDegrees = 75,
    this.maxJitterDegrees = 1.5,
    this.jitterWindow = const Duration(milliseconds: 300),
    this.maxStep = const Duration(milliseconds: 200),
  });

  final Queue<_Sample> _window = Queue<_Sample>();
  DateTime? _lastAt;
  double _progress = 0;
  bool _complete = false;
  ArSteadyHint _hint = ArSteadyHint.ok;

  /// 0..1.
  double get progress => _complete ? 1 : _progress;

  /// The gate has filled at least once since the last [reset].
  bool get isSteady => _complete;

  ArSteadyHint get hint => _complete ? ArSteadyHint.ok : _hint;

  /// Feeds one (already low-passed) tilt sample taken at [at] and returns the
  /// new [progress].
  double add({required double pitchDegrees, required DateTime at}) {
    final last = _lastAt;
    _lastAt = at;
    _window.addLast(_Sample(at, pitchDegrees));
    while (_window.isNotEmpty &&
        at.difference(_window.first.at) > jitterWindow) {
      _window.removeFirst();
    }
    if (_complete) return 1;

    final inRange =
        pitchDegrees >= minPitchDegrees && pitchDegrees <= maxPitchDegrees;
    final steady = _jitter() < maxJitterDegrees;
    _hint = !inRange
        ? (pitchDegrees < minPitchDegrees
              ? ArSteadyHint.tiltDown
              : ArSteadyHint.tiltUp)
        : (steady ? ArSteadyHint.ok : ArSteadyHint.holdStill);

    if (last == null) return _progress;
    var step = at.difference(last);
    if (step.isNegative) step = Duration.zero;
    if (step > maxStep) step = maxStep;
    final delta = step.inMicroseconds / fillDuration.inMicroseconds;
    _progress = (inRange && steady ? _progress + delta : _progress - delta)
        .clamp(0.0, 1.0);
    if (_progress >= 1) _complete = true;
    return progress;
  }

  /// Back to empty, e.g. for «إعادة الضبط» or when the camera stops.
  void reset() {
    _window.clear();
    _lastAt = null;
    _progress = 0;
    _complete = false;
    _hint = ArSteadyHint.ok;
  }

  double _jitter() {
    if (_window.length < 2) return 0;
    var minPitch = double.infinity;
    var maxPitch = double.negativeInfinity;
    for (final s in _window) {
      minPitch = math.min(minPitch, s.pitch);
      maxPitch = math.max(maxPitch, s.pitch);
    }
    return maxPitch - minPitch;
  }
}

class _Sample {
  final DateTime at;
  final double pitch;

  const _Sample(this.at, this.pitch);
}
