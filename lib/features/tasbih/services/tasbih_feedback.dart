import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the tasbih can make the device do: vibrate, click, keep the screen on.
///
/// Behind an interface for two reasons.
///
/// **Platforms differ.** Android gets a native bridge (below), iOS gets what
/// Flutter offers, Windows gets nothing — a desktop has no vibrator, and every
/// mouse click already counts as input that keeps the display awake. The
/// `supports*` flags let the screen hide a switch the platform cannot honour,
/// rather than show one that silently does nothing.
///
/// **Tests.** `dart:io`'s `Platform` cannot be overridden in a test, so the
/// screen and cubit take an instance and tests hand them a fake that records
/// calls.
abstract class TasbihFeedback {
  const TasbihFeedback();

  /// The right implementation for the platform this build is running on.
  factory TasbihFeedback.forPlatform() {
    if (kIsWeb) return const NoopTasbihFeedback();
    if (Platform.isAndroid) return MethodChannelTasbihFeedback();
    if (Platform.isIOS) return const FallbackTasbihFeedback();
    return const NoopTasbihFeedback();
  }

  bool get supportsHaptics;
  bool get supportsSound;
  bool get supportsKeepScreenOn;

  /// Loads the click so the first one is not late. Idempotent.
  Future<void> prepare();

  /// One counted tasbiha.
  void tap({required bool vibrate, required bool sound});

  /// A round reached its target. Replaces [tap] for that count — never both,
  /// or the last bead of every round would buzz twice.
  void roundComplete({required bool vibrate, required bool sound});

  Future<void> setKeepScreenOn(bool on);

  /// Frees the sound. The screen calls it on dispose, after switching
  /// keep-screen-on off.
  Future<void> release();
}

/// Android: `TasbihFeedbackBridge.kt`.
///
/// Native rather than [HapticFeedback] / [SystemSound] because both of those
/// follow system switches the user may have turned off for other reasons:
/// "Touch feedback" silences [HapticFeedback] entirely, and "Touch sounds"
/// silences [SystemSound.click] — off by default on many phones. Either way
/// the tasbih's own switch would look broken. The bridge drives `Vibrator`
/// and a `SoundPool` directly, takes no audio focus (Quran or radio keep
/// playing under the click), and skips the click when the phone is on
/// silent or in a call.
class MethodChannelTasbihFeedback extends TasbihFeedback {
  MethodChannelTasbihFeedback([
    this._channel = const MethodChannel(channelName),
  ]);

  static const String channelName = 'com.bloom.wadhakir/tasbih_feedback';

  final MethodChannel _channel;

  @override
  bool get supportsHaptics => true;
  @override
  bool get supportsSound => true;
  @override
  bool get supportsKeepScreenOn => true;

  /// Never lets a missing or failing bridge reach the UI: a count must
  /// always land, with or without its buzz.
  Future<void> _call(String method, [Object? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // A build without the native side registered. Nothing to do.
    } on PlatformException catch (e) {
      debugPrint('TasbihFeedback.$method failed: ${e.message}');
    }
  }

  @override
  Future<void> prepare() => _call('prepare');

  @override
  void tap({required bool vibrate, required bool sound}) {
    if (vibrate) _call('tick');
    if (sound) _call('click');
  }

  @override
  void roundComplete({required bool vibrate, required bool sound}) {
    if (vibrate) _call('roundComplete');
    if (sound) _call('click');
  }

  @override
  Future<void> setKeepScreenOn(bool on) => _call('setKeepScreenOn', on);

  @override
  Future<void> release() => _call('release');
}

/// iOS: Flutter's own haptics and the system click. Keep-screen-on would need
/// a plugin (`UIApplication.isIdleTimerDisabled`), so the switch is hidden.
class FallbackTasbihFeedback extends TasbihFeedback {
  const FallbackTasbihFeedback();

  @override
  bool get supportsHaptics => true;
  @override
  bool get supportsSound => true;
  @override
  bool get supportsKeepScreenOn => false;

  @override
  Future<void> prepare() async {}

  @override
  void tap({required bool vibrate, required bool sound}) {
    if (vibrate) HapticFeedback.selectionClick();
    if (sound) SystemSound.play(SystemSoundType.click);
  }

  @override
  void roundComplete({required bool vibrate, required bool sound}) {
    if (vibrate) HapticFeedback.mediumImpact();
    if (sound) SystemSound.play(SystemSoundType.click);
  }

  @override
  Future<void> setKeepScreenOn(bool on) async {}

  @override
  Future<void> release() async {}
}

/// Desktop and web: counting only.
class NoopTasbihFeedback extends TasbihFeedback {
  const NoopTasbihFeedback();

  @override
  bool get supportsHaptics => false;
  @override
  bool get supportsSound => false;
  @override
  bool get supportsKeepScreenOn => false;

  @override
  Future<void> prepare() async {}

  @override
  void tap({required bool vibrate, required bool sound}) {}

  @override
  void roundComplete({required bool vibrate, required bool sound}) {}

  @override
  Future<void> setKeepScreenOn(bool on) async {}

  @override
  Future<void> release() async {}
}
