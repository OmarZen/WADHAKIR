import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/time/clock.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';
import 'package:wadhakir/features/pray_times/services/prayer_schedule_planner.dart';
import 'package:wadhakir/features/pray_times/services/prayer_scheduler.dart';

/// Records what the scheduler asked the device to do.
///
/// This is the whole reason [PrayerAlarmGateway] exists: the real gateway is
/// `awesome_notifications`, a singleton behind platform channels, so before
/// the interface there was no way to assert that a reschedule cancels before
/// it arms, or that a failed arm does not poison the next attempt.
class _FakeGateway implements PrayerAlarmGateway {
  final List<String> calls = [];
  final List<int> cancelled = [];
  final List<PlannedPrayerNotification> armed = [];

  /// Set to make the next [arm] throw, standing in for a denied permission or
  /// an exact-alarm refusal.
  Object? armThrows;

  @override
  Future<void> cancelIds(Iterable<int> ids) async {
    calls.add('cancel');
    cancelled.addAll(ids);
  }

  @override
  Future<void> arm(
    PlannedPrayerNotification planned, {
    String? locationName,
  }) async {
    calls.add('arm:${planned.id}');
    final failure = armThrows;
    if (failure != null) throw failure;
    armed.add(planned);
  }
}

/// A gateway that batches, like the native `AlarmManager` bridge.
class _BatchingFakeGateway extends _FakeGateway
    implements BatchingPrayerAlarmGateway {
  Object? commitThrows;

  /// Forces a real async gap inside every arm, so two overlapping reschedules
  /// would genuinely interleave if the scheduler let them.
  bool slowArm = false;

  @override
  Future<void> arm(
    PlannedPrayerNotification planned, {
    String? locationName,
  }) async {
    if (slowArm) await Future<void>.delayed(Duration.zero);
    return super.arm(planned, locationName: locationName);
  }

  @override
  Future<void> commit() async {
    calls.add('commit');
    final failure = commitThrows;
    if (failure != null) throw failure;
  }

  @override
  Future<void> abandon() async => calls.add('abandon');
}

const _cairoTimes = {
  'Fajr': (4, 41),
  'Dhuhr': (11, 58),
  'Asr': (15, 22),
  'Maghrib': (17, 56),
  'Isha': (19, 14),
};

Map<DateTime, Map<String, DateTime>> _horizon(int days) => {
  for (var i = 0; i < days; i++)
    DateTime(2026, 3, 14 + i): {
      for (final e in _cairoTimes.entries)
        e.key: DateTime(2026, 3, 14 + i, e.value.$1, e.value.$2),
    },
};

NotificationSettingsModel _settings({bool masterEnabled = true}) =>
    NotificationSettingsModel.defaultSettings().copyWith(
      masterEnabled: masterEnabled,
    );

void main() {
  late _FakeGateway gateway;
  late FixedClock clock;
  late PrayerScheduler scheduler;

  setUp(() {
    gateway = _FakeGateway();
    // 04:00 — before Fajr, so a full horizon is still schedulable.
    clock = FixedClock(DateTime(2026, 3, 14, 4));
    scheduler = PrayerScheduler(gateway, const PrayerSchedulePlanner(), clock);
  });

  group('sequencing', () {
    test('cancels the whole prayer window before arming anything', () async {
      // Order matters: arming first would let a cancel sweep wipe what was
      // just armed.
      await scheduler.reschedule(
        prayerTimesByDay: _horizon(2),
        settings: _settings(),
      );

      expect(gateway.calls.first, 'cancel');
      expect(gateway.calls.where((c) => c == 'cancel'), hasLength(1));
      expect(gateway.armed, hasLength(10));
      expect(
        gateway.cancelled.toSet(),
        PrayerSchedulePlanner.cancellableIds.toSet(),
      );
    });

    test('the sweep never leaves the ids prayers own', () async {
      // Azkar (7100+), wird (6001/6099), fasting (5001-5999) and the
      // persistent notification (999) live on the same plugin and only re-arm
      // on their own settings change or a cold start. A sweep that reached
      // them would silently disable four other features.
      await scheduler.reschedule(
        prayerTimesByDay: _horizon(7),
        settings: _settings(),
      );

      for (final id in gateway.cancelled) {
        expect(id, inInclusiveRange(100, 214));
      }
    });

    test('the master toggle off cancels and arms nothing', () async {
      final result = await scheduler.reschedule(
        prayerTimesByDay: _horizon(7),
        settings: _settings(masterEnabled: false),
      );

      expect(result.isEmpty, isTrue);
      expect(gateway.calls, ['cancel']);
      expect(gateway.armed, isEmpty);
      expect(
        gateway.cancelled.toSet(),
        PrayerSchedulePlanner.cancellableIds.toSet(),
        reason: 'turning notifications off must clear what is already armed',
      );
    });
  });

  group('redundant reschedules are suppressed', () {
    test('an identical plan does not touch the alarm table twice', () async {
      // Settings changes, prayer-time reloads and day rollovers all trigger a
      // reschedule and several land together. Re-arming an identical plan
      // cancels every prayer id and re-adds it, and a notification due inside
      // that window can be dropped in the gap.
      await scheduler.reschedule(
        prayerTimesByDay: _horizon(3),
        settings: _settings(),
      );
      final afterFirst = gateway.calls.length;

      final second = await scheduler.reschedule(
        prayerTimesByDay: _horizon(3),
        settings: _settings(),
      );

      expect(gateway.calls, hasLength(afterFirst));
      // The result still describes the plan, so callers can report on it.
      expect(second.planned, hasLength(15));
    });

    test('a changed plan does re-arm', () async {
      await scheduler.reschedule(
        prayerTimesByDay: _horizon(3),
        settings: _settings(),
      );
      gateway.calls.clear();
      gateway.armed.clear();

      // Time passes: Fajr and Dhuhr fall out of the plan.
      clock.jumpTo(DateTime(2026, 3, 14, 13));
      await scheduler.reschedule(
        prayerTimesByDay: _horizon(3),
        settings: _settings(),
      );

      expect(gateway.calls.first, 'cancel');
      expect(gateway.armed, hasLength(13));
    });

    test(
      'a changed location re-arms even when every minute is identical',
      () async {
        // The location is rendered into the notification body. Without it in the
        // signature, moving city while the prayer minutes happened to match
        // would leave the old city's name on every armed adhan, and the guard
        // would call that "unchanged".
        await scheduler.reschedule(
          prayerTimesByDay: _horizon(3),
          settings: _settings(),
          locationName: 'القاهرة',
        );
        gateway.calls.clear();

        await scheduler.reschedule(
          prayerTimesByDay: _horizon(3),
          settings: _settings(),
          locationName: 'الرياض',
        );

        expect(gateway.calls.first, 'cancel');
        expect(gateway.calls.where((c) => c.startsWith('arm:')), hasLength(15));
      },
    );

    test('force re-arms even when nothing changed', () async {
      // What a reboot or a timezone change needs: the app's intent is
      // unchanged but the OS alarm table is not.
      await scheduler.reschedule(
        prayerTimesByDay: _horizon(3),
        settings: _settings(),
      );
      gateway.calls.clear();

      await scheduler.reschedule(
        prayerTimesByDay: _horizon(3),
        settings: _settings(),
        force: true,
      );

      expect(gateway.calls.first, 'cancel');
      expect(gateway.calls.where((c) => c.startsWith('arm:')), hasLength(15));
    });

    test('invalidate() makes the next reschedule re-arm', () async {
      await scheduler.reschedule(
        prayerTimesByDay: _horizon(3),
        settings: _settings(),
      );
      gateway.calls.clear();

      scheduler.invalidate();
      await scheduler.reschedule(
        prayerTimesByDay: _horizon(3),
        settings: _settings(),
      );

      expect(gateway.calls, isNotEmpty);
    });
  });

  group('a failed arm does not suppress the retry', () {
    test('a throwing gateway leaves the signature unrecorded', () async {
      // The bug this guards: recording the plan as "done" before it succeeded
      // meant one denied permission or exact-alarm refusal silently disabled
      // every reminder for the rest of the session.
      gateway.armThrows = Exception('SCHEDULE_EXACT_ALARM denied');

      await expectLater(
        scheduler.reschedule(
          prayerTimesByDay: _horizon(3),
          settings: _settings(),
        ),
        throwsA(isA<Exception>()),
      );

      gateway.armThrows = null;
      gateway.calls.clear();

      // The very next attempt must actually try again.
      final retry = await scheduler.reschedule(
        prayerTimesByDay: _horizon(3),
        settings: _settings(),
      );

      expect(gateway.calls.first, 'cancel');
      expect(retry.planned, hasLength(15));
      expect(gateway.armed, hasLength(15));
    });
  });

  group('preview', () {
    test('answers what would be armed without arming it', () async {
      final plan = scheduler.preview(
        prayerTimesByDay: _horizon(7),
        settings: _settings(),
      );

      expect(plan, hasLength(35));
      expect(gateway.calls, isEmpty, reason: 'preview must not touch the OS');
    });

    test('follows the clock', () async {
      expect(
        scheduler
            .preview(prayerTimesByDay: _horizon(1), settings: _settings())
            .length,
        5,
      );

      clock.jumpTo(DateTime(2026, 3, 14, 18));
      expect(
        scheduler
            .preview(prayerTimesByDay: _horizon(1), settings: _settings())
            .map((p) => p.prayer)
            .toList(),
        [PlannedPrayer.isha],
      );
    });
  });

  group('the result describes what happened', () {
    test('day count is distinct days, not entries', () async {
      final result = await scheduler.reschedule(
        prayerTimesByDay: _horizon(4),
        settings: _settings(),
      );
      expect(result.planned, hasLength(20));
      expect(result.dayCount, 4);
      expect(result.isEmpty, isFalse);
    });
  });

  group('a batching gateway', () {
    late _BatchingFakeGateway batching;
    late PrayerScheduler batchingScheduler;

    setUp(() {
      batching = _BatchingFakeGateway();
      batchingScheduler = PrayerScheduler(
        batching,
        const PrayerSchedulePlanner(),
        FixedClock(DateTime(2026, 3, 14, 4)),
      );
    });

    test('is committed once, after every arm', () async {
      await batchingScheduler.reschedule(
        prayerTimesByDay: _horizon(1),
        settings: _settings(),
      );

      expect(batching.calls.first, 'cancel');
      expect(batching.calls.last, 'commit');
      expect(batching.calls.where((c) => c == 'commit'), hasLength(1));
    });

    test('is still committed when the plan is empty', () async {
      // Master toggle off. Without the commit the native side would keep the
      // previous plan armed — turning notifications off would appear to do
      // nothing, which is the R1 defect in its new clothes.
      await batchingScheduler.reschedule(
        prayerTimesByDay: _horizon(1),
        settings: _settings(masterEnabled: false),
      );

      expect(batching.calls, ['cancel', 'commit']);
    });

    test('is not committed when the reschedule is suppressed', () async {
      await batchingScheduler.reschedule(
        prayerTimesByDay: _horizon(1),
        settings: _settings(),
      );
      batching.calls.clear();

      await batchingScheduler.reschedule(
        prayerTimesByDay: _horizon(1),
        settings: _settings(),
      );

      expect(batching.calls, isEmpty);
    });

    test('overlapping reschedules never interleave into one sweep', () async {
      // A batching gateway accumulates a whole sweep in ONE buffer with nothing
      // to tell two senders apart. Interleaved, the second sweep's cancel
      // empties it mid-flight and the first sweep's commit applies a plan with
      // most of its alarms missing — a user left with two prayers armed out of
      // ten and no error anywhere.
      batching.slowArm = true;

      await Future.wait([
        batchingScheduler.reschedule(
          prayerTimesByDay: _horizon(1),
          settings: _settings(),
          force: true,
        ),
        batchingScheduler.reschedule(
          prayerTimesByDay: _horizon(1),
          settings: _settings(),
          force: true,
        ),
      ]);

      // Two complete, separated transactions: cancel ... commit, then again.
      final boundaries = batching.calls
          .where((c) => c == 'cancel' || c == 'commit')
          .toList();
      expect(boundaries, ['cancel', 'commit', 'cancel', 'commit']);

      final firstCommit = batching.calls.indexOf('commit');
      final secondCancel = batching.calls.indexOf('cancel', firstCommit);
      expect(
        batching.calls
            .sublist(0, firstCommit)
            .where((c) => c.startsWith('arm:')),
        hasLength(5),
        reason: 'the first sweep commits all five of its alarms',
      );
      expect(secondCancel, firstCommit + 1);
    });

    test('a failed sweep does not poison the ones after it', () async {
      // The queue must survive a throw, or one transient failure would silently
      // block every reschedule for the rest of the session.
      batching.armThrows = StateError('denied');
      await expectLater(
        batchingScheduler.reschedule(
          prayerTimesByDay: _horizon(1),
          settings: _settings(),
        ),
        throwsStateError,
      );

      batching.armThrows = null;
      batching.calls.clear();
      await batchingScheduler.reschedule(
        prayerTimesByDay: _horizon(1),
        settings: _settings(),
      );

      expect(batching.calls.last, 'commit');
    });

    test('a failed commit does not advance the signature', () async {
      // The plan was computed and sent but never applied. If the guard recorded
      // it as done, every retry for the rest of the session would be skipped
      // and the user would have no alarms at all.
      batching.commitThrows = StateError('ledger write failed');

      await expectLater(
        batchingScheduler.reschedule(
          prayerTimesByDay: _horizon(1),
          settings: _settings(),
        ),
        throwsStateError,
      );

      batching.commitThrows = null;
      batching.calls.clear();
      await batchingScheduler.reschedule(
        prayerTimesByDay: _horizon(1),
        settings: _settings(),
      );

      expect(batching.calls, contains('commit'));
    });
  });
}
