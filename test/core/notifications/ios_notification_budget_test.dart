import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/notifications/ios_notification_budget.dart';

/// A candidate reminder, standing in for whatever a scheduler wants to post.
typedef _Candidate = ({String name, DateTime fireAt});

_Candidate _at(String name, int day) =>
    (name: name, fireAt: DateTime(2026, 3, day));

void main() {
  group('the allocation', () {
    // This is the test the definition of done asks for: proof, not an assert
    // that only fires in debug on a developer's phone.
    test('fits inside the 64 requests iOS actually keeps', () {
      expect(
        IosNotificationBudget.allocated +
            IosNotificationBudget.transientReserve,
        lessThanOrEqualTo(IosNotificationBudget.pendingCap),
        reason:
            'The per-feature quotas sum to ${IosNotificationBudget.allocated}, '
            'which leaves no room for the ${IosNotificationBudget.transientReserve} '
            'reserved transient slots. iOS discards the overflow silently — the '
            'app would look healthy and the adhan would not fire.',
      );
    });

    test('spends no more than the plannable slots', () {
      expect(
        IosNotificationBudget.allocated,
        lessThanOrEqualTo(IosNotificationBudget.plannable),
      );
      expect(IosNotificationBudget.unallocated, greaterThanOrEqualTo(0));
    });

    test('leaves the transient reserve genuinely unspent', () {
      // A reserve that the allocation has already eaten is not a reserve. This
      // catches the specific mistake of raising a feature quota by "just one"
      // until the margin is gone.
      expect(
        IosNotificationBudget.plannable,
        IosNotificationBudget.pendingCap -
            IosNotificationBudget.transientReserve,
      );
      expect(IosNotificationBudget.transientReserve, greaterThan(0));
    });

    test('the allocation covers real iOS demand instead of throttling it', () {
      // The number that matters is not "is the budget small" — it is "does the
      // budget fit what the app actually asks for on iOS".
      //
      // This test replaces one that asserted 25+13+26+1+1+1 = 67 > 64. That 26
      // was the ANDROID fasting figure: _scheduleHijriCalendarNotifications has
      // always skipped the next-month pre-schedule on iOS. Believing it is what
      // led the first draft to cap fasting at 6 and silently delete Ayyam
      // al-Bid from every iOS device. The old test passed throughout — it
      // compared two hand-written constants and could never have caught it.
      const realIosWorstCase =
          25 + // prayers: 5 x the 5-day iOS horizon
          12 + //  azkar: 6 fixed-clock + 7 prayer-driven, minus the qiyam pair
          17 + // fasting: 2 weekly + 5 distinct days x 3 reminders
          1 + // wird
          1 + // daily inspiration
          1; // the reminder floor

      expect(
        IosNotificationBudget.allocated,
        greaterThanOrEqualTo(realIosWorstCase),
        reason:
            'The allocation is smaller than what the app actually schedules on '
            'iOS, so some feature is being silently truncated by our own code '
            'rather than by any real constraint.',
      );
      expect(
        realIosWorstCase + IosNotificationBudget.transientReserve,
        lessThanOrEqualTo(IosNotificationBudget.pendingCap),
        reason: 'Real demand plus the reserve must still fit in 64.',
      );
    });

    test('every slot is allocated on iOS and uncapped on Android', () {
      for (final slot in ReminderSlot.values) {
        expect(
          IosNotificationBudget.capFor(slot, isIOS: true),
          isA<int>().having((c) => c, 'cap', greaterThan(0)),
          reason: '$slot has no iOS quota',
        );
        expect(
          IosNotificationBudget.capFor(slot, isIOS: false),
          isNull,
          reason: '$slot must be uncapped on Android, which has no limit',
        );
      }
    });

    test('the quotas add up to exactly what capFor hands out', () {
      final sum = ReminderSlot.values
          .map((s) => IosNotificationBudget.capFor(s, isIOS: true)!)
          .reduce((a, b) => a + b);
      expect(
        sum,
        IosNotificationBudget.allocated,
        reason:
            'A slot was added to ReminderSlot without being added to '
            'IosNotificationBudget.allocated, so the total is a fiction.',
      );
    });

    test('prayers outrank every other slot', () {
      // Declaration order is the contract; a reorder that demoted prayers
      // would otherwise pass silently.
      expect(ReminderSlot.values.first, ReminderSlot.prayer);
      expect(ReminderSlot.values.last, ReminderSlot.fasting);
    });
  });

  group('soonest()', () {
    test('keeps the nearest entries and drops the far ones', () {
      final kept = IosNotificationBudget.soonest(
        [_at('far', 20), _at('near', 2), _at('mid', 9)],
        2,
        when: (c) => c.fireAt,
      );
      expect(kept.map((c) => c.name), ['near', 'mid']);
    });

    test('returns them in chronological order, not input order', () {
      final kept = IosNotificationBudget.soonest(
        [_at('c', 30), _at('a', 1), _at('b', 15)],
        10,
        when: (c) => c.fireAt,
      );
      expect(kept.map((c) => c.name), ['a', 'b', 'c']);
    });

    test('a null cap sorts without truncating', () {
      final kept = IosNotificationBudget.soonest(
        [_at('c', 30), _at('a', 1), _at('b', 15)],
        null,
        when: (c) => c.fireAt,
      );
      expect(kept.map((c) => c.name), ['a', 'b', 'c']);
    });

    test('a cap wider than the list is not an error', () {
      final kept = IosNotificationBudget.soonest(
        [_at('a', 1)],
        50,
        when: (c) => c.fireAt,
      );
      expect(kept, hasLength(1));
    });

    test('an empty list stays empty', () {
      expect(
        IosNotificationBudget.soonest(<_Candidate>[], 5, when: (c) => c.fireAt),
        isEmpty,
      );
    });

    test('does not mutate the caller\'s list', () {
      final input = [_at('c', 30), _at('a', 1)];
      IosNotificationBudget.soonest(input, 1, when: (c) => c.fireAt);
      expect(input.map((c) => c.name), ['c', 'a']);
    });
  });

  group('NotificationSlotBudget', () {
    test('hands out exactly its slots and then refuses', () {
      final budget = NotificationSlotBudget(3);
      expect([
        budget.take(),
        budget.take(),
        budget.take(),
      ], everyElement(isTrue));
      expect(budget.take(), isFalse);
      expect(budget.take(), isFalse, reason: 'a refusal must not restore room');
      expect(budget.taken, 3);
    });

    test('a refused take claims nothing', () {
      final budget = NotificationSlotBudget(1);
      budget.take();
      budget.take();
      expect(budget.taken, 1);
      expect(budget.hasRoom, isFalse);
    });

    test('an unlimited budget never refuses', () {
      final budget = NotificationSlotBudget.unlimited();
      for (var i = 0; i < 500; i++) {
        expect(budget.take(), isTrue);
      }
      expect(budget.hasRoom, isTrue);
      expect(budget.taken, 500);
    });

    test('of(null) is unlimited and of(n) is capped', () {
      expect(NotificationSlotBudget.of(null).hasRoom, isTrue);
      final capped = NotificationSlotBudget.of(2);
      capped.take();
      capped.take();
      expect(capped.hasRoom, isFalse);
    });

    test('a zero or negative budget refuses immediately', () {
      expect(NotificationSlotBudget(0).take(), isFalse);
      expect(NotificationSlotBudget(-5).take(), isFalse);
      expect(NotificationSlotBudget(0).hasRoom, isFalse);
    });

    test('pairs with capFor to be capped on iOS and open on Android', () {
      final ios = NotificationSlotBudget.of(
        IosNotificationBudget.capFor(ReminderSlot.fasting, isIOS: true),
      );
      for (var i = 0; i < IosNotificationBudget.fasting; i++) {
        expect(ios.take(), isTrue);
      }
      expect(ios.take(), isFalse);

      final android = NotificationSlotBudget.of(
        IosNotificationBudget.capFor(ReminderSlot.fasting, isIOS: false),
      );
      for (var i = 0; i < 100; i++) {
        expect(android.take(), isTrue);
      }
    });
  });
}
