import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';
import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/data/repositories/salah_tracker_repository_impl.dart';
import 'package:wadhakir/domain/usecases/clear_salah_log_usecase.dart';
import 'package:wadhakir/domain/usecases/get_salah_log_stream_usecase.dart';
import 'package:wadhakir/domain/usecases/get_salah_log_usecase.dart';
import 'package:wadhakir/domain/usecases/set_salah_log_usecase.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_cubit.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_state.dart';

SalahTrackerCubit _buildCubit(SalahTrackerRepositoryImpl repo) {
  return SalahTrackerCubit(
    getLogUseCase: GetSalahLogUseCase(repo),
    setLogUseCase: SetSalahLogUseCase(repo),
    getLogStreamUseCase: GetSalahLogStreamUseCase(repo),
    clearLogUseCase: ClearSalahLogUseCase(repo),
  );
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late SalahTrackerRepositoryImpl repo;
  late SalahTrackerCubit cubit;
  final today = DateTime.now();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = SalahTrackerRepositoryImpl(prefs);
    cubit = _buildCubit(repo);
    await _settle();
  });

  tearDown(() async {
    await cubit.close();
    repo.dispose();
  });

  test('loads an empty log into a Loaded state', () {
    expect(cubit.state, isA<SalahTrackerLoaded>());
    final state = cubit.state as SalahTrackerLoaded;
    expect(state.currentStreak, 0);
    expect(state.todayPrayedCount, 0);
    expect(state.totalMakeUp, 0);
  });

  test('marking missed increments make-up, then qada decrements it', () async {
    await cubit.logFard(today, PrayerSlot.fajr, PrayerStatus.missed);
    await _settle();
    var state = cubit.state as SalahTrackerLoaded;
    expect(state.todayStatuses[PrayerSlot.fajr], PrayerStatus.missed);
    expect(state.log.makeUpFor(PrayerSlot.fajr), 1);
    expect(state.totalMakeUp, 1);

    await cubit.logFard(today, PrayerSlot.fajr, PrayerStatus.qada);
    await _settle();
    state = cubit.state as SalahTrackerLoaded;
    expect(state.todayStatuses[PrayerSlot.fajr], PrayerStatus.qada);
    expect(state.log.makeUpFor(PrayerSlot.fajr), 0);
    expect(state.totalMakeUp, 0);
  });

  test(
    'cycleFard walks notLogged -> auto -> qada -> missed -> notLogged',
    () async {
      // notLogged -> onTime (auto-classified passed in)
      await cubit.cycleFard(today, PrayerSlot.dhuhr, PrayerStatus.onTime);
      await _settle();
      expect(
        (cubit.state as SalahTrackerLoaded).todayStatuses[PrayerSlot.dhuhr],
        PrayerStatus.onTime,
      );

      // onTime -> qada
      await cubit.cycleFard(today, PrayerSlot.dhuhr, PrayerStatus.onTime);
      await _settle();
      expect(
        (cubit.state as SalahTrackerLoaded).todayStatuses[PrayerSlot.dhuhr],
        PrayerStatus.qada,
      );

      // qada -> missed (make-up +1)
      await cubit.cycleFard(today, PrayerSlot.dhuhr, PrayerStatus.onTime);
      await _settle();
      var state = cubit.state as SalahTrackerLoaded;
      expect(state.todayStatuses[PrayerSlot.dhuhr], PrayerStatus.missed);
      expect(state.log.makeUpFor(PrayerSlot.dhuhr), 1);

      // missed -> notLogged (make-up -1)
      await cubit.cycleFard(today, PrayerSlot.dhuhr, PrayerStatus.onTime);
      await _settle();
      state = cubit.state as SalahTrackerLoaded;
      expect(state.todayStatuses[PrayerSlot.dhuhr], PrayerStatus.notLogged);
      expect(state.log.makeUpFor(PrayerSlot.dhuhr), 0);
    },
  );

  test('completing all five fard today yields a streak of 1', () async {
    for (final slot in PrayerSlot.values) {
      await cubit.logFard(today, slot, PrayerStatus.onTime);
    }
    await _settle();
    final state = cubit.state as SalahTrackerLoaded;
    expect(state.todayPrayedCount, 5);
    expect(state.currentStreak, 1);
  });

  test('makeUpOne pays down only existing debt (never negative)', () async {
    await cubit.adjustMakeUp(PrayerSlot.asr, 3);
    await _settle();
    expect(
      (cubit.state as SalahTrackerLoaded).log.makeUpFor(PrayerSlot.asr),
      3,
    );

    await cubit.makeUpOne(PrayerSlot.asr);
    await _settle();
    expect(
      (cubit.state as SalahTrackerLoaded).log.makeUpFor(PrayerSlot.asr),
      2,
    );

    // Drain past zero — stays at 0.
    for (var i = 0; i < 5; i++) {
      await cubit.makeUpOne(PrayerSlot.asr);
      await _settle();
    }
    expect(
      (cubit.state as SalahTrackerLoaded).log.makeUpFor(PrayerSlot.asr),
      0,
    );
  });

  group('pause (excused days)', () {
    test('startPause excuses today and sets the anchor', () async {
      await cubit.startPause();
      await _settle();
      final log = (cubit.state as SalahTrackerLoaded).log;
      expect(log.isExcusedDay(today), isTrue);
      expect(log.excusedSince, SalahLogModel.dateKey(today));
    });

    test(
      'logging a fard on an excused day accrues no qada — the core bug',
      () async {
        await cubit.startPause();
        await _settle();
        await cubit.logFard(today, PrayerSlot.fajr, PrayerStatus.missed);
        await _settle();
        final log = (cubit.state as SalahTrackerLoaded).log;
        expect(log.totalMakeUp, 0);
        expect(log.makeUpFor(PrayerSlot.fajr), 0);
      },
    );

    test('pausing unwinds qada already accrued for that day', () async {
      await cubit.logFard(today, PrayerSlot.fajr, PrayerStatus.missed);
      await _settle();
      expect(
        (cubit.state as SalahTrackerLoaded).log.makeUpFor(PrayerSlot.fajr),
        1,
      );

      await cubit.startPause();
      await _settle();
      final log = (cubit.state as SalahTrackerLoaded).log;
      expect(log.makeUpFor(PrayerSlot.fajr), 0);
      expect(log.totalMakeUp, 0);
    });

    test('endPause clears the anchor but keeps the historical days', () async {
      await cubit.startPause();
      await _settle();
      await cubit.endPause();
      await _settle();
      final log = (cubit.state as SalahTrackerLoaded).log;
      expect(log.excusedSince, isNull);
      // The day it covered stays on the record.
      expect(log.isExcusedDay(today), isTrue);
    });

    test('syncPause fills forward from an anchor set days ago', () async {
      // Simulate a pause started 3 days ago that the app never saw roll over.
      final start = today.subtract(const Duration(days: 3));
      final seeded = SalahLogModel.defaultSettings().copyWith(
        excusedSince: SalahLogModel.dateKey(start),
      );
      await repo.setLog(seeded);
      await _settle();

      await cubit.syncPause();
      await _settle();

      final log = (cubit.state as SalahTrackerLoaded).log;
      for (var i = 0; i <= 3; i++) {
        expect(
          log.isExcusedDay(today.subtract(Duration(days: i))),
          isTrue,
          reason: 'day -$i should have been filled in',
        );
      }
      expect(
        log.isExcusedDay(today.subtract(const Duration(days: 4))),
        isFalse,
      );
    });

    test('syncPause is a no-op when not paused', () async {
      await cubit.syncPause();
      await _settle();
      expect((cubit.state as SalahTrackerLoaded).log.excusedDays, isEmpty);
    });

    test('an unparseable anchor is dropped rather than looping', () async {
      final seeded = SalahLogModel.defaultSettings().copyWith(
        excusedSince: 'not-a-date',
      );
      await repo.setLog(seeded);
      await _settle();

      await cubit.syncPause();
      await _settle();
      expect((cubit.state as SalahTrackerLoaded).log.excusedSince, isNull);
    });
  });
}
