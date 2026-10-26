import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/tasbih_models.dart';
import '../data/tasbih_repository.dart';
import '../services/tasbih_feedback.dart';
import 'tasbih_state.dart';

/// The tasbih's rules. Provided by the screen itself, not app-wide: nothing
/// else reads it, so it costs nothing at launch and holds no timers while the
/// screen is closed.
class TasbihCubit extends Cubit<TasbihState> {
  TasbihCubit({
    required this.repository,
    required this.feedback,
    DateTime Function()? now,
    this.saveDelay = const Duration(milliseconds: 500),
    this.advanceGuard = const Duration(milliseconds: 400),
  }) : _now = now ?? DateTime.now,
       super(TasbihState.initial(tasbihDayKey((now ?? DateTime.now)())));

  final TasbihRepository repository;

  /// Public so the screen can read the `supports*` flags from the same
  /// instance the cubit drives.
  final TasbihFeedback feedback;

  /// Injected so tests can drive midnight under `fakeAsync`.
  final DateTime Function() _now;

  /// Taps are saved this long after the last one. Writing on every tap of a
  /// fast count is dozens of disk writes a second for nothing; at worst a
  /// killed process loses this much counting.
  final Duration saveDelay;

  /// After auto-advance, taps are ignored this long, so the tail of a fast
  /// burst does not spill into the next dhikr.
  final Duration advanceGuard;

  Timer? _saveTimer;
  Timer? _guardTimer;
  Timer? _midnightTimer;
  bool _dirty = false;
  bool _guarded = false;

  Future<void> load() async {
    final stored = await repository.load(_now());
    if (isClosed) return;
    emit(
      state.copyWith(
        loading: false,
        snapshot: stored.snapshot,
        prefs: stored.prefs,
        lifetimeTotal: stored.lifetimeTotal,
      ),
    );
    if (stored.prefs.sound && feedback.supportsSound) {
      unawaited(feedback.prepare());
    }
    _scheduleMidnight();
  }

  /// One tasbiha.
  void increment() {
    if (isClosed || state.loading || _guarded) return;
    _rollIfNeeded();

    final snapshot = state.snapshot;
    final current = snapshot.selected;
    var count = current.count + 1;
    var rounds = current.roundsToday;
    final completed = count >= current.target;
    if (completed) {
      rounds += 1;
      count = 0;
    }

    final items = [...snapshot.items];
    items[snapshot.selectedIndex] = current.copyWith(
      count: count,
      roundsToday: rounds,
    );
    var selectedIndex = snapshot.selectedIndex;
    if (completed && state.prefs.autoAdvance) {
      selectedIndex = (selectedIndex + 1) % items.length;
      _startGuard();
    }

    emit(
      state.copyWith(
        snapshot: snapshot.copyWith(
          items: items,
          selectedIndex: selectedIndex,
          todayTotal: snapshot.todayTotal + 1,
        ),
        lifetimeTotal: state.lifetimeTotal + 1,
        completionTick: completed ? state.completionTick + 1 : null,
        lastCompletedRound: completed ? rounds : null,
        lastCompletedId: completed ? current.id : null,
      ),
    );

    final prefs = state.prefs;
    if (completed) {
      feedback.roundComplete(vibrate: prefs.vibrate, sound: prefs.sound);
      // A finished round is worth a write of its own.
      _saveNow();
    } else {
      feedback.tap(vibrate: prefs.vibrate, sound: prefs.sound);
      _scheduleSave();
    }
  }

  void selectIndex(int index) {
    if (isClosed || state.loading) return;
    final n = state.items.length;
    final i = ((index % n) + n) % n;
    if (i == state.selectedIndex) return;
    emit(state.copyWith(snapshot: state.snapshot.copyWith(selectedIndex: i)));
    _saveNow();
  }

  void next() => selectIndex(state.selectedIndex + 1);
  void previous() => selectIndex(state.selectedIndex - 1);

  /// A new target for the selected dhikr. When the count already meets it,
  /// the count starts again rather than sitting at or past the target — the
  /// same rule the old screen had.
  void setTarget(int target) {
    if (isClosed || state.loading) return;
    final t = TasbihTargets.clamp(target);
    final current = state.selected;
    if (t == current.target) return;
    _replaceSelected(
      current.copyWith(target: t, count: t <= current.count ? 0 : null),
    );
    _saveNow();
  }

  /// The selected dhikr's count and today's rounds. Today's and the lifetime
  /// total are kept: those tasbihat were said.
  void resetCurrent() {
    if (isClosed || state.loading) return;
    _replaceSelected(state.selected.copyWith(count: 0, roundsToday: 0));
    _saveNow();
  }

  void resetLifetime() {
    if (isClosed || state.loading) return;
    emit(state.copyWith(lifetimeTotal: 0));
    _saveNow();
  }

  void setMode(TasbihMode mode) => _setPrefs(state.prefs.copyWith(mode: mode));
  void setVibrate(bool on) => _setPrefs(state.prefs.copyWith(vibrate: on));
  void setAutoAdvance(bool on) =>
      _setPrefs(state.prefs.copyWith(autoAdvance: on));
  void setKeepScreenOn(bool on) =>
      _setPrefs(state.prefs.copyWith(keepScreenOn: on));

  void setSound(bool on) {
    if (isClosed || state.loading) return;
    if (on && feedback.supportsSound) unawaited(feedback.prepare());
    _setPrefs(state.prefs.copyWith(sound: on));
  }

  /// The app came back. The phone may have slept through midnight, when a
  /// Dart timer does not run.
  void refreshDay() {
    if (isClosed || state.loading) return;
    _rollIfNeeded();
    _scheduleMidnight();
  }

  /// Writes any pending counts now: the app is going to the background, where
  /// it may be killed without another word.
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (!_dirty) return;
    _dirty = false;
    try {
      await repository.saveState(state.snapshot, state.lifetimeTotal);
    } catch (e) {
      // Kept dirty, so the next tap, pause or close tries again. A failed
      // write must never take the counting down with it.
      _dirty = true;
      debugPrint('TasbihCubit: save failed: $e');
    }
  }

  @override
  Future<void> close() async {
    _guardTimer?.cancel();
    _midnightTimer?.cancel();
    await flush();
    return super.close();
  }

  void _replaceSelected(DhikrProgress progress) {
    final items = [...state.items];
    items[state.selectedIndex] = progress;
    emit(state.copyWith(snapshot: state.snapshot.copyWith(items: items)));
  }

  /// Ignored until [load] is done, like every other change. Until then
  /// [TasbihState.prefs] is the defaults, and saving the defaults plus this
  /// one switch would overwrite every other choice the user had made. The
  /// selector and the pill are on screen during that moment, so it happens.
  void _setPrefs(TasbihPrefs prefs) {
    if (isClosed || state.loading || prefs == state.prefs) return;
    emit(state.copyWith(prefs: prefs));
    unawaited(repository.savePrefs(prefs));
  }

  /// Returns whether the day changed.
  bool _rollIfNeeded() {
    final today = tasbihDayKey(_now());
    if (today == state.snapshot.day) return false;
    emit(state.copyWith(snapshot: state.snapshot.rolledTo(today)));
    _saveNow();
    return true;
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = _now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    var wait = midnight.difference(now);
    if (wait.isNegative) wait = Duration.zero;
    // A second past, so the clock read inside the callback is firmly in the
    // new day. Local-time construction above already accounts for DST.
    _midnightTimer = Timer(wait + const Duration(seconds: 1), () {
      if (isClosed) return;
      _rollIfNeeded();
      _scheduleMidnight();
    });
  }

  void _startGuard() {
    _guarded = true;
    _guardTimer?.cancel();
    _guardTimer = Timer(advanceGuard, () => _guarded = false);
  }

  void _scheduleSave() {
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, () => unawaited(flush()));
  }

  void _saveNow() {
    _dirty = true;
    unawaited(flush());
  }
}
