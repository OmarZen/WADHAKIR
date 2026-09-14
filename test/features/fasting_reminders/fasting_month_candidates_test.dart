import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/notifications/ios_notification_budget.dart';
import 'package:wadhakir/features/fasting_reminders/services/fasting_notification_service.dart';

/// Every fasting reminder switched on, which is the configuration that put the
/// app over the iOS cap in the first place.
List<FastingDayCandidate> _everything({
  required int month,
  int year = 1447,
  int idOffset = 0,
  int currentHijriDay = 1,
  int? currentHijriMonth,
  int currentHijriYear = 1447,
}) => FastingNotificationService.monthCandidates(
  month: month,
  year: year,
  idOffset: idOffset,
  ayyamAlBidEnabled: true,
  ninthTenthEnabled: true,
  specialDaysEmphasis: true,
  currentHijriDay: currentHijriDay,
  currentHijriMonth: currentHijriMonth ?? month,
  currentHijriYear: currentHijriYear,
);

void main() {
  group('monthCandidates ordering', () {
    test('the 9th and 10th come before Ayyam al-Bid, despite being declared '
        'after it', () {
      // The regression this whole extraction exists to prevent. Before the
      // budget, declaration order was invisible; now it decides who is dropped,
      // and declaration order would have starved the SOONER reminders.
      final days = _everything(month: 5).map((c) => c.day).toList();
      expect(days, [9, 10, 13, 14, 15]);
    });

    test('an ordinary month offers exactly the five enabled days', () {
      expect(_everything(month: 5), hasLength(5));
    });

    test('Muharram offers the 9th and 10th ONCE each, named Tasu\'a and '
        'Ashura', () {
      // Tasu'a IS the 9th and Ashura IS the 10th — the same fast under two
      // names. Scheduling both would post two near-identical cards at the same
      // instant, and under the slot budget the duplicate pair on the 9th ate
      // four of the fasting slots and starved Ashura entirely. Adversarial
      // review caught that before it shipped.
      final candidates = _everything(month: 1);
      expect(candidates.map((c) => c.day), [9, 10, 13, 14, 15]);
      expect(candidates[0].idBase, 5020, reason: 'the 9th must be Tasu\'a');
      expect(candidates[1].idBase, 5010, reason: 'the 10th must be Ashura');
      expect(candidates[0].isSpecial, isTrue);
      expect(candidates[1].isSpecial, isTrue);
    });

    test('Dhul Hijjah offers the 9th once, named Arafah', () {
      final candidates = _everything(month: 12);
      expect(candidates.map((c) => c.day), [9, 10, 13, 14, 15]);
      expect(candidates[0].idBase, 5030, reason: 'the 9th must be Arafah');
      expect(candidates[0].isSpecial, isTrue);
    });

    test('the named fast wins its day, never the generic one', () {
      // "صيام عاشوراء" tells a user what the day is; "العاشر من الشهر" does
      // not. If the generic entry ever won, the user would still be reminded —
      // which is exactly why this needs a test rather than a bug report.
      for (final (month, day, expectedBase) in [
        (1, 9, 5020), // Tasu'a over the 9th
        (1, 10, 5010), // Ashura over the 10th
        (12, 9, 5030), // Arafah over the 9th
      ]) {
        final winner = _everything(
          month: month,
        ).firstWhere((c) => c.day == day);
        expect(winner.idBase, expectedBase);
        expect(winner.isSpecial, isTrue);
      }
    });

    test('a Hijri month never offers more than five distinct days', () {
      // This is the invariant IosNotificationBudget.fasting is sized against:
      // 2 weekly + 5 days x 3 reminders = 17. If a month could offer seven,
      // the quota would be wrong and the budget would silently truncate.
      for (var month = 1; month <= 12; month++) {
        final candidates = _everything(month: month);
        expect(
          candidates.length,
          lessThanOrEqualTo(5),
          reason: 'month $month offered ${candidates.length} days',
        );
        expect(
          candidates.map((c) => c.day).toSet().length,
          candidates.length,
          reason: 'month $month offered the same day twice',
        );
      }
    });

    test('special days appear only in their own months', () {
      final ordinary = _everything(month: 5);
      expect(ordinary.every((c) => !c.isSpecial), isTrue);
    });

    test('the same month derives identically on every run', () {
      // De-duplication reads from a map, so the result must not depend on
      // iteration luck. At the budget boundary a shuffle would give a user
      // Tasu'a one day and the plain 9th the next, for no observable reason.
      final first = _everything(month: 1).map((c) => c.idBase).toList();
      for (var i = 0; i < 20; i++) {
        expect(_everything(month: 1).map((c) => c.idBase).toList(), first);
      }
    });
  });

  group('monthCandidates and the passage of the month', () {
    test('days already past in the CURRENT month are dropped', () {
      final onThe14th = _everything(month: 5, currentHijriDay: 14);
      expect(onThe14th.map((c) => c.day), [14, 15]);
    });

    test('the current day itself still counts — it is not past yet', () {
      final onThe10th = _everything(month: 5, currentHijriDay: 10);
      expect(onThe10th.map((c) => c.day), contains(10));
    });

    test('a later month keeps every day, whatever today is', () {
      // This is what makes the next-month pre-schedule work on Android.
      final nextMonth = _everything(
        month: 6,
        currentHijriDay: 29,
        currentHijriMonth: 5,
      );
      expect(nextMonth.map((c) => c.day), [9, 10, 13, 14, 15]);
    });

    test('the same month in a different year is not "the current month"', () {
      final nextYear = _everything(
        month: 5,
        year: 1448,
        currentHijriDay: 29,
        currentHijriMonth: 5,
        currentHijriYear: 1447,
      );
      expect(nextYear, hasLength(5));
    });

    test('past the 15th there is nothing left in the month to offer', () {
      // Not a bug: the next month's pass covers what comes after. On iOS that
      // pass is skipped and the next cold start picks it up instead.
      expect(_everything(month: 5, currentHijriDay: 16), isEmpty);
      expect(_everything(month: 5, currentHijriDay: 29), isEmpty);
    });
  });

  group('monthCandidates and settings', () {
    test('nothing enabled offers nothing', () {
      final none = FastingNotificationService.monthCandidates(
        month: 1,
        year: 1447,
        idOffset: 0,
        ayyamAlBidEnabled: false,
        ninthTenthEnabled: false,
        specialDaysEmphasis: false,
        currentHijriDay: 1,
        currentHijriMonth: 1,
        currentHijriYear: 1447,
      );
      expect(none, isEmpty);
    });

    test('each switch contributes only its own days', () {
      final onlyAyyam = FastingNotificationService.monthCandidates(
        month: 1,
        year: 1447,
        idOffset: 0,
        ayyamAlBidEnabled: true,
        ninthTenthEnabled: false,
        specialDaysEmphasis: false,
        currentHijriDay: 1,
        currentHijriMonth: 1,
        currentHijriYear: 1447,
      );
      expect(onlyAyyam.map((c) => c.day), [13, 14, 15]);
    });

    test('idOffset shifts every id base and collides with nothing', () {
      final base = _everything(month: 1);
      final shifted = _everything(month: 1, idOffset: 400);
      final baseIds = base.map((c) => c.idBase).toSet();
      final shiftedIds = shifted.map((c) => c.idBase).toSet();

      expect(baseIds.length, base.length, reason: 'id bases must be unique');
      expect(
        shiftedIds.intersection(baseIds),
        isEmpty,
        reason: 'the next-month pass must not overwrite this month',
      );
      for (var i = 0; i < base.length; i++) {
        expect(shifted[i].idBase, base[i].idBase + 400);
      }
    });

    test('every id base stays inside the 5001-5999 fasting range', () {
      // The id space is what lets a prayer reschedule cancel only prayers. A
      // fasting id that wandered out of range would be swept by someone else.
      for (final month in [1, 5, 12]) {
        for (final offset in [0, 400]) {
          for (final c in _everything(month: month, idOffset: offset)) {
            // +3 because each candidate numbers three reminders from its base.
            expect(c.idBase, greaterThanOrEqualTo(5001));
            expect(c.idBase + 3, lessThanOrEqualTo(5999));
          }
        }
      }
    });
  });

  group('the fasting quota', () {
    test('the worst month fits its quota EXACTLY, dropping nothing', () {
      // The whole point of the corrected quota. Muharram, everything on, first
      // of the month, advance reminders in play: 2 weekly + 5 days x 3 = 17,
      // which is exactly IosNotificationBudget.fasting.
      //
      // The first draft capped this at 6 and would have silently deleted Ayyam
      // al-Bid from every iOS device. A test that only asserted "we truncate
      // correctly" would have passed. This one asserts nothing is truncated.
      for (final month in [1, 5, 12]) {
        final candidates = _everything(month: month);
        final budget = NotificationSlotBudget.of(
          IosNotificationBudget.capFor(ReminderSlot.fasting, isIOS: true),
        );
        // The two weekly repeating reminders are charged first.
        expect(budget.take(), isTrue);
        expect(budget.take(), isTrue);

        var refused = 0;
        for (final _ in candidates) {
          for (var reminder = 0; reminder < 3; reminder++) {
            if (!budget.take()) refused++;
          }
        }

        expect(
          refused,
          0,
          reason:
              'month $month wanted ${2 + candidates.length * 3} slots and the '
              'quota is ${IosNotificationBudget.fasting} — a real reminder was '
              'dropped',
        );
      }
    });

    test('the quota is not wastefully larger than the worst month either', () {
      // A quota that is too big steals slots from prayers just as silently as
      // one that is too small deletes reminders. 17 is the measured ceiling,
      // not a round number picked for comfort.
      const worstCase = 2 + 5 * 3;
      expect(IosNotificationBudget.fasting, worstCase);
    });

    test('Android spends the same pass without dropping anything', () {
      final candidates = _everything(month: 1);
      final budget = NotificationSlotBudget.of(
        IosNotificationBudget.capFor(ReminderSlot.fasting, isIOS: false),
      );
      var posted = 0;
      for (final _ in candidates) {
        for (var reminder = 0; reminder < 3; reminder++) {
          if (budget.take()) posted++;
        }
      }
      expect(posted, candidates.length * 3);
    });

    test('what survives is the soonest, not the first declared', () {
      // The point of the sort: with only a couple of slots left, the user gets
      // the 9th — not Ayyam al-Bid on the 13th.
      final candidates = _everything(month: 5);
      final budget = NotificationSlotBudget(2);
      final survived = <int>[];
      for (final candidate in candidates) {
        if (budget.take()) survived.add(candidate.day);
      }
      expect(survived, [9, 10]);
    });
  });
}
