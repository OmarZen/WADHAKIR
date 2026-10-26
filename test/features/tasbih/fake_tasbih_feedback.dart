import 'package:wadhakir/features/tasbih/services/tasbih_feedback.dart';

/// Records every call, with switchable capabilities — the stand-in for a
/// platform a test cannot pretend to be.
class FakeTasbihFeedback extends TasbihFeedback {
  FakeTasbihFeedback({
    this.supportsHaptics = true,
    this.supportsSound = true,
    this.supportsKeepScreenOn = true,
  });

  @override
  final bool supportsHaptics;
  @override
  final bool supportsSound;
  @override
  final bool supportsKeepScreenOn;

  /// Each tap as `(vibrate, sound)`.
  final List<(bool, bool)> taps = [];
  final List<(bool, bool)> rounds = [];
  final List<bool> screenOn = [];
  int prepares = 0;
  int releases = 0;

  @override
  Future<void> prepare() async => prepares++;

  @override
  void tap({required bool vibrate, required bool sound}) =>
      taps.add((vibrate, sound));

  @override
  void roundComplete({required bool vibrate, required bool sound}) =>
      rounds.add((vibrate, sound));

  @override
  Future<void> setKeepScreenOn(bool on) async => screenOn.add(on);

  @override
  Future<void> release() async => releases++;
}
