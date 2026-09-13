import 'package:adhan_dart/adhan_dart.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/utils/calculation_method_mapper.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/features/pray_times/services/native_persistent_notifier.dart';
import 'package:wadhakir/features/pray_times/services/persistent_notification_manager.dart';

/// Stands in for the Kotlin renderer, and counts.
///
/// The count is the whole point of these tests. This card used to be re-posted
/// by `Timer.periodic(Duration(seconds: 1))` — 86,400 platform round-trips a
/// day, forever — and the fix is that Android renders the countdown itself.
/// The only way to assert "no timer" is to let time pass and find nothing new.
class _FakeNotifier implements NativePersistentNotifier {
  final List<Map<String, Object?>> shown = [];
  int hides = 0;

  @override
  Future<void> show({
    required String titleFormat,
    required String prayerName,
    required String body,
    required DateTime prayerAt,
  }) async {
    shown.add({
      'titleFormat': titleFormat,
      'prayerName': prayerName,
      'body': body,
      'prayerAt': prayerAt,
    });
  }

  @override
  Future<void> hide() async => hides++;
}

PrayerTimesModel _times(DateTime day) {
  DateTime at(int hour, int minute) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  return PrayerTimesModel(
    fajr: at(4, 41),
    sunrise: at(6, 5),
    dhuhr: at(11, 58),
    asr: at(15, 22),
    maghrib: at(17, 51),
    isha: at(19, 14),
    date: DateTime(day.year, day.month, day.day),
    calculationParameters: CalculationMethodMapper.getParameters(
      'muslim_world_league',
    ),
    coordinates: const Coordinates(30.0444, 31.2357),
    middleOfTheNight: at(23, 30),
    lastThirdOfTheNight: at(1, 20),
  );
}

void main() {
  late _FakeNotifier notifier;
  late PersistentNotificationManager manager;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    notifier = _FakeNotifier();
    manager = PersistentNotificationManager.forTesting(notifier: notifier);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('no periodic work', () {
    test('starting posts exactly once', () async {
      await manager.start(prayerTimes: _times(DateTime.now()));

      expect(notifier.shown, hasLength(1));
    });

    test('a full day passes and nothing is re-posted', () {
      // The regression guard for roadmap #13. If a Timer.periodic ever comes
      // back here, this is what catches it: 24 hours of fake time used to be
      // 86,400 posts.
      fakeAsync((async) {
        manager.start(prayerTimes: _times(DateTime.now()));
        async.flushMicrotasks();
        expect(notifier.shown, hasLength(1));

        async.elapse(const Duration(days: 1));
        async.flushMicrotasks();

        expect(notifier.shown, hasLength(1));
        expect(async.periodicTimerCount, 0);
        expect(async.nonPeriodicTimerCount, 0);
      });
    });

    test('stopping leaves no timer behind either', () {
      fakeAsync((async) {
        manager.start(prayerTimes: _times(DateTime.now()));
        async.flushMicrotasks();
        manager.stop();
        async.flushMicrotasks();

        async.elapse(const Duration(hours: 6));

        expect(notifier.hides, 1);
        expect(async.periodicTimerCount, 0);
      });
    });
  });

  group('what the card says', () {
    test('counts down to the prayer instant, not to "now"', () async {
      // setWhen(theInstant) is what lets Android render the countdown with no
      // updates. A "now"-relative value would need re-posting to stay true,
      // which is the bug this replaced.
      final day = DateTime.now();
      final times = _times(day);
      await manager.start(prayerTimes: times);

      final at = notifier.shown.single['prayerAt']! as DateTime;
      expect(at.isAfter(DateTime.now()), isTrue);
    });

    test('the title is authored here, with a token for Kotlin', () async {
      // Kotlin substitutes and never composes: it has to render this card again
      // on every fire, and a second author of Arabic on the native side is the
      // drift the wire format exists to prevent.
      await manager.start(prayerTimes: _times(DateTime.now()));

      final format = notifier.shown.single['titleFormat']! as String;
      expect(format, contains('{prayer}'));
      expect(format, contains('الصلاة القادمة'));
      expect(
        format.replaceAll('{prayer}', 'الفجر'),
        isNot(contains('{prayer}')),
      );
    });

    test('the body reads the same as the adhan card', () async {
      // Shared with PrayerNotificationContent.bodyText so the roll-forward,
      // which renders this card from a ledger row's `body`, cannot drift from
      // what Dart would have written.
      await manager.start(
        prayerTimes: _times(DateTime.now()),
        locationName: 'القاهرة',
      );

      expect(notifier.shown.single['body'], contains('القاهرة'));
      expect(notifier.shown.single['body'], contains('•'));
    });

    test('with every prayer past, it points at tomorrow\'s Fajr', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await manager.start(prayerTimes: _times(yesterday));

      final shown = notifier.shown.single;
      expect(shown['prayerName'], 'الفجر');
      expect((shown['prayerAt']! as DateTime).isAfter(yesterday), isTrue);
    });
  });

  group('lifecycle', () {
    test('a second start re-posts rather than no-opping', () async {
      // The caller reaches start() on every reschedule, and the times it hands
      // over may be newer than the ones the card was built from. The old code
      // returned early here and the card went stale.
      final times = _times(DateTime.now());
      await manager.start(prayerTimes: times);
      await manager.start(prayerTimes: times);

      expect(notifier.shown, hasLength(2));
      expect(manager.isActive, isTrue);
    });

    test('updating prayer times while stopped posts nothing', () async {
      await manager.updatePrayerTimes(prayerTimes: _times(DateTime.now()));

      expect(notifier.shown, isEmpty);
    });

    test('stopping without ever starting still hides', () async {
      // The card is owned natively and rolled forward by a broadcast receiver,
      // so it outlives the Dart process that posted it — while _isActive starts
      // false in every new one. When stop() was guarded on that flag, a user who
      // turned the card off in a session where it had not yet been started
      // never reached hide(): the native flag stayed set and the receiver
      // re-posted the card after every prayer, with no way back short of
      // clearing app data.
      await manager.stop();

      expect(notifier.hides, 1);
      expect(manager.isActive, isFalse);
    });

    test('stopping twice hides twice, and hiding twice is harmless', () async {
      await manager.start(prayerTimes: _times(DateTime.now()));
      await manager.stop();
      await manager.stop();

      expect(notifier.hides, 2);
      expect(manager.isActive, isFalse);
    });
  });
}
