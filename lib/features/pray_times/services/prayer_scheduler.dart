import 'package:wadhakir/core/time/clock.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';
import 'package:wadhakir/features/pray_times/services/prayer_schedule_planner.dart';

/// The entire surface the prayer scheduler needs from whatever actually arms
/// alarms on the device.
///
/// Two methods. That is the point.
///
/// Today the only implementation wraps `awesome_notifications`. The reliability
/// work that follows replaces it with a native `AlarmManager.setAlarmClock`
/// bridge so no Flutter engine sits in the fire path — and because everything
/// that *decides* what to arm lives in [PrayerSchedulePlanner], that swap is a
/// new class implementing this interface rather than a rewrite of the
/// scheduling logic.
///
/// It is also what makes the scheduler testable at all. The plugin is a
/// singleton behind platform channels; a fake that records calls is not.
abstract interface class PrayerAlarmGateway {
  /// Clears the prayer id window. Must never touch ids outside it — azkar,
  /// wird, fasting and daily-inspiration reminders live on the same plugin and
  /// only re-arm on their own settings change or a cold start, so a blanket
  /// cancel here silently disables four other features.
  Future<void> cancelIds(Iterable<int> ids);

  /// Arms one already-decided notification.
  Future<void> arm(PlannedPrayerNotification planned, {String? locationName});
}

/// The optional half of the gateway contract, for a gateway that treats one
/// sweep as a transaction.
///
/// The plugin arms each notification as it arrives and has nothing to commit.
/// The native bridge cannot: a sixty-day plan is three hundred alarms, and
/// persisting the ledger on each one would rewrite a growing JSON document
/// three hundred times. So it buffers, and [PrayerScheduler] tells it when the
/// sweep is complete.
///
/// The transaction is also what makes a crashed sweep safe. Nothing is applied
/// until [commit], so an app killed halfway through leaves the PREVIOUS
/// schedule armed and intact, rather than a half-written one.
abstract interface class BatchingPrayerAlarmGateway {
  /// Applies the sweep built since the last [PrayerAlarmGateway.cancelIds].
  Future<void> commit();

  /// Gives up: cancels everything this gateway has armed and drops its stored
  /// plan.
  ///
  /// Distinct from [PrayerAlarmGateway.cancelIds] precisely because a batching
  /// gateway's sweep does NOT cancel anything — the previous schedule stays
  /// live until [commit] replaces it. Handing over to another gateway therefore
  /// needs this, or the committed plan keeps ringing underneath the new owner's
  /// and every adhan sounds twice.
  Future<void> abandon();
}

/// What a reschedule did.
class PrayerScheduleResult {
  final List<PlannedPrayerNotification> planned;

  /// Fingerprint of [planned], for suppressing an identical reschedule.
  final String signature;

  const PrayerScheduleResult({required this.planned, required this.signature});

  bool get isEmpty => planned.isEmpty;

  /// Distinct days covered.
  int get dayCount => planned.map((p) => p.dayIndex).toSet().length;
}

/// Cancels the prayer id window and re-arms it from a freshly computed plan.
///
/// Three collaborators, each replaceable: the [Clock] decides what counts as
/// past, the [PrayerSchedulePlanner] decides what should exist, the
/// [PrayerAlarmGateway] makes it exist. None of them is a singleton and none
/// of them needs a device, so the sequencing this class owns — cancel first,
/// then arm, and skip the whole thing when nothing changed — can be asserted
/// in a unit test.
///
/// That sequencing is not incidental. Re-arming an identical plan cancels
/// every prayer id and re-adds it, and a notification due inside that window
/// can be dropped in the gap; reschedules fire from settings changes, prayer
/// time reloads and day rollovers, several of which land together.
class PrayerScheduler {
  final PrayerAlarmGateway _gateway;
  final PrayerSchedulePlanner _planner;
  final Clock _clock;

  /// The last plan actually armed, or null if this scheduler has not armed one
  /// yet.
  ///
  /// Nullable rather than an empty string on purpose. An empty plan — the
  /// master toggle switched off — also has an empty signature, so with `''` as
  /// the initial value the very first reschedule after launch would compare
  /// equal, skip the cancel sweep, and leave every alarm from the previous run
  /// armed. Turning notifications off would appear to do nothing.
  String? _lastSignature;

  /// Positional-optional so the two seams can be initializing formals with
  /// defaults — Dart forbids a private name on a named parameter.
  PrayerScheduler(
    this._gateway, [
    this._planner = const PrayerSchedulePlanner(),
    this._clock = systemClock,
  ]);

  /// The plan this device would arm right now, without arming it.
  ///
  /// Read-only, and the reason the whole extraction was worth doing: what the
  /// app *intends* to schedule is now answerable without a device, a plugin or
  /// a wait until Fajr.
  List<PlannedPrayerNotification> preview({
    required Map<DateTime, Map<String, DateTime>> prayerTimesByDay,
    required NotificationSettingsModel settings,
  }) => _planner.plan(
    prayerTimesByDay: prayerTimesByDay,
    settings: settings,
    now: _clock.now(),
  );

  /// Recomputes the plan and, if it differs from the last one armed, replaces
  /// the whole prayer id window with it.
  ///
  /// Pass [force] to re-arm regardless — after a reboot, a timezone change or
  /// anything else that can invalidate the OS alarm table without changing
  /// what this app intended.
  Future<PrayerScheduleResult> reschedule({
    required Map<DateTime, Map<String, DateTime>> prayerTimesByDay,
    required NotificationSettingsModel settings,
    String? locationName,
    bool force = false,
  }) {
    // Serialised, because a sweep is three phases — cancel, arm each of up to
    // three hundred, commit — and a batching gateway accumulates them in ONE
    // buffer with nothing to tell two senders apart. Reschedules routinely
    // arrive together: a settings change, a prayer-time reload and a day
    // rollover can all land in the same frame. Interleaved, the second sweep's
    // cancel empties the buffer mid-flight and the first sweep's commit then
    // applies a plan with most of its alarms missing.
    final result = _queue.then(
      (_) => _rescheduleSerially(
        prayerTimesByDay: prayerTimesByDay,
        settings: settings,
        locationName: locationName,
        force: force,
      ),
    );
    // The chain must survive a failed sweep, or one thrown exception would
    // poison every reschedule for the rest of the session.
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> _queue = Future<void>.value();

  Future<PrayerScheduleResult> _rescheduleSerially({
    required Map<DateTime, Map<String, DateTime>> prayerTimesByDay,
    required NotificationSettingsModel settings,
    String? locationName,
    bool force = false,
  }) async {
    final plan = preview(
      prayerTimesByDay: prayerTimesByDay,
      settings: settings,
    );
    // The location is part of the signature because it is rendered into the
    // notification body. Without it, moving city while every prayer minute
    // happened to stay identical would leave the old city's name on every
    // armed adhan, and this guard would call that "unchanged".
    final signature = '${_planner.signature(plan)}|loc:${locationName ?? ''}';

    if (!force && signature == _lastSignature) {
      return PrayerScheduleResult(planned: plan, signature: signature);
    }

    await _gateway.cancelIds(PrayerSchedulePlanner.cancellableIds);
    for (final planned in plan) {
      await _gateway.arm(planned, locationName: locationName);
    }

    // Closes the sweep for a gateway that batches. Sequenced here rather than
    // in the repository because this class already owns "cancel first, then
    // arm" — "then apply" is the same responsibility, and a caller that forgot
    // to commit would leave a plan that was computed, sent and never armed.
    if (_gateway case final BatchingPrayerAlarmGateway batching) {
      await batching.commit();
    }

    // Recorded only after the arming actually completes. If the gateway throws
    // — a denied permission, an exact-alarm refusal — the signature must NOT
    // advance, or a transient failure would suppress every retry for the rest
    // of the session and silently leave the user with no adhan.
    _lastSignature = signature;

    return PrayerScheduleResult(planned: plan, signature: signature);
  }

  /// Forgets the last plan, so the next [reschedule] re-arms unconditionally.
  void invalidate() => _lastSignature = null;
}
