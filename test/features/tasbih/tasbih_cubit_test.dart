import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/features/tasbih/cubit/tasbih_cubit.dart';
import 'package:wadhakir/features/tasbih/data/tasbih_models.dart';
import 'package:wadhakir/features/tasbih/data/tasbih_repository.dart';

import 'fake_tasbih_feedback.dart';
import 'write_failing_prefs.dart';

/// The counting rules: rounds, auto-advance, resets, targets, the day, and
/// when things reach the disk.

/// Counts writes of the counts blob, the expensive part.
class _CountingRepository extends TasbihRepository {
  _CountingRepository([super.prefs]);

  int stateSaves = 0;

  @override
  Future<void> saveState(TasbihSnapshot snapshot, int lifetimeTotal) {
    stateSaves++;
    return super.saveState(snapshot, lifetimeTotal);
  }
}

final _noon = DateTime(2026, 10, 25, 12);

String _v2WithTarget(int target) => jsonEncode({
  'v': 2,
  'selected': 'subhan_allah',
  'day': '2026-10-25',
  'todayTotal': 0,
  'dhikr': {
    'subhan_allah': {'c': 0, 't': target, 'r': 0},
  },
});

void main() {
  late FakeTasbihFeedback feedback;
  final opened = <TasbihCubit>[];

  Future<TasbihCubit> loaded({
    Map<String, Object> stored = const {},
    DateTime Function()? now,
  }) async {
    SharedPreferences.setMockInitialValues(stored);
    final cubit = TasbihCubit(
      repository: TasbihRepository(),
      feedback: feedback,
      now: now ?? () => _noon,
    );
    opened.add(cubit);
    await cubit.load();
    return cubit;
  }

  void tap(TasbihCubit cubit, [int times = 1]) {
    for (var i = 0; i < times; i++) {
      cubit.increment();
    }
  }

  setUp(() => feedback = FakeTasbihFeedback());
  tearDown(() async {
    for (final c in opened) {
      await c.close();
    }
    opened.clear();
  });

  group('counting', () {
    test('a tap adds one to the count, today and the lifetime', () async {
      final cubit = await loaded(stored: {'electronic_tasbih_total': 100});
      tap(cubit);
      expect(cubit.state.selected.count, 1);
      expect(cubit.state.todayTotal, 1);
      expect(cubit.state.lifetimeTotal, 101);
      // Defaults: vibrate on, sound off.
      expect(feedback.taps, [(true, false)]);
    });

    test('taps before the stored counts load are ignored', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = TasbihCubit(
        repository: TasbihRepository(),
        feedback: feedback,
        now: () => _noon,
      );
      opened.add(cubit);
      cubit.increment();
      expect(cubit.state.selected.count, 0);
      expect(feedback.taps, isEmpty);
    });

    test('reaching the target finishes a round, with one feedback', () async {
      final cubit = await loaded(
        stored: {TasbihRepository.stateKey: _v2WithTarget(3)},
      );
      tap(cubit, 3);
      final s = cubit.state;
      expect(s.selected.count, 0);
      expect(s.selected.roundsToday, 1);
      expect(s.completionTick, 1);
      expect(s.lastCompletedRound, 1);
      expect(s.lastCompletedId, 'subhan_allah');
      expect(s.todayTotal, 3);
      // Two taps, then the round's own feedback INSTEAD of a third tap.
      expect(feedback.taps, hasLength(2));
      expect(feedback.rounds, [(true, false)]);

      tap(cubit, 3);
      expect(cubit.state.selected.roundsToday, 2);
      expect(cubit.state.lastCompletedRound, 2);
    });

    test('the vibrate and sound switches reach the feedback', () async {
      final cubit = await loaded();
      expect(feedback.prepares, 0, reason: 'sound is off by default');
      cubit
        ..setVibrate(false)
        ..setSound(true);
      expect(feedback.prepares, 1, reason: 'the click loads when switched on');
      tap(cubit);
      expect(feedback.taps.last, (false, true));
    });

    test('a stored sound-on loads the click when the screen opens', () async {
      await loaded(
        stored: {
          TasbihRepository.prefsKey: const TasbihPrefs(sound: true).encode(),
        },
      );
      expect(feedback.prepares, 1);
    });
  });

  group('auto-advance', () {
    test('off: the round starts again on the same dhikr', () async {
      final cubit = await loaded(
        stored: {TasbihRepository.stateKey: _v2WithTarget(2)},
      );
      tap(cubit, 2);
      expect(cubit.state.selectedIndex, 0);
    });

    test('on: moves to the next dhikr, guarded for 400 ms', () {
      fakeAsync((async) {
        SharedPreferences.setMockInitialValues({
          TasbihRepository.stateKey: _v2WithTarget(2),
        });
        final cubit = TasbihCubit(
          repository: TasbihRepository(),
          feedback: feedback,
          now: () => _noon.add(async.elapsed),
        );
        cubit.load();
        async.flushMicrotasks();
        cubit.setAutoAdvance(true);

        tap(cubit, 2);
        expect(cubit.state.selectedIndex, 1);
        expect(cubit.state.todayTotal, 2);

        // The tail of a fast burst must not spill into the next dhikr.
        tap(cubit, 3);
        async.elapse(const Duration(milliseconds: 399));
        tap(cubit);
        expect(cubit.state.selected.count, 0);
        expect(cubit.state.todayTotal, 2);

        async.elapse(const Duration(milliseconds: 2));
        tap(cubit);
        expect(cubit.state.selected.count, 1);
        expect(cubit.state.todayTotal, 3);

        cubit.close();
        async.flushMicrotasks();
      });
    });

    test('on: wraps from the last dhikr to the first', () {
      fakeAsync((async) {
        SharedPreferences.setMockInitialValues({});
        final cubit = TasbihCubit(
          repository: TasbihRepository(),
          feedback: feedback,
          now: () => _noon.add(async.elapsed),
        );
        cubit.load();
        async.flushMicrotasks();
        cubit
          ..setAutoAdvance(true)
          ..selectIndex(7)
          ..setTarget(1);
        tap(cubit);
        expect(cubit.state.selectedIndex, 0);
        cubit.close();
        async.flushMicrotasks();
      });
    });
  });

  group('choosing a dhikr', () {
    test('next and previous wrap around', () async {
      final cubit = await loaded();
      cubit.previous();
      expect(cubit.state.selectedIndex, 7);
      cubit.next();
      expect(cubit.state.selectedIndex, 0);
      cubit.selectIndex(-1);
      expect(cubit.state.selectedIndex, 7);
    });

    test('each dhikr keeps its own count', () async {
      final cubit = await loaded();
      tap(cubit, 4);
      cubit.next();
      tap(cubit, 2);
      cubit.previous();
      expect(cubit.state.selected.count, 4);
      expect(cubit.state.items[1].count, 2);
      expect(cubit.state.todayTotal, 6);
    });
  });

  group('resets', () {
    test('the counter reset keeps today and the lifetime', () async {
      final cubit = await loaded(
        stored: {TasbihRepository.stateKey: _v2WithTarget(3)},
      );
      tap(cubit, 5);
      expect(cubit.state.selected.roundsToday, 1);
      expect(cubit.state.selectedIsClear, isFalse);
      cubit.resetCurrent();
      expect(cubit.state.selected.count, 0);
      expect(cubit.state.selected.roundsToday, 0);
      expect(cubit.state.selectedIsClear, isTrue);
      expect(cubit.state.todayTotal, 5);
      expect(cubit.state.lifetimeTotal, 5);
    });

    test('the lifetime reset touches only the lifetime', () async {
      final cubit = await loaded(stored: {'electronic_tasbih_total': 50});
      tap(cubit, 2);
      cubit.resetLifetime();
      expect(cubit.state.lifetimeTotal, 0);
      expect(cubit.state.selected.count, 2);
      expect(cubit.state.todayTotal, 2);
    });
  });

  group('targets', () {
    test('a target at or below the count starts the round again', () async {
      final cubit = await loaded();
      tap(cubit, 10);
      cubit.setTarget(10);
      expect(cubit.state.selected.target, 10);
      expect(cubit.state.selected.count, 0);
    });

    test('a target above the count keeps it', () async {
      final cubit = await loaded();
      tap(cubit, 3);
      cubit.setTarget(50);
      expect(cubit.state.selected.count, 3);
    });

    test('targets are clamped to 1..9999', () async {
      final cubit = await loaded();
      cubit.setTarget(0);
      expect(cubit.state.selected.target, 1);
      cubit.setTarget(20000);
      expect(cubit.state.selected.target, TasbihTargets.max);
    });

    test('a target belongs to its dhikr', () async {
      final cubit = await loaded();
      cubit.setTarget(99);
      cubit.next();
      expect(cubit.state.selected.target, 33);
    });
  });

  group('the day', () {
    test('the midnight timer clears today and keeps the counts', () {
      fakeAsync((async) {
        final start = DateTime(2026, 10, 25, 23, 59, 50);
        SharedPreferences.setMockInitialValues({});
        final cubit = TasbihCubit(
          repository: TasbihRepository(),
          feedback: feedback,
          now: () => start.add(async.elapsed),
        );
        cubit.load();
        async.flushMicrotasks();
        cubit.setTarget(2);
        tap(cubit, 3);
        expect(cubit.state.todayTotal, 3);
        expect(cubit.state.selected.roundsToday, 1);
        expect(cubit.state.selected.count, 1);

        async.elapse(const Duration(seconds: 12));
        expect(cubit.state.snapshot.day, '2026-10-26');
        expect(cubit.state.todayTotal, 0);
        expect(cubit.state.selected.roundsToday, 0);
        expect(cubit.state.selected.count, 1, reason: 'mid-round is kept');
        expect(cubit.state.lifetimeTotal, 3);

        // And it re-arms for the night after.
        async.elapse(const Duration(hours: 24));
        expect(cubit.state.snapshot.day, '2026-10-27');

        cubit.close();
        async.flushMicrotasks();
      });
    });

    test(
      'resuming after the phone slept through midnight rolls the day',
      () async {
        var now = DateTime(2026, 10, 25, 22);
        final cubit = await loaded(now: () => now);
        tap(cubit, 2);
        now = DateTime(2026, 10, 26, 7);
        cubit.refreshDay();
        expect(cubit.state.todayTotal, 0);
        expect(cubit.state.selected.count, 2);
      },
    );

    test('a tap after midnight rolls the day before counting', () async {
      var now = DateTime(2026, 10, 25, 22);
      final cubit = await loaded(now: () => now);
      tap(cubit, 2);
      now = DateTime(2026, 10, 26, 0, 5);
      tap(cubit);
      expect(cubit.state.todayTotal, 1);
      expect(cubit.state.selected.count, 3);
    });
  });

  group('saving', () {
    test('rapid taps are written once, 500 ms after the last', () {
      fakeAsync((async) {
        SharedPreferences.setMockInitialValues({});
        late _CountingRepository repository;
        SharedPreferences.getInstance().then(
          (p) => repository = _CountingRepository(p),
        );
        async.flushMicrotasks();
        final cubit = TasbihCubit(
          repository: repository,
          feedback: feedback,
          now: () => _noon.add(async.elapsed),
        );
        cubit.load();
        async.flushMicrotasks();

        for (var i = 0; i < 10; i++) {
          cubit.increment();
          async.elapse(const Duration(milliseconds: 50));
        }
        expect(repository.stateSaves, 0);
        async.elapse(const Duration(milliseconds: 449));
        expect(repository.stateSaves, 0);
        async.elapse(const Duration(milliseconds: 2));
        expect(repository.stateSaves, 1);

        late SharedPreferences prefs;
        SharedPreferences.getInstance().then((p) => prefs = p);
        async.flushMicrotasks();
        expect(prefs.getInt('electronic_tasbih_counter'), 10);
        expect(prefs.getInt('electronic_tasbih_total'), 10);

        // Pending taps are flushed by close(), not lost.
        cubit
          ..increment()
          ..increment();
        cubit.close();
        async.flushMicrotasks();
        expect(repository.stateSaves, 2);
        expect(prefs.getInt('electronic_tasbih_counter'), 12);
      });
    });

    test('flush() writes at once, and only when something changed', () {
      fakeAsync((async) {
        SharedPreferences.setMockInitialValues({});
        late _CountingRepository repository;
        SharedPreferences.getInstance().then(
          (p) => repository = _CountingRepository(p),
        );
        async.flushMicrotasks();
        final cubit = TasbihCubit(
          repository: repository,
          feedback: feedback,
          now: () => _noon.add(async.elapsed),
        );
        cubit.load();
        async.flushMicrotasks();

        cubit.flush();
        async.flushMicrotasks();
        expect(repository.stateSaves, 0);

        cubit.increment();
        cubit.flush();
        async.flushMicrotasks();
        expect(repository.stateSaves, 1);
        // The debounce was cancelled by the flush.
        async.elapse(const Duration(seconds: 1));
        expect(repository.stateSaves, 1);

        cubit.close();
        async.flushMicrotasks();
      });
    });

    test('a finished round is written at once', () {
      fakeAsync((async) {
        SharedPreferences.setMockInitialValues({
          TasbihRepository.stateKey: _v2WithTarget(2),
        });
        late _CountingRepository repository;
        SharedPreferences.getInstance().then(
          (p) => repository = _CountingRepository(p),
        );
        async.flushMicrotasks();
        final cubit = TasbihCubit(
          repository: repository,
          feedback: feedback,
          now: () => _noon.add(async.elapsed),
        );
        cubit.load();
        async.flushMicrotasks();

        cubit
          ..increment()
          ..increment();
        async.flushMicrotasks();
        expect(repository.stateSaves, 1);
        cubit.close();
        async.flushMicrotasks();
      });
    });

    test('a switch flipped before the stored prefs load is not saved over '
        'them', () async {
      // The selector and the pill are on screen while load() runs. Saving
      // the defaults plus that one switch would wipe every other choice.
      const mine = TasbihPrefs(
        mode: TasbihMode.beads,
        vibrate: false,
        sound: true,
        autoAdvance: true,
      );
      SharedPreferences.setMockInitialValues({
        TasbihRepository.prefsKey: mine.encode(),
      });
      final cubit = TasbihCubit(
        repository: TasbihRepository(),
        feedback: feedback,
        now: () => _noon,
      );
      opened.add(cubit);
      final loading = cubit.load();
      cubit
        ..setMode(TasbihMode.ring)
        ..setVibrate(true)
        ..setSound(false)
        ..setAutoAdvance(false)
        ..setKeepScreenOn(false);
      await loading;
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.prefs, mine);
      final prefs = await SharedPreferences.getInstance();
      expect(
        TasbihPrefs.decode(prefs.getString(TasbihRepository.prefsKey)),
        mine,
      );
    });

    test('a load whose own writes fail still opens and counts', () async {
      // Before, the exception escaped load() and the screen stayed blank,
      // every tap ignored.
      final cubit = TasbihCubit(
        repository: TasbihRepository(
          WriteFailingPrefs({
            'electronic_tasbih_counter': 21,
            'electronic_tasbih_target': 33,
          }),
        ),
        feedback: feedback,
        now: () => _noon,
      );
      opened.add(cubit);
      await cubit.load();
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.selected.count, 21);
      tap(cubit);
      expect(cubit.state.selected.count, 22);
    });

    test('prefs survive a reopen', () async {
      final cubit = await loaded();
      cubit
        ..setMode(TasbihMode.beads)
        ..setAutoAdvance(true);
      await Future<void>.delayed(Duration.zero);
      final stored = await TasbihRepository().load(_noon);
      expect(stored.prefs.mode, TasbihMode.beads);
      expect(stored.prefs.autoAdvance, isTrue);
    });
  });

  test('wantsScreenOn follows the switch, and focus mode always', () async {
    final cubit = await loaded();
    expect(cubit.state.wantsScreenOn, isTrue);
    cubit.setKeepScreenOn(false);
    expect(cubit.state.wantsScreenOn, isFalse);
    cubit.setMode(TasbihMode.focus);
    expect(cubit.state.wantsScreenOn, isTrue);
    cubit.setMode(TasbihMode.ring);
    expect(cubit.state.wantsScreenOn, isFalse);
  });
}
