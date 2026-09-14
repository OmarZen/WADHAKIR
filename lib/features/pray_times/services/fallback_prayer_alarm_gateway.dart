import 'package:flutter/foundation.dart';
import 'package:wadhakir/features/pray_times/services/prayer_schedule_planner.dart';
import 'package:wadhakir/features/pray_times/services/prayer_scheduler.dart';

/// Arms through [primary], and falls back to [secondary] for the rest of the
/// session the first time [primary] throws.
///
/// ## Why a whole class for a try/catch
///
/// Because a half-migrated sweep is worse than either path on its own. The
/// scheduler's contract is "cancel the window, then arm every entry"; if the
/// native bridge accepts three alarms and then throws — a manufacturer that
/// refuses `setAlarmClock`, a Kotlin regression, an exact-alarm denial — the
/// naive handler leaves three native alarms armed and the remaining thirty-two
/// nowhere. Worse, retrying the whole plan on the plugin would then double-fire
/// those three: two adhans, seconds apart, from a device the user trusts.
///
/// So the fallback is transactional. Every armed entry of the current sweep is
/// remembered; on the first failure the primary's table is dropped whole and
/// the entries are replayed through the secondary in their original order. The
/// user gets one complete schedule from one owner, always.
///
/// ## Why it never fails back
///
/// Once degraded it stays degraded until the app restarts. Flapping between two
/// alarm owners inside a session is the one state neither side can reconcile:
/// each believes it holds the table, and the cancel sweep of one does not reach
/// the other's alarms.
class FallbackPrayerAlarmGateway
    implements PrayerAlarmGateway, BatchingPrayerAlarmGateway {
  final PrayerAlarmGateway _primary;
  final PrayerAlarmGateway _secondary;

  /// Called once, the first time the primary fails, with the error that caused
  /// it. Lets the app record *why* a device is on the old path — the difference
  /// between "this OEM refuses exact alarms" and "our Kotlin threw" is
  /// invisible otherwise.
  final void Function(Object error, StackTrace stackTrace)? onDegraded;

  bool _degraded = false;

  /// Entries armed through the primary during the sweep in progress, in call
  /// order, so a failure can replay them through the secondary.
  final List<_ArmedEntry> _sweep = [];

  /// Positional for the same reason [PrayerScheduler]'s seams are: Dart forbids
  /// a private name on a named parameter, so named ones could not be
  /// initializing formals.
  FallbackPrayerAlarmGateway(this._primary, this._secondary, {this.onDegraded});

  /// Whether this session has given up on the primary.
  bool get isDegraded => _degraded;

  @override
  Future<void> cancelIds(Iterable<int> ids) async {
    // A sweep always begins here, so this is where the replay buffer resets.
    // Materialised because the caller's iterable may be lazy and is walked
    // again on the fallback path.
    final idList = ids.toList(growable: false);
    _sweep.clear();

    if (_degraded) return _secondary.cancelIds(idList);

    try {
      await _primary.cancelIds(idList);
    } catch (error, stackTrace) {
      await _degrade(error, stackTrace, idsToClear: idList);
    }
  }

  /// Ids the secondary's cancel sweep can actually reach.
  ///
  /// Built once: [PrayerSchedulePlanner.cancellableIds] is a fresh list on every
  /// read, and this is consulted per alarm across a sixty-day plan.
  static final Set<int> _sweepable = PrayerSchedulePlanner.cancellableIds
      .toSet();

  /// Whether the secondary could ever take this alarm back.
  ///
  /// The primary is handed sixty days, which allocates ids up to 694. The
  /// plugin's sweep only reaches [PrayerSchedulePlanner.cancelDayWindow] days —
  /// ids 100..219. Replaying the whole plan onto it would arm hundreds of
  /// notifications that nothing can ever cancel: switching the adhan off, or
  /// changing its sound, would leave the originals firing for two months.
  ///
  /// So a degraded sweep is truncated to what the secondary can own. The days
  /// dropped here are re-planned at the shorter horizon on the next reschedule,
  /// because degrading also tells the app to stop asking for sixty.
  bool _reachableBySecondary(PlannedPrayerNotification planned) =>
      _sweepable.contains(planned.id);

  @override
  Future<void> arm(
    PlannedPrayerNotification planned, {
    String? locationName,
  }) async {
    if (_degraded) {
      if (!_reachableBySecondary(planned)) return;
      return _secondary.arm(planned, locationName: locationName);
    }

    try {
      await _primary.arm(planned, locationName: locationName);
      _sweep.add(_ArmedEntry(planned, locationName));
    } catch (error, stackTrace) {
      // The entry that failed is replayed too — it was never armed anywhere.
      _sweep.add(_ArmedEntry(planned, locationName));
      await _degrade(
        error,
        stackTrace,
        idsToClear: PrayerSchedulePlanner.cancellableIds,
      );
    }
  }

  @override
  Future<void> commit() async {
    // The secondary arms as it goes, so once degraded there is nothing to
    // apply — the plan is already live on it.
    if (_degraded) return;

    try {
      if (_primary case final BatchingPrayerAlarmGateway batching) {
        await batching.commit();
      }
      // Applied. The replay buffer only exists to survive a failure, and
      // holding sixty days of plan for the rest of the session is pure waste.
      _sweep.clear();
    } catch (error, stackTrace) {
      await _degrade(
        error,
        stackTrace,
        idsToClear: PrayerSchedulePlanner.cancellableIds,
      );
    }
  }

  @override
  Future<void> abandon() async {
    _sweep.clear();
    if (_primary case final BatchingPrayerAlarmGateway batching) {
      await batching.abandon();
    } else {
      await _primary.cancelIds(PrayerSchedulePlanner.cancellableIds);
    }
    if (_degraded) {
      await _secondary.cancelIds(PrayerSchedulePlanner.cancellableIds);
    }
  }

  /// Switches to the secondary and rebuilds the sweep so far on it.
  ///
  /// The primary's own table is dropped first. That call is best-effort by
  /// necessity: the primary has just thrown, so it may well throw again — but
  /// leaving it armed alongside a full secondary schedule would double every
  /// adhan for the rest of the day, which is the one outcome worth extra work
  /// to avoid.
  Future<void> _degrade(
    Object error,
    StackTrace stackTrace, {
    required List<int> idsToClear,
  }) async {
    _degraded = true;
    debugPrint(
      'Native alarm gateway failed, falling back to the plugin: $error',
    );
    onDegraded?.call(error, stackTrace);

    try {
      // abandon(), not cancelIds(). A batching primary's sweep cancels nothing
      // — the plan it committed on a PREVIOUS reschedule is still armed, and
      // only an explicit abandon takes it back. Sweeping instead would leave
      // yesterday's native alarms ringing under today's plugin schedule.
      if (_primary case final BatchingPrayerAlarmGateway batching) {
        await batching.abandon();
      } else {
        await _primary.cancelIds(idsToClear);
      }
    } catch (_) {
      // Already accounted for above.
    }

    await _secondary.cancelIds(idsToClear);
    var dropped = 0;
    for (final entry in _sweep) {
      if (!_reachableBySecondary(entry.planned)) {
        dropped++;
        continue;
      }
      await _secondary.arm(entry.planned, locationName: entry.locationName);
    }
    if (dropped > 0) {
      debugPrint(
        'Dropped $dropped alarms beyond the plugin\'s cancellable window; '
        'the next reschedule re-plans at the shorter horizon',
      );
    }
    _sweep.clear();
  }
}

class _ArmedEntry {
  final PlannedPrayerNotification planned;
  final String? locationName;

  const _ArmedEntry(this.planned, this.locationName);
}
