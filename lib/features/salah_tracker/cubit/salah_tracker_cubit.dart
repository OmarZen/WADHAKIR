import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';
import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/domain/usecases/get_salah_log_usecase.dart';
import 'package:wadhakir/domain/usecases/set_salah_log_usecase.dart';
import 'package:wadhakir/domain/usecases/get_salah_log_stream_usecase.dart';
import 'package:wadhakir/domain/usecases/clear_salah_log_usecase.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_state.dart';
import 'package:wadhakir/features/salah_tracker/services/salah_stats_service.dart';

/// Cubit for the Salah (prayer) tracker. Loads the log, subscribes to the
/// repository stream (single source of truth), and exposes logging + make-up
/// mutations plus derived streak/stats. Mirrors WirdCubit.
class SalahTrackerCubit extends Cubit<SalahTrackerState> {
  final GetSalahLogUseCase _getLogUseCase;
  final SetSalahLogUseCase _setLogUseCase;
  final GetSalahLogStreamUseCase _getLogStreamUseCase;
  final ClearSalahLogUseCase _clearLogUseCase;
  final SalahStatsService _stats;

  StreamSubscription? _logSubscription;

  /// The calendar day "today" stats are anchored to. Advanced by
  /// [refreshIfStale] on app resume / day rollover.
  DateTime _today;

  SalahTrackerCubit({
    required this._getLogUseCase,
    required this._setLogUseCase,
    required this._getLogStreamUseCase,
    required this._clearLogUseCase,
    SalahStatsService? stats,
  }) : _stats = stats ?? const SalahStatsService(),
       _today = _normalizedNow(),
       super(const SalahTrackerInitial()) {
    loadLog();
    _listenToLogChanges();
  }

  static DateTime _normalizedNow() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  void _listenToLogChanges() {
    _logSubscription = _getLogStreamUseCase().listen(
      _emitWithLog,
      onError: (Object error) => emit(SalahTrackerError(error.toString())),
    );
  }

  void _emitWithLog(SalahLogModel log) {
    final today = _today;
    final todayKey = SalahLogModel.dateKey(today);
    emit(
      SalahTrackerLoaded(
        log: log,
        today: today,
        currentStreak: _stats.currentStreak(log, today),
        bestStreak: _stats.bestStreak(log),
        todayStatuses: log.statusesFor(todayKey),
        todayCompletion: _stats.completionFraction(log, today),
        totalMakeUp: log.totalMakeUp,
      ),
    );
  }

  Future<void> loadLog() async {
    try {
      final log = await _getLogUseCase();
      _emitWithLog(log);
      // Catch up any days that passed while the app was closed during a pause.
      // ignore: unawaited_futures
      syncPause();
    } catch (e, st) {
      developer.log('🟥 SalahTrackerCubit.loadLog: $e\n$st');
      emit(SalahTrackerError(e.toString()));
    }
  }

  SalahLogModel? get _currentLog {
    final s = state;
    return s is SalahTrackerLoaded ? s.log : null;
  }

  /// Authoritative log to mutate from. Always reads the repository (whose cache
  /// is updated synchronously inside setLog) rather than the emitted [state],
  /// which lags by a microtask via the stream — otherwise rapid sequential
  /// writes would each read a stale log and clobber one another.
  Future<SalahLogModel> _ensureLog() => _getLogUseCase();

  Future<void> _persist(SalahLogModel log) async {
    try {
      await _setLogUseCase(log);
      // State re-emits via the repository stream.
    } catch (e, st) {
      developer.log('🟥 SalahTrackerCubit._persist: $e\n$st');
      emit(SalahTrackerError(e.toString()));
    }
  }

  /// Set [slot] on [date] to [status], adjusting the qada (make-up) debt on the
  /// missed↔not-missed transition so each missed prayer is owed exactly once.
  Future<void> logFard(
    DateTime date,
    PrayerSlot slot,
    PrayerStatus status,
  ) async {
    final current = await _ensureLog();
    final key = SalahLogModel.dateKey(_normalize(date));

    // An excused day owes nothing, so nothing can be logged against it and no
    // qada can accrue from it. Without this guard the branch below charges a
    // make-up debt for prayers that were never obligatory.
    if (current.isExcused(key)) return;

    final old = current.fardStatus(key, slot);
    if (old == status) return;

    var next = current.setFard(key, slot, status);
    if (status == PrayerStatus.missed && old != PrayerStatus.missed) {
      next = next.adjustMakeUp(slot, 1);
    } else if (old == PrayerStatus.missed && status != PrayerStatus.missed) {
      next = next.adjustMakeUp(slot, -1);
    }
    await _persist(next);
  }

  /// Mark [date] excused, or lift it. See [SalahLogModel.excusedDays].
  ///
  /// Marking a day excused unwinds any qada that day had already accrued —
  /// otherwise a user who logs a missed Fajr and *then* pauses would be left
  /// owing a prayer the ruling does not require of her.
  Future<void> setExcused(DateTime date, bool excused) async {
    final current = await _ensureLog();
    await _persist(_applyExcused(current, _normalize(date), excused));
  }

  /// Pure helper shared by [setExcused], [startPause] and [syncPause].
  SalahLogModel _applyExcused(SalahLogModel log, DateTime day, bool excused) {
    final key = SalahLogModel.dateKey(day);
    if (log.isExcused(key) == excused) return log;
    var next = log;
    if (excused) {
      for (final slot in PrayerSlot.values) {
        if (log.fardStatus(key, slot) == PrayerStatus.missed) {
          next = next.adjustMakeUp(slot, -1);
        }
      }
    }
    // setExcused clears the day's statuses itself, so run it after the debt
    // above has been read off the pre-change log.
    return next.setExcused(key, excused);
  }

  /// Begin an open-ended pause starting today.
  ///
  /// One tap in, one tap out — the user is never asked to predict how long the
  /// pause will last. [syncPause] fills each subsequent day in as it arrives.
  Future<void> startPause() async {
    final current = await _ensureLog();
    if (current.excusedSince != null) return;
    final today = _normalizedNow();
    final next = _applyExcused(
      current,
      today,
      true,
    ).copyWith(excusedSince: SalahLogModel.dateKey(today));
    await _persist(next);
  }

  /// End the current pause. Days already marked excused stay excused — they are
  /// the historical record; only the open-ended state ends.
  Future<void> endPause() async {
    final current = await _ensureLog();
    if (current.excusedSince == null) return;
    await _persist(current.copyWith(clearExcusedSince: true));
  }

  /// While a pause is active, mark every day from its start through today as
  /// excused. Idempotent, and a no-op when not paused.
  ///
  /// Called on load and on day rollover, so a pause that spans midnight (or a
  /// week of the app not being opened) is filled in without the user tapping
  /// anything.
  Future<void> syncPause() async {
    final current = await _ensureLog();
    final since = current.excusedSince;
    if (since == null) return;
    final start = DateTime.tryParse(since);
    if (start == null) {
      // Unparseable anchor — drop it rather than loop forever.
      await _persist(current.copyWith(clearExcusedSince: true));
      return;
    }
    final today = _normalizedNow();
    var next = current;
    var cursor = _normalize(start);
    while (!cursor.isAfter(today)) {
      next = _applyExcused(next, cursor, true);
      cursor = cursor.add(const Duration(days: 1));
    }
    if (next == current) return;
    await _persist(next);
  }

  /// Mark the inclusive range [from]..[to] excused, or lift it. Same qada
  /// unwinding as [setExcused], applied per day.
  Future<void> setExcusedRange(DateTime from, DateTime to, bool excused) async {
    final current = await _ensureLog();
    var next = current;
    var cursor = _normalize(from);
    final end = _normalize(to);
    while (!cursor.isAfter(end)) {
      final key = SalahLogModel.dateKey(cursor);
      if (next.isExcused(key) != excused) {
        if (excused) {
          for (final slot in PrayerSlot.values) {
            if (next.fardStatus(key, slot) == PrayerStatus.missed) {
              next = next.adjustMakeUp(slot, -1);
            }
          }
        }
        next = next.setExcused(key, excused);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    if (next == current) return;
    await _persist(next);
  }

  /// Quick tap cycle for the prayer card: notLogged → [autoClassified]
  /// (onTime/late) → qada → missed → notLogged.
  Future<void> cycleFard(
    DateTime date,
    PrayerSlot slot,
    PrayerStatus autoClassified,
  ) async {
    final current = await _ensureLog();
    final key = SalahLogModel.dateKey(_normalize(date));
    final cur = current.fardStatus(key, slot);
    final PrayerStatus next;
    switch (cur) {
      case PrayerStatus.notLogged:
        next = autoClassified;
      case PrayerStatus.onTime:
      case PrayerStatus.late:
        next = PrayerStatus.qada;
      case PrayerStatus.qada:
        next = PrayerStatus.missed;
      case PrayerStatus.missed:
        next = PrayerStatus.notLogged;
    }
    await logFard(date, slot, next);
  }

  /// Toggle a single Sunnah rawatib [unit] on [date].
  Future<void> toggleRawatib(DateTime date, RawatibUnit unit) async {
    final current = await _ensureLog();
    final key = SalahLogModel.dateKey(_normalize(date));
    final done = current.rawatibDone(key, unit);
    await _persist(current.setRawatib(key, unit, !done));
  }

  /// Toggle the Witr prayer on [date].
  Future<void> toggleWitr(DateTime date) async {
    final current = await _ensureLog();
    final key = SalahLogModel.dateKey(_normalize(date));
    await _persist(current.setWitr(key, !current.witrDone(key)));
  }

  /// Set the legacy qada debt for [slot] (floored at 0).
  Future<void> setMakeUp(PrayerSlot slot, int value) async {
    final current = await _ensureLog();
    await _persist(current.setMakeUp(slot, value));
  }

  Future<void> adjustMakeUp(PrayerSlot slot, int delta) async {
    final current = await _ensureLog();
    await _persist(current.adjustMakeUp(slot, delta));
  }

  /// Pay down one outstanding make-up for [slot] (قضيتها).
  Future<void> makeUpOne(PrayerSlot slot) async {
    final current = await _ensureLog();
    if (current.makeUpFor(slot) <= 0) return;
    await _persist(current.adjustMakeUp(slot, -1));
  }

  Future<void> setTrackNawafil(bool enabled) async {
    final current = await _ensureLog();
    if (current.trackNawafil == enabled) return;
    await _persist(current.copyWith(trackNawafil: enabled));
  }

  Future<void> resetLog() async {
    try {
      await _clearLogUseCase();
    } catch (e, st) {
      developer.log('🟥 SalahTrackerCubit.resetLog: $e\n$st');
      emit(SalahTrackerError(e.toString()));
    }
  }

  /// If the calendar day advanced (app resumed across midnight), re-anchor
  /// "today" and re-emit so the streak/today rows are correct. Cheap no-op
  /// otherwise. Call from the app-resume lifecycle hook.
  void refreshIfStale() {
    final now = _normalizedNow();
    if (now.isAfter(_today)) {
      _today = now;
      final log = _currentLog;
      if (log != null) _emitWithLog(log);
      // A pause that spanned midnight must cover the new day too, otherwise
      // today would silently start owing prayers again.
      // ignore: unawaited_futures
      syncPause();
    }
  }

  /// Auto-classify a fard logged now against today's prayer times.
  PrayerStatus classify(
    PrayerTimesModel model,
    PrayerSlot slot,
    DateTime now,
  ) => _stats.classifyFard(model, slot, now);

  SalahStatsService get stats => _stats;

  @override
  Future<void> close() {
    _logSubscription?.cancel();
    return super.close();
  }
}
