import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';
import 'package:wadhakir/features/pray_times/services/native_prayer_alarm_gateway.dart';
import 'package:wadhakir/features/pray_times/services/prayer_schedule_planner.dart';

/// Stands in for the Kotlin side. The real bridge is a `MethodChannel`, which
/// is exactly the kind of platform singleton the R1 extraction existed to keep
/// out of the scheduling path.
class _FakeBridge implements NativeAlarmBridge {
  final List<String> calls = [];
  final List<Map<String, Object?>> armed = [];
  bool available = true;

  @override
  Future<void> clear() async => calls.add('clear');

  @override
  Future<void> arm(Map<String, Object?> alarm) async {
    calls.add('arm:${alarm['id']}');
    armed.add(alarm);
  }

  @override
  Future<void> commit() async => calls.add('commit');

  @override
  Future<void> purge() async => calls.add('purge');

  @override
  Future<bool> isAvailable() async => available;
}

PlannedPrayerNotification _planned({
  PlannedPrayer prayer = PlannedPrayer.fajr,
  int dayIndex = 0,
  DateTime? prayerTime,
  Duration lead = Duration.zero,
  bool vibration = true,
}) {
  final at = prayerTime ?? DateTime(2026, 3, 14, 4, 41);
  return PlannedPrayerNotification(
    id: PrayerSchedulePlanner.idFor(prayer, dayIndex),
    prayer: prayer,
    day: DateTime(at.year, at.month, at.day),
    dayIndex: dayIndex,
    prayerTime: at,
    fireTime: at.subtract(lead),
    settings: PrayerNotificationSettings(
      enabled: true,
      timing: NotificationTiming.onTime,
      sound: NotificationSound.defaultSound,
      vibration: vibration,
    ),
  );
}

void main() {
  late _FakeBridge bridge;
  late NativePrayerAlarmGateway gateway;

  setUp(() {
    bridge = _FakeBridge();
    gateway = NativePrayerAlarmGateway(bridge);
  });

  test('the cancel sweep clears the native table wholesale', () async {
    // The plugin's id list is meaningless natively — the Kotlin side owns its
    // own table and drops all of it. Passing the ids through would invite a
    // second id space that has to be kept in sync with this one.
    await gateway.cancelIds(PrayerSchedulePlanner.cancellableIds);

    expect(bridge.calls, ['clear']);
  });

  test('every alarm crosses as absolute epoch millis', () async {
    // This is the C18 fix. The plugin path sends calendar components plus a
    // cached zone name and re-resolves them natively, so a DST shift or a
    // flight moves every armed alarm. An instant cannot be re-interpreted.
    final fajr = DateTime(2026, 3, 14, 4, 41);
    await gateway.arm(
      _planned(prayerTime: fajr, lead: const Duration(minutes: 10)),
    );

    final sent = bridge.armed.single;
    expect(
      sent['fireAtEpochMs'],
      fajr.subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
    );
    expect(sent.keys, isNot(contains('timeZone')));
  });

  test('the wire format carries everything Kotlin needs to render', () async {
    // Kotlin must never re-derive Arabic copy or a channel key: two renderers
    // drift, and a notification posted to a channel that was never created is
    // dropped by Android without a trace.
    await gateway.arm(
      _planned(prayer: PlannedPrayer.maghrib, dayIndex: 3),
      locationName: 'القاهرة',
    );

    final sent = bridge.armed.single;
    expect(sent['id'], PrayerSchedulePlanner.idFor(PlannedPrayer.maghrib, 3));
    expect(sent['prayerKey'], 'Maghrib');
    expect(sent['dayIndex'], 3);
    expect(
      sent['channelId'],
      isA<String>().having((s) => s.isNotEmpty, 'set', isTrue),
    );
    expect(sent['title'], contains('المغرب'));
    expect(sent['body'], contains('القاهرة'));
    expect(sent['vibrate'], isTrue);
    expect((sent['payload']! as Map)['type'], 'prayer');
  });

  test('vibration follows the per-prayer setting', () async {
    await gateway.arm(_planned(vibration: false));

    expect(bridge.armed.single['vibrate'], isFalse);
  });

  test('a sweep is a transaction: nothing applies until commit', () async {
    // The previous plan must stay armed until the new one is complete. A sweep
    // that dies partway — the app killed, the channel torn down mid-reschedule
    // — would otherwise leave the user with a cancelled schedule and no
    // replacement, which is silence rather than a late adhan.
    await gateway.cancelIds(PrayerSchedulePlanner.cancellableIds);
    await gateway.arm(_planned());
    await gateway.commit();

    expect(bridge.calls, ['clear', 'arm:100', 'commit']);
  });

  test('abandon is what actually takes back armed alarms', () async {
    // cancelIds only opens a transaction, so handing the schedule to another
    // gateway needs this. Without it the committed native plan keeps ringing
    // underneath the new owner's, and every adhan sounds twice.
    await gateway.abandon();

    expect(bridge.calls, ['purge']);
  });

  test(
    'a full native horizon stays inside ids no other feature owns',
    () async {
      // Sixty days pushes prayer ids well past the plugin path's 100..214. The
      // ranges that must stay clear are persistent 999, fasting 5001-5999,
      // wird 6001/6099 and azkar 7100+.
      final last = PrayerSchedulePlanner.idFor(
        PlannedPrayer.isha,
        PrayerSchedulePlanner.nativeHorizonDays - 1,
      );

      expect(last, lessThan(998));
    },
  );
}
