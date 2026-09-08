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
  }) async {
    final plan = preview(
      prayerTimesByDay: prayerTimesByDay,
      settings: settings,
    );
    final signature = _planner.signature(plan);

    if (!force && signature == _lastSignature) {
      return PrayerScheduleResult(planned: plan, signature: signature);
    }

    await _gateway.cancelIds(PrayerSchedulePlanner.cancellableIds);
    for (final planned in plan) {
      await _gateway.arm(planned, locationName: locationName);
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
