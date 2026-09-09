import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wadhakir/features/pray_times/services/prayer_notification_content.dart';
import 'package:wadhakir/features/pray_times/services/prayer_schedule_planner.dart';
import 'package:wadhakir/features/pray_times/services/prayer_scheduler.dart';

/// The Android side of the native alarm bridge, as a Dart interface.
///
/// Exists so [NativePrayerAlarmGateway] can be unit-tested. A `MethodChannel`
/// is not fakeable in the way this needs — the point of the R1 extraction was
/// that the whole scheduling path is assertable without a device, and putting a
/// raw channel call in the gateway would have given that back.
abstract interface class NativeAlarmBridge {
  /// Opens a plan transaction and discards any half-built previous one.
  ///
  /// Nothing is cancelled yet. The scheduler always sweeps before it arms, so
  /// this means "a new plan is coming", and the alarms currently armed stay
  /// armed until [commit] replaces them. A sweep that dies partway therefore
  /// costs nothing — the old schedule is still live.
  Future<void> clear();

  /// Adds one fully-rendered alarm to the plan being built.
  ///
  /// Buffered, not applied. Persisting the ledger on each of three hundred
  /// calls would rewrite a growing JSON document three hundred times.
  Future<void> arm(Map<String, Object?> alarm);

  /// Applies the buffered plan: replaces the ledger, cancels what is no longer
  /// in it, and arms the near window.
  Future<void> commit();

  /// Cancels every alarm the native side has armed and empties its ledger.
  ///
  /// Used when handing the schedule to another owner. [clear] deliberately does
  /// not do this — it only opens a transaction.
  Future<void> purge();

  /// Whether this device has a working native alarm bridge.
  ///
  /// False on iOS, and false on an Android build where the platform side is
  /// missing — which is what makes an accidental half-migration fail loudly at
  /// startup instead of silently dropping every adhan.
  Future<bool> isAvailable();
}

/// [NativeAlarmBridge] over the real platform channel.
class MethodChannelAlarmBridge implements NativeAlarmBridge {
  static const MethodChannel channel = MethodChannel(
    'com.bloom.wadhakir/prayer_alarms',
  );

  const MethodChannelAlarmBridge();

  @override
  Future<void> clear() => channel.invokeMethod<void>('clear');

  @override
  Future<void> arm(Map<String, Object?> alarm) =>
      channel.invokeMethod<void>('arm', alarm);

  @override
  Future<void> commit() => channel.invokeMethod<void>('commit');

  @override
  Future<void> purge() => channel.invokeMethod<void>('purge');

  @override
  Future<bool> isAvailable() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await channel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

/// Arms prayer alarms through native `AlarmManager.setAlarmClock` instead of
/// `awesome_notifications`.
///
/// ## What moves and what does not
///
/// Nothing about *what* to schedule changes: [PrayerSchedulePlanner] still
/// decides, [PrayerNotificationContent] still renders, and this class is a
/// second implementation of [PrayerAlarmGateway]'s two methods. What changes is
/// who holds the table. The plugin arms only what the app told it about on its
/// last launch, which is why the adhan stops for anyone who leaves the app
/// closed for longer than the horizon (C1). The native side is handed a 60-day
/// plan, keeps it in its own storage, and re-arms itself from every alarm that
/// fires — so the chain survives without a Flutter engine ever running.
///
/// ## Absolute time
///
/// Every alarm crosses the channel as epoch milliseconds, never as a wall-clock
/// field set plus a timezone name. The plugin path caches a resolved zone
/// identifier and re-renders calendar components against it, which is what
/// makes a DST transition or a flight mis-fire the whole armed horizon (C18).
/// An instant has no such ambiguity.
class NativePrayerAlarmGateway
    implements PrayerAlarmGateway, BatchingPrayerAlarmGateway {
  final NativeAlarmBridge _bridge;

  const NativePrayerAlarmGateway(this._bridge);

  @override
  Future<void> cancelIds(Iterable<int> ids) => _bridge.clear();

  @override
  Future<void> commit() => _bridge.commit();

  @override
  Future<void> abandon() => _bridge.purge();

  @override
  Future<void> arm(PlannedPrayerNotification planned, {String? locationName}) {
    final content = PrayerNotificationContent.of(
      planned,
      locationName: locationName,
    );
    return _bridge.arm(payloadFor(planned, content));
  }

  /// The wire format, kept in one place so the Kotlin reader has exactly one
  /// contract to match.
  @visibleForTesting
  static Map<String, Object?> payloadFor(
    PlannedPrayerNotification planned,
    PrayerNotificationContent content,
  ) => {
    'id': planned.id,
    // The only time value on the wire. See the class doc.
    'fireAtEpochMs': planned.fireTime.millisecondsSinceEpoch,
    'prayerKey': planned.prayer.key,
    'dayIndex': planned.dayIndex,
    'channelId': content.channelKey,
    'groupKey': PrayerNotificationContent.groupKey,
    'title': content.title,
    'body': content.body,
    'vibrate': content.vibrate,
    // Only Android 7 reads this. From Oreo the channel owns the sound, and the
    // adhan channels already have the mp3 baked in — but this app's minSdk is
    // 24, and on 24/25 a notification with no sound of its own is silent. The
    // one thing this feature must never be.
    'soundRes': content.androidRawRes,
    'payload': content.payload,
  };
}
