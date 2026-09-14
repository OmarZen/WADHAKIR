import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/reminders/reminder_health.dart';
import 'package:wadhakir/core/reminders/reminder_ledger_entry.dart';

/// A fixed instant everything below is measured against, so no test here
/// depends on when it runs.
final DateTime now = DateTime(2026, 9, 13, 14, 0);

ReminderLedgerEntry fired({
  required int daysAgo,
  Duration skew = Duration.zero,
  ReminderFireOutcome outcome = ReminderFireOutcome.sounded,
  int id = 100,
}) {
  final due = now.subtract(Duration(days: daysAgo));
  return ReminderLedgerEntry(
    type: ReminderEventType.fired,
    atEpochMs: due.add(skew).millisecondsSinceEpoch,
    id: id,
    dueEpochMs: due.millisecondsSinceEpoch,
    outcome: outcome,
  );
}

ReminderLedgerEntry lapsed({required int daysAgo, int id = 100}) {
  final due = now.subtract(Duration(days: daysAgo));
  return ReminderLedgerEntry(
    type: ReminderEventType.lapsed,
    atEpochMs: due.add(const Duration(hours: 5)).millisecondsSinceEpoch,
    id: id,
    dueEpochMs: due.millisecondsSinceEpoch,
  );
}

/// A device with nothing wrong with it.
const healthyProbe = ReminderHealthProbe(
  notificationsAllowed: true,
  remindersEnabled: true,
);

ReminderHealthVerdict evaluate(
  List<ReminderLedgerEntry> entries, [
  ReminderHealthProbe probe = healthyProbe,
]) => ReminderHealth.evaluate(entries: entries, probe: probe, now: now);

/// Enough clean rows to clear the minimum-evidence bar.
List<ReminderLedgerEntry> get healthyWeek => [
  for (var day = 1; day <= 7; day++) fired(daysAgo: day, id: 100 + day),
];

void main() {
  group('honesty about what is not known', () {
    test('an empty ledger is "unknown", never "healthy"', () {
      final verdict = evaluate([]);

      // The worst reminder bug in this app's history was silent. A green tick
      // over no evidence is how a user learns to stop believing this screen.
      expect(verdict.status, ReminderHealthStatus.unknown);
      expect(verdict.action, ReminderHealthAction.none);
    });

    test('one or two fired rows is still not enough to claim health', () {
      expect(
        evaluate([fired(daysAgo: 1), fired(daysAgo: 2, id: 101)]).status,
        ReminderHealthStatus.unknown,
      );
    });

    test('three clean rows is enough', () {
      expect(
        evaluate(healthyWeek.take(3).toList()).status,
        ReminderHealthStatus.healthy,
      );
    });

    test('settings that have not loaded produce no verdict at all', () {
      // Assuming "reminders are on" would let this screen diagnose — and demand
      // a system permission for — a feature the user had switched off.
      final verdict = evaluate(
        [
          ...healthyWeek,
          lapsed(daysAgo: 1, id: 201),
          lapsed(daysAgo: 2, id: 202),
        ],
        const ReminderHealthProbe(
          notificationsAllowed: false,
          remindersEnabled: true,
          settingsKnown: false,
          batteryExempt: false,
        ),
      );

      expect(verdict.status, ReminderHealthStatus.unknown);
      expect(verdict.action, ReminderHealthAction.none);
    });

    test('rows older than the window do not count towards evidence', () {
      expect(
        evaluate([
          for (var day = 20; day <= 40; day++)
            fired(daysAgo: day, id: 100 + day),
        ]).status,
        ReminderHealthStatus.unknown,
        reason: 'a device fixed last month should not be judged on last month',
      );
    });

    test('rows dated in the future are ignored', () {
      // The signature of a clock that was wrong and has since been corrected.
      // Counting them lets one bad NTP sync poison the verdict for weeks.
      final future = ReminderLedgerEntry(
        type: ReminderEventType.lapsed,
        atEpochMs: now.add(const Duration(days: 400)).millisecondsSinceEpoch,
        id: 1,
        dueEpochMs: now.add(const Duration(days: 400)).millisecondsSinceEpoch,
      );

      final verdict = evaluate([...healthyWeek, future, future]);

      expect(verdict.status, ReminderHealthStatus.healthy);
      expect(verdict.evidence.lapsed, 0);
    });
  });

  group('thin evidence may not accuse, either', () {
    test('one late arrival on a fresh install demands nothing', () {
      // The defect this replaces: `late/fired = 1/1 = 1.0` cleared the share
      // threshold, so a brand-new install whose first adhan came three minutes
      // late was told its device was at fault and asked for a system-level
      // battery exemption — the exact thing the screen promises never to do.
      final verdict = evaluate(
        [fired(daysAgo: 1, skew: const Duration(minutes: 3))],
        const ReminderHealthProbe(
          notificationsAllowed: true,
          remindersEnabled: true,
          batteryExempt: false,
          oemAutostartAvailable: true,
        ),
      );

      expect(verdict.status, ReminderHealthStatus.unknown);
      expect(verdict.action, ReminderHealthAction.none);
    });

    test(
      'a phone switched off overnight on day one is not a broken device',
      () {
        // Isha and Fajr lapse because there was no device, not because a vendor
        // killed the app. Two lapses and nothing else is not a pattern.
        final verdict = evaluate(
          [lapsed(daysAgo: 1, id: 201), lapsed(daysAgo: 1, id: 202)],
          const ReminderHealthProbe(
            notificationsAllowed: true,
            remindersEnabled: true,
            batteryExempt: false,
          ),
        );

        expect(verdict.status, ReminderHealthStatus.unknown);
        expect(verdict.action, ReminderHealthAction.none);
      },
    );

    test(
      'the same two lapses with a week of evidence behind them DO accuse',
      () {
        final verdict = evaluate(
          [
            ...healthyWeek,
            lapsed(daysAgo: 1, id: 201),
            lapsed(daysAgo: 2, id: 202),
          ],
          const ReminderHealthProbe(
            notificationsAllowed: true,
            remindersEnabled: true,
            batteryExempt: false,
          ),
        );

        expect(verdict.status, ReminderHealthStatus.broken);
        expect(verdict.action, ReminderHealthAction.grantBatteryExemption);
      },
    );
  });

  group('the user\'s own choices are not faults', () {
    test('reminders switched off outranks everything else', () {
      final verdict = evaluate(
        [lapsed(daysAgo: 1, id: 1), lapsed(daysAgo: 2, id: 2)],
        const ReminderHealthProbe(
          notificationsAllowed: false,
          remindersEnabled: false,
          exactAlarmsAllowed: false,
          batteryExempt: false,
        ),
      );

      // Telling someone their phone is broken because they turned something
      // off on purpose is the fastest way to lose them.
      expect(verdict.status, ReminderHealthStatus.off);
      expect(verdict.action, ReminderHealthAction.none);
    });

    test('a silenced phone is not counted as a delivery failure', () {
      final verdict = evaluate([
        for (var day = 1; day <= 7; day++)
          fired(
            daysAgo: day,
            id: 100 + day,
            outcome: ReminderFireOutcome.silent,
          ),
      ]);

      expect(verdict.status, ReminderHealthStatus.healthy);
      expect(verdict.evidence.silenced, 7);
    });
  });

  group('certainties outrank inferences', () {
    test('blocked notifications beat any ledger evidence', () {
      final verdict = evaluate(
        healthyWeek,
        const ReminderHealthProbe(
          notificationsAllowed: false,
          remindersEnabled: true,
        ),
      );

      expect(verdict.status, ReminderHealthStatus.broken);
      expect(verdict.action, ReminderHealthAction.openNotificationSettings);
    });

    test('a muted channel is read live, not out of the ledger', () {
      // The defect this replaces: `evidence.muted > 0` was historical, so a
      // user who muted a channel on Monday and unmuted it on Tuesday was told
      // it was still muted for a fortnight — and that verdict sits high enough
      // in the ladder to hide every real fault underneath it.
      final withHistory = evaluate([
        ...healthyWeek,
        fired(daysAgo: 6, id: 601, outcome: ReminderFireOutcome.muted),
      ]);
      expect(
        withHistory.status,
        ReminderHealthStatus.healthy,
        reason: 'a channel they have since unmuted is not a present fault',
      );

      final blockedNow = evaluate(
        healthyWeek,
        const ReminderHealthProbe(
          notificationsAllowed: true,
          remindersEnabled: true,
          mutedAdhanChannelKey: 'prayer_adhan_fajr_v2',
        ),
      );
      expect(blockedNow.status, ReminderHealthStatus.broken);
      expect(blockedNow.action, ReminderHealthAction.openChannelSettings);
    });
  });

  group('causes are diagnosed before symptoms', () {
    test('revoked exact alarms outrank the lateness they explain', () {
      // With the permission revoked the scheduler degrades to
      // setAndAllowWhileIdle, which is inexact BY DESIGN. Sending the user to
      // a vendor autostart screen to fix that would be solving the wrong
      // problem, and one the app can fix in a single tap.
      final verdict = evaluate(
        [
          for (var day = 1; day <= 7; day++)
            fired(
              daysAgo: day,
              id: 100 + day,
              skew: const Duration(minutes: 20),
            ),
        ],
        const ReminderHealthProbe(
          notificationsAllowed: true,
          remindersEnabled: true,
          exactAlarmsAllowed: false,
          oemAutostartAvailable: true,
        ),
      );

      expect(verdict.status, ReminderHealthStatus.degraded);
      expect(verdict.action, ReminderHealthAction.grantExactAlarms);
    });
  });

  group('an alarm that arrives without a sound is not a success', () {
    test('a week of refused foreground starts is never "healthy"', () {
      // The defect this replaces: `refused` counted towards `fired` with no
      // branch of its own, so a device that refused every foreground-service
      // start for a week — no adhan at all — was shown a green tick and offered
      // no button.
      final verdict = evaluate(
        [
          for (var day = 1; day <= 7; day++)
            fired(
              daysAgo: day,
              id: 100 + day,
              outcome: ReminderFireOutcome.refused,
            ),
        ],
        const ReminderHealthProbe(
          notificationsAllowed: true,
          remindersEnabled: true,
          batteryExempt: false,
        ),
      );

      expect(verdict.status, ReminderHealthStatus.degraded);
      expect(verdict.messageKey, 'reminder_health.silent_delivery');
      expect(verdict.action, ReminderHealthAction.grantBatteryExemption);
      expect(verdict.evidence.refused, 7);
    });

    test('one refusal among many successes is not the verdict', () {
      final verdict = evaluate([
        ...healthyWeek,
        fired(daysAgo: 1, id: 901, outcome: ReminderFireOutcome.refused),
      ]);

      expect(verdict.status, ReminderHealthStatus.healthy);
    });

    test('orphans are not deliveries, and cannot manufacture health', () {
      // An orphan's `due` IS its arrival instant, so it can never be late —
      // three of them counted as deliveries read as a perfect week.
      final verdict = evaluate([
        for (var day = 1; day <= 5; day++)
          fired(
            daysAgo: day,
            id: 100 + day,
            outcome: ReminderFireOutcome.orphan,
          ),
      ]);

      expect(verdict.status, ReminderHealthStatus.unknown);
      expect(verdict.evidence.fired, 0);
      expect(verdict.evidence.orphan, 5);
    });
  });

  group('lateness', () {
    test('a skew inside the threshold is not late', () {
      final verdict = evaluate([
        for (var day = 1; day <= 7; day++)
          fired(daysAgo: day, id: 100 + day, skew: const Duration(seconds: 90)),
      ]);

      expect(verdict.status, ReminderHealthStatus.healthy);
      expect(verdict.evidence.late, 0);
    });

    test('three late arrivals is a pattern', () {
      final verdict = evaluate([
        ...healthyWeek,
        for (var day = 1; day <= 3; day++)
          fired(daysAgo: day, skew: const Duration(minutes: 12), id: 200 + day),
      ]);

      expect(verdict.status, ReminderHealthStatus.degraded);
      expect(verdict.messageKey, 'reminder_health.arriving_late');
    });

    test('the share test catches the SMALL end a count never reaches', () {
      // Two late out of four never accumulates to three, and is still half of
      // everything this device has done.
      final verdict = evaluate([
        fired(daysAgo: 1, id: 101),
        fired(daysAgo: 2, id: 102),
        fired(daysAgo: 3, id: 103, skew: const Duration(minutes: 30)),
        fired(daysAgo: 4, id: 104, skew: const Duration(minutes: 30)),
      ]);

      expect(verdict.status, ReminderHealthStatus.degraded);
    });

    test('the count test catches the LARGE end a share dilutes', () {
      // 4 late out of 40 is 10% — under the share threshold, and still four
      // missed prayer times.
      final verdict = evaluate([
        for (var i = 0; i < 36; i++) fired(daysAgo: 1 + i ~/ 6, id: 100 + i),
        for (var i = 0; i < 4; i++)
          fired(daysAgo: 2, id: 900 + i, skew: const Duration(minutes: 30)),
      ]);

      expect(verdict.status, ReminderHealthStatus.degraded);
    });

    test('one late arrival out of forty is neither', () {
      final verdict = evaluate([
        for (var i = 0; i < 40; i++) fired(daysAgo: 1 + i ~/ 6, id: 100 + i),
        fired(daysAgo: 2, id: 999, skew: const Duration(minutes: 30)),
      ]);

      expect(verdict.status, ReminderHealthStatus.healthy);
    });

    test('an alarm that arrived EARLY is not late', () {
      // A lead-time reminder legitimately fires ahead of its instant.
      final verdict = evaluate([
        for (var day = 1; day <= 7; day++)
          fired(
            daysAgo: day,
            id: 100 + day,
            skew: const Duration(minutes: -15),
          ),
      ]);

      expect(verdict.evidence.late, 0);
      expect(verdict.status, ReminderHealthStatus.healthy);
    });
  });

  group('the button a broken device earns', () {
    List<ReminderLedgerEntry> lapsing() => [
      ...healthyWeek,
      lapsed(daysAgo: 1, id: 201),
      lapsed(daysAgo: 2, id: 202),
    ];

    test('the OEM screen is offered ahead of the battery exemption', () {
      // On the vendors this branch fires on, the battery exemption alone does
      // not stop the task killer — which is the entire premise of item #16.
      final verdict = evaluate(
        lapsing(),
        const ReminderHealthProbe(
          notificationsAllowed: true,
          remindersEnabled: true,
          batteryExempt: false,
          oemAutostartAvailable: true,
        ),
      );

      expect(verdict.action, ReminderHealthAction.openOemAutostart);
    });

    test('with no OEM screen, the battery exemption is the fallback', () {
      final verdict = evaluate(
        lapsing(),
        const ReminderHealthProbe(
          notificationsAllowed: true,
          remindersEnabled: true,
          batteryExempt: false,
        ),
      );

      expect(verdict.action, ReminderHealthAction.grantBatteryExemption);
    });

    test('with nothing left to offer, it offers nothing', () {
      // An honest dead end beats a button that changes nothing.
      final verdict = evaluate(
        lapsing(),
        const ReminderHealthProbe(
          notificationsAllowed: true,
          remindersEnabled: true,
          batteryExempt: true,
        ),
      );

      expect(verdict.status, ReminderHealthStatus.broken);
      expect(verdict.action, ReminderHealthAction.none);
    });

    test('the battery exemption is never asked for without evidence', () {
      // R1's lesson, generalised: this is a demand for a system-level
      // exemption, and asking before the app has any reason is how an app
      // teaches users to say no.
      final verdict = evaluate(
        healthyWeek,
        const ReminderHealthProbe(
          notificationsAllowed: true,
          remindersEnabled: true,
          batteryExempt: false,
        ),
      );

      expect(verdict.status, ReminderHealthStatus.healthy);
      expect(verdict.action, ReminderHealthAction.none);
    });
  });

  group('iOS, which has no fire path to report from', () {
    test('an OS holding nothing is broken, and says so', () {
      // Without this, iOS could only ever return "ask me later": no Dart writer
      // produces a fired/lapsed row, so the ledger is permanently empty of
      // delivery evidence and every other branch is unreachable.
      final verdict = evaluate(
        const [],
        const ReminderHealthProbe(
          notificationsAllowed: true,
          remindersEnabled: true,
          pendingCount: 0,
          pendingCapacity: 64,
        ),
      );

      expect(verdict.status, ReminderHealthStatus.broken);
      expect(verdict.messageKey, 'reminder_health.nothing_scheduled');
    });

    test('a saturated cap is reported, with nothing to press', () {
      final verdict = evaluate(
        const [],
        const ReminderHealthProbe(
          notificationsAllowed: true,
          remindersEnabled: true,
          pendingCount: 64,
          pendingCapacity: 64,
        ),
      );

      expect(verdict.status, ReminderHealthStatus.degraded);
      expect(verdict.messageKey, 'reminder_health.at_capacity');
      expect(verdict.action, ReminderHealthAction.none);
    });

    test('an iOS install below the cap can actually reach healthy', () {
      // The defect this replaces: no Dart writer produces a fired/lapsed row,
      // so `observations` is permanently zero on iOS and every iPhone sat on
      // «لم يمرّ وقت كافٍ **بعد**» — a sentence promising a verdict that could
      // never arrive. An earlier version of THIS TEST asserted `unknown` while
      // calling the scenario "healthy" in its own name.
      final verdict = evaluate(
        const [],
        const ReminderHealthProbe(
          notificationsAllowed: true,
          remindersEnabled: true,
          pendingCount: 57,
          pendingCapacity: 64,
        ),
      );

      expect(verdict.status, ReminderHealthStatus.healthy);
      expect(
        verdict.messageKey,
        'reminder_health.healthy_scheduled',
        reason: 'iOS can prove scheduling, never delivery — say only that',
      );
    });

    test('the iOS claim is weaker than the Android one, and worded so', () {
      final ios = evaluate(
        const [],
        const ReminderHealthProbe(
          notificationsAllowed: true,
          remindersEnabled: true,
          pendingCount: 57,
          pendingCapacity: 64,
        ),
      );
      final android = evaluate(healthyWeek);

      expect(ios.status, android.status);
      expect(
        ios.messageKey,
        isNot(android.messageKey),
        reason:
            'delivery evidence and scheduling evidence are not the '
            'same claim and must not share a sentence',
      );
    });

    test('a zero pending count is ignored where the platform has no cap', () {
      // Android reports the plugin's schedules, which exclude the five prayers
      // once native alarms own them — zero there is normal, not catastrophic.
      final verdict = evaluate(healthyWeek);
      expect(verdict.status, ReminderHealthStatus.healthy);
    });
  });

  group('evidence counting', () {
    test('armed, pending and trigger rows are context, not faults', () {
      final verdict = evaluate([
        ...healthyWeek,
        ReminderLedgerEntry(
          type: ReminderEventType.armed,
          atEpochMs: now.millisecondsSinceEpoch,
          count: 0,
          detail: 'plugin',
        ),
        ReminderLedgerEntry(
          type: ReminderEventType.trigger,
          atEpochMs: now.millisecondsSinceEpoch,
          detail: 'android.intent.action.BOOT_COMPLETED',
        ),
        ReminderLedgerEntry(
          type: ReminderEventType.pending,
          atEpochMs: now.millisecondsSinceEpoch,
          count: 57,
        ),
      ]);

      expect(verdict.status, ReminderHealthStatus.healthy);
      expect(verdict.evidence.fired, 7);
      expect(verdict.evidence.lapsed, 0);
    });

    test('"since" reports the oldest row actually considered, in UTC', () {
      final verdict = evaluate([
        fired(daysAgo: 40, id: 1),
        fired(daysAgo: 5, id: 2),
        fired(daysAgo: 3, id: 3),
        fired(daysAgo: 1, id: 4),
      ]);

      expect(verdict.evidence.since!.isUtc, isTrue);
      expect(
        verdict.evidence.since!.difference(now.toUtc()).inDays.abs(),
        5,
        reason: 'the 40-day-old row is outside the window',
      );
    });
  });
}
