import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/time/clock.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';
import 'package:wadhakir/features/pray_times/services/fallback_prayer_alarm_gateway.dart';
import 'package:wadhakir/features/pray_times/services/prayer_schedule_planner.dart';
import 'package:wadhakir/features/pray_times/services/prayer_scheduler.dart';

class _RecordingGateway implements PrayerAlarmGateway {
  final String name;
  final List<String> calls = [];
  final List<int> armedIds = [];

  /// Ids whose [arm] should throw, standing in for an OEM that refuses
  /// `setAlarmClock` or a Kotlin regression.
  final Set<int> failOnArm = {};
  Object? cancelThrows;

  _RecordingGateway(this.name);

  @override
  Future<void> cancelIds(Iterable<int> ids) async {
    calls.add('cancel');
    final failure = cancelThrows;
    if (failure != null) throw failure;
  }

  @override
  Future<void> arm(
    PlannedPrayerNotification planned, {
    String? locationName,
  }) async {
    if (failOnArm.contains(planned.id)) {
      calls.add('arm-failed:${planned.id}');
      throw PlatformException(code: 'EXACT_ALARM_DENIED');
    }
    calls.add('arm:${planned.id}');
    armedIds.add(planned.id);
  }
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

void main() {
  late _RecordingGateway native;
  late _RecordingGateway plugin;
  late FallbackPrayerAlarmGateway gateway;
  late PrayerScheduler scheduler;
  final degradedWith = <Object>[];

  setUp(() {
    degradedWith.clear();
    native = _RecordingGateway('native');
    plugin = _RecordingGateway('plugin');
    gateway = FallbackPrayerAlarmGateway(
      native,
      plugin,
      onDegraded: (error, _) => degradedWith.add(error),
    );
    scheduler = PrayerScheduler(
      gateway,
      const PrayerSchedulePlanner(),
      // 04:00 — before Fajr, so a whole day is still schedulable.
      FixedClock(DateTime(2026, 3, 14, 4)),
    );
  });

  Future<void> runSweep({int days = 2}) => scheduler.reschedule(
    prayerTimesByDay: _horizon(days),
    settings: NotificationSettingsModel.defaultSettings().copyWith(
      masterEnabled: true,
    ),
  );

  test('a healthy primary is the only gateway touched', () async {
    await runSweep();

    expect(native.armedIds, hasLength(10));
    expect(plugin.calls, isEmpty);
    expect(gateway.isDegraded, isFalse);
    expect(degradedWith, isEmpty);
  });

  group('when the primary fails mid-sweep', () {
    /// Fails on the third alarm — two already armed natively, seven still to
    /// come. This is the state a naive try/catch leaves broken.
    setUp(
      () => native.failOnArm.add(
        PrayerSchedulePlanner.idFor(PlannedPrayer.asr, 0),
      ),
    );

    test(
      'the whole plan ends up on the secondary, exactly once each',
      () async {
        await runSweep();

        expect(plugin.armedIds, hasLength(10));
        expect(plugin.armedIds.toSet(), hasLength(10));
      },
    );

    test('the entry that failed is armed too, not skipped', () async {
      // It was never armed anywhere — dropping it would silently cost the user
      // one adhan, which is the failure mode hardest to notice.
      await runSweep();

      expect(
        plugin.armedIds,
        contains(PrayerSchedulePlanner.idFor(PlannedPrayer.asr, 0)),
      );
    });

    test(
      'the primary table is dropped before the secondary is filled',
      () async {
        // Leaving two native alarms armed alongside a full plugin schedule would
        // sound those two adhans twice, seconds apart.
        await runSweep();

        final nativeClears = native.calls.where((c) => c == 'cancel').length;
        expect(
          nativeClears,
          2,
          reason: 'the opening sweep, then the drop on failure',
        );
        expect(
          native.calls.indexOf('cancel'),
          lessThan(native.calls.indexOf('arm:100')),
        );
        expect(plugin.calls.first, 'cancel');
      },
    );

    test('the replay keeps the planner\'s order', () async {
      await runSweep();

      final sorted = [...plugin.armedIds]..sort();
      expect(plugin.armedIds, sorted);
    });

    test('it reports why, once', () async {
      await runSweep();

      expect(degradedWith, hasLength(1));
      expect(degradedWith.single, isA<PlatformException>());
    });

    test('it never fails back, even once the primary recovers', () async {
      // Flapping between two alarm owners is the one state neither can
      // reconcile: each believes it holds the table, and neither's cancel
      // sweep reaches the other's alarms.
      await runSweep();
      native.failOnArm.clear();
      native.calls.clear();
      scheduler.invalidate();
      await runSweep();

      expect(native.calls, isEmpty);
      expect(gateway.isDegraded, isTrue);
      expect(degradedWith, hasLength(1));
    });
  });

  group('degrading from a native-sized plan', () {
    // Twenty days of horizon. The native path is handed sixty, which allocates
    // ids far beyond the twelve days the plugin's cancel sweep can reach.
    setUp(
      () => native.failOnArm.add(
        PrayerSchedulePlanner.idFor(PlannedPrayer.fajr, 0),
      ),
    );

    test(
      'the plugin is never armed with an id its sweep cannot cancel',
      () async {
        // Otherwise switching the adhan off, or changing its sound, would leave
        // the originals firing for weeks with nothing able to take them back.
        await runSweep(days: 20);

        final reachable = PrayerSchedulePlanner.cancellableIds.toSet();
        expect(plugin.armedIds, isNotEmpty);
        expect(
          plugin.armedIds.where((id) => !reachable.contains(id)),
          isEmpty,
          reason: 'every replayed id must be inside cancellableIds',
        );
      },
    );

    test(
      'later sweeps stay truncated too, not just the one that failed',
      () async {
        await runSweep(days: 20);
        plugin.armedIds.clear();
        scheduler.invalidate();

        await runSweep(days: 20);

        final reachable = PrayerSchedulePlanner.cancellableIds.toSet();
        expect(plugin.armedIds, isNotEmpty);
        expect(plugin.armedIds.where((id) => !reachable.contains(id)), isEmpty);
      },
    );

    test('everything inside the window is still armed', () async {
      // Truncation must cost only the days the plugin could never own, not the
      // near ones the user actually depends on.
      await runSweep(days: 20);

      expect(
        plugin.armedIds,
        contains(PrayerSchedulePlanner.idFor(PlannedPrayer.fajr, 0)),
      );
      expect(
        plugin.armedIds,
        contains(PrayerSchedulePlanner.idFor(PlannedPrayer.isha, 11)),
      );
    });
  });

  test(
    'a primary that cannot even clear degrades before arming anything',
    () async {
      native.cancelThrows = MissingPluginException('no native bridge');

      await runSweep();

      expect(native.armedIds, isEmpty);
      expect(plugin.armedIds, hasLength(10));
      expect(gateway.isDegraded, isTrue);
    },
  );
}
