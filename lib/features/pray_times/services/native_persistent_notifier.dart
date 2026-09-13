import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wadhakir/features/pray_times/services/native_prayer_alarm_gateway.dart';

/// Posts the ongoing "next prayer" card through the Kotlin renderer.
///
/// ## Why this is not on the plugin
///
/// The card's whole job is a live countdown, and `awesome_notifications`
/// exposes neither `setUsesChronometer` nor `setChronometerCountDown`. Without
/// them the only way to show a counter is to re-post the notification on a
/// timer — which is exactly what the app did: once a second, 86,400 times a
/// day, for the lifetime of the install. Handing `setWhen(theInstant)` and the
/// two chronometer flags to Android renders the same countdown with **zero**
/// posts, and keeps it running when the app is not.
///
/// R2 built a native notification path for the adhan, so the renderer already
/// existed. This is one more caller of it.
///
/// An interface, because the one thing worth asserting here — that nothing
/// schedules a repeating anything — is only assertable with a fake in its place.
abstract interface class NativePersistentNotifier {
  /// Shows or replaces the card.
  ///
  /// [titleFormat] carries a `{prayer}` token that Kotlin substitutes. The copy
  /// is authored here so the native side never becomes a second author of
  /// Arabic — it has to render this card again, on its own, every time an alarm
  /// fires and the "next" prayer changes.
  Future<void> show({
    required String titleFormat,
    required String prayerName,
    required String body,
    required DateTime prayerAt,
  });

  Future<void> hide();
}

/// [NativePersistentNotifier] over the real platform channel.
///
/// Shares the prayer-alarm channel rather than opening a second one: the
/// receiver that rolls this card forward is the same receiver that fires the
/// adhan, and the flag saying whether the card is wanted lives in the same
/// device-protected store as the alarm ledger.
class MethodChannelPersistentNotifier implements NativePersistentNotifier {
  const MethodChannelPersistentNotifier();

  @override
  Future<void> show({
    required String titleFormat,
    required String prayerName,
    required String body,
    required DateTime prayerAt,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await MethodChannelAlarmBridge.channel
          .invokeMethod<void>('showPersistent', <String, Object?>{
            'titleFormat': titleFormat,
            'prayerName': prayerName,
            'body': body,
            'prayerAtEpochMs': prayerAt.millisecondsSinceEpoch,
          });
    } on MissingPluginException {
      // A build without the native side. The card is a convenience; the
      // schedule it describes is unaffected.
    } on PlatformException catch (e) {
      debugPrint('Persistent notification refused by the platform: ${e.code}');
    }
  }

  @override
  Future<void> hide() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await MethodChannelAlarmBridge.channel.invokeMethod<void>(
        'hidePersistent',
      );
    } on MissingPluginException {
      // As above.
    } on PlatformException catch (e) {
      debugPrint('Could not hide the persistent notification: ${e.code}');
    }
  }
}
