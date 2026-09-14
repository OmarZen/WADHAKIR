import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/notifications/ios_notification_budget.dart';
import 'package:wadhakir/core/notifications/reminder_floor_service.dart';

DateTime _at(int day, int hour, [int minute = 0]) =>
    DateTime(2026, 3, day, hour, minute);

void main() {
  group('fireTimeFrom — the hour', () {
    test('never inherits the hour the app was opened at', () {
      // The defect this test exists for. The original took now.add(10 days)
      // wholesale, so the floor fired at whatever minute the user last
      // foregrounded the app. In a PRAYER app the classic late foreground is
      // checking Fajr at 04:20 — and ten days later, that is when a channel
      // with playSound: true would have gone off.
      for (final hour in [0, 3, 4, 5, 23]) {
        final fire = ReminderFloorService.fireTimeFrom(_at(1, hour, 20));
        expect(
          fire.hour,
          isNot(hour),
          reason: 'a $hour:20 resume still fires at $hour:00',
        );
      }
    });

    test('always lands on the same polite hour, whatever the resume', () {
      final hours = <int>{};
      for (var hour = 0; hour < 24; hour++) {
        for (final minute in [0, 17, 59]) {
          hours.add(
            ReminderFloorService.fireTimeFrom(_at(1, hour, minute)).hour,
          );
        }
      }
      expect(hours, hasLength(1), reason: 'the fire hour must be pinned');
      final settled = hours.single;
      expect(settled, greaterThanOrEqualTo(8));
      expect(settled, lessThanOrEqualTo(20));
    });

    test('never fires in the night, from any resume minute', () {
      for (var hour = 0; hour < 24; hour++) {
        final fire = ReminderFloorService.fireTimeFrom(_at(1, hour, 45));
        expect(
          fire.hour >= 7 && fire.hour <= 21,
          isTrue,
          reason: 'a $hour:45 resume produced a ${fire.hour}:00 notification',
        );
      }
    });

    test('is on the minute, not the second', () {
      final fire = ReminderFloorService.fireTimeFrom(_at(1, 4, 37));
      expect(fire.minute, 0);
      expect(fire.second, 0);
    });
  });

  group('fireTimeFrom — the fuse', () {
    test('gives the user at least the full silence window', () {
      // The fuse must never burn short: firing early would tell someone their
      // reminders had stopped while they were still running.
      for (var hour = 0; hour < 24; hour++) {
        final now = _at(1, hour, 30);
        final fire = ReminderFloorService.fireTimeFrom(now);
        expect(
          fire.difference(now).inDays,
          greaterThanOrEqualTo(10),
          reason: 'a $hour:30 resume burns its fuse in under ten days',
        );
      }
    });

    test('does not overshoot by more than a day', () {
      for (var hour = 0; hour < 24; hour++) {
        final now = _at(1, hour, 30);
        final fire = ReminderFloorService.fireTimeFrom(now);
        expect(fire.difference(now).inDays, lessThanOrEqualTo(11));
      }
    });

    test('a late-night resume rolls to the following morning, not the same '
        'one', () {
      // 23:50 + 10 days lands at 23:50 on day 11; the polite hour that day has
      // already passed, so it must move to day 12 rather than fire nine days
      // and ten minutes in.
      final now = _at(1, 23, 50);
      final fire = ReminderFloorService.fireTimeFrom(now);
      expect(fire.isAfter(now.add(const Duration(days: 10))), isTrue);
    });

    test('an early-morning resume does not wait an extra day for nothing', () {
      final now = _at(1, 2, 0);
      final fire = ReminderFloorService.fireTimeFrom(now);
      expect(fire.difference(now).inDays, 10);
    });
  });

  group('the floor and the budget', () {
    test('occupies exactly the one slot it is allocated', () {
      expect(IosNotificationBudget.floor, 1);
      expect(
        IosNotificationBudget.capFor(ReminderSlot.floorNudge, isIOS: true),
        1,
      );
    });

    test('its id is clear of every other range in the app', () {
      // prayers 100-694, location 900, diagnostic 998, persistent 999,
      // fasting 5001-5999, wird 6001/6099, azkar 7100+, feature nudge 7200,
      // app-lock 8011, floating dhikr 9011.
      const id = ReminderFloorService.notificationId;
      expect(id, 9500);
      for (final (low, high) in [
        (100, 694),
        (5001, 5999),
        (6001, 6099),
        (7099, 7200),
        (8011, 8011),
        (9011, 9011),
      ]) {
        expect(
          id >= low && id <= high,
          isFalse,
          reason: 'the floor id collides with $low-$high',
        );
      }
      expect([900, 998, 999], isNot(contains(id)));
    });
  });
}
