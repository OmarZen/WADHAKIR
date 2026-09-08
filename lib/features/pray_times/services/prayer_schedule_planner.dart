import 'package:flutter/foundation.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';

/// The five fard, in the order their notification ids are allocated.
///
/// The Arabic name is part of the identity rather than a lookup, because
/// `notification_repository_impl` used to branch on the Arabic display string
/// to decide which prayer it was holding — a translation change or a JSON typo
/// would have broken *scheduling*, not just text.
enum PlannedPrayer {
  fajr('Fajr', 'الفجر'),
  dhuhr('Dhuhr', 'الظهر'),
  asr('Asr', 'العصر'),
  maghrib('Maghrib', 'المغرب'),
  isha('Isha', 'العشاء');

  /// The key used in the `Map<String, DateTime>` the repository is handed, and
  /// in the notification payload the deep-link router reads back.
  final String key;

  final String arabicName;

  const PlannedPrayer(this.key, this.arabicName);

  /// Base notification id. The full id is [PrayerSchedulePlanner.idFor].
  int get baseId => PrayerSchedulePlanner.fajrId + index;

  bool get isFajr => this == PlannedPrayer.fajr;

  static PlannedPrayer? byKey(String key) {
    final lower = key.toLowerCase();
    for (final prayer in PlannedPrayer.values) {
      if (prayer.key.toLowerCase() == lower || prayer.arabicName == key) {
        return prayer;
      }
    }
    return null;
  }
}

/// One notification the planner has decided should exist, fully resolved.
///
/// Everything a scheduler needs and nothing it has to work out for itself:
/// which id, which instant, which prayer, and the settings that govern its
/// sound and vibration. Deliberately free of any `awesome_notifications` type
/// so the plan can be asserted on in a unit test and, later, handed to a
/// native `AlarmManager` bridge instead.
@immutable
class PlannedPrayerNotification {
  /// Stable across a reschedule: `base + dayIndex * idsPerDay`.
  final int id;

  final PlannedPrayer prayer;

  /// Local midnight of the day this belongs to. The scheduler never has to
  /// re-derive it from [prayerTime], which would be wrong for an Isha that
  /// crosses midnight.
  final DateTime day;

  /// Position of [day] in the sorted horizon. Only meaningful for id
  /// allocation and the cancel window.
  final int dayIndex;

  /// The prayer time itself — what the notification is *about*.
  final DateTime prayerTime;

  /// When the notification actually fires: [prayerTime] minus the user's
  /// chosen lead time. Equal to [prayerTime] for `onTime`.
  final DateTime fireTime;

  final PrayerNotificationSettings settings;

  const PlannedPrayerNotification({
    required this.id,
    required this.prayer,
    required this.day,
    required this.dayIndex,
    required this.prayerTime,
    required this.fireTime,
    required this.settings,
  });

  /// How far ahead of the prayer this fires. `Duration.zero` for `onTime`.
  Duration get leadTime => prayerTime.difference(fireTime);

  @override
  String toString() =>
      'PlannedPrayerNotification(#$id ${prayer.key} day$dayIndex '
      'fires $fireTime for $prayerTime)';
}

/// Decides *what* prayer notifications should exist, given the settings, the
/// computed prayer times and the current instant.
///
/// ## Why this is separate
///
/// This used to be spread across [PrayerTimesCubit.scheduleNotificationsWith
/// Settings] (horizon selection), `_MobileNotificationRepositoryImpl
/// .scheduleMultiDayPrayerNotifications` (day ordering, id allocation) and
/// `_scheduleOne` (lead-time offset, past-time skip) — with every one of those
/// steps sitting behind an `awesome_notifications` singleton and a bare
/// `DateTime.now()`. There was no way to ask what the app would schedule
/// without actually scheduling it on a device.
///
/// Pulling the decisions into one pure function is what makes the reliability
/// work testable: "what fires on the day the horizon rolls over", "what
/// happens to an Isha that has already passed", "do two days ever collide on
/// an id" are now assertions instead of field reports. Everything downstream
/// of `plan()` is rendering.
///
/// It is also the seam R2 needs. Handing this list to a native `AlarmManager`
/// bridge rather than to the Flutter plugin is a change of consumer, not a
/// rewrite of the logic.
class PrayerSchedulePlanner {
  const PrayerSchedulePlanner();

  // --- The notification id space -------------------------------------------
  //
  // Prayers own 100..214. Every other feature schedules well clear of it
  // (persistent 999, fasting 5001-5999, wird 6001/6099, azkar 7100+), which is
  // what lets a reschedule cancel only prayers instead of a global cancelAll()
  // that would silently wipe every other reminder in the app.

  static const int fajrId = 100;

  /// Ids are `base + dayIndex * idsPerDay`. Ten leaves five spare slots per
  /// day, so a sixth prayer-adjacent notification could be added later without
  /// renumbering ids that are already armed on users' devices.
  static const int idsPerDay = 10;

  /// How many days of ids the cancel sweep clears.
  ///
  /// Deliberately wider than [horizonDays] on either platform: shrinking the
  /// horizon must not strand ids armed by a previous, longer one. Twelve days
  /// covers the widest horizon this app has shipped with room to spare.
  static const int cancelDayWindow = 12;

  /// How many days ahead to schedule.
  ///
  /// Android has no cap. iOS keeps only the 64 soonest-firing pending requests
  /// and silently discards the rest, and this app is genuinely over that budget
  /// with every feature enabled (~81 worst case; the fasting fan-out is the
  /// offender, not this horizon). Because prayer notifications all fire within
  /// five days they are the LAST to be discarded under iOS's soonest-first
  /// retention, so shrinking this further would not help — it would free slots
  /// that far-future fasting requests immediately consume and then lose anyway,
  /// trading the app's most important alert for its least important.
  static int horizonDays({required bool isIOS}) => isIOS ? 5 : 7;

  /// Every id the prayer schedule may occupy, for the cancel sweep.
  static List<int> get cancellableIds => [
    for (var day = 0; day < cancelDayWindow; day++)
      for (final prayer in PlannedPrayer.values)
        prayer.baseId + day * idsPerDay,
  ];

  /// The id for [prayer] on the [dayIndex]-th day of the horizon.
  static int idFor(PlannedPrayer prayer, int dayIndex) =>
      prayer.baseId + dayIndex * idsPerDay;

  /// The lead time for a timing choice.
  static Duration leadTimeFor(NotificationTiming timing) => switch (timing) {
    NotificationTiming.onTime => Duration.zero,
    NotificationTiming.before5Min => const Duration(minutes: 5),
    NotificationTiming.before10Min => const Duration(minutes: 10),
    NotificationTiming.before15Min => const Duration(minutes: 15),
  };

  /// Builds the complete set of prayer notifications that should be armed.
  ///
  /// [prayerTimesByDay] is keyed by local midnight; each value maps
  /// [PlannedPrayer.key] to that prayer's instant. Days are sorted before ids
  /// are allocated, so the id a given day receives does not depend on map
  /// iteration order — two runs over the same horizon produce byte-identical
  /// plans, which is what makes the reschedule-suppression signature honest.
  ///
  /// Returns an empty list when the master toggle is off. That is a real
  /// answer, not a failure: the caller cancels the id range and arms nothing.
  List<PlannedPrayerNotification> plan({
    required Map<DateTime, Map<String, DateTime>> prayerTimesByDay,
    required NotificationSettingsModel settings,
    required DateTime now,
  }) {
    if (!settings.masterEnabled) return const [];

    final perPrayer = {
      PlannedPrayer.fajr: settings.fajrSettings,
      PlannedPrayer.dhuhr: settings.dhuhrSettings,
      PlannedPrayer.asr: settings.asrSettings,
      PlannedPrayer.maghrib: settings.maghribSettings,
      PlannedPrayer.isha: settings.ishaSettings,
    };

    final days = prayerTimesByDay.keys.toList()..sort();
    final planned = <PlannedPrayerNotification>[];

    for (var dayIndex = 0; dayIndex < days.length; dayIndex++) {
      final day = days[dayIndex];
      final times = prayerTimesByDay[day]!;

      for (final prayer in PlannedPrayer.values) {
        final prayerSettings = perPrayer[prayer]!;
        if (!prayerSettings.enabled) continue;

        final prayerTime = times[prayer.key];
        if (prayerTime == null) continue;

        final fireTime = prayerTime.subtract(
          leadTimeFor(prayerSettings.timing),
        );

        // An instant that has already passed cannot be scheduled — the OS
        // would either fire it immediately or drop it. Compared with `!isAfter`
        // rather than `isBefore` so a notification due at exactly `now` is
        // skipped too: by the time the platform channel round-trips, it is in
        // the past.
        if (!fireTime.isAfter(now)) continue;

        planned.add(
          PlannedPrayerNotification(
            id: idFor(prayer, dayIndex),
            prayer: prayer,
            day: day,
            dayIndex: dayIndex,
            prayerTime: prayerTime,
            fireTime: fireTime,
            settings: prayerSettings,
          ),
        );
      }
    }

    return planned;
  }

  /// A stable fingerprint of a plan, used to skip a redundant
  /// cancel-and-rearm.
  ///
  /// Reschedules are triggered by settings changes, prayer-time reloads and
  /// day rollovers, and several of those fire together. Re-arming an identical
  /// plan is not free: it cancels every prayer id and re-adds it, and a
  /// notification due in that window can be dropped in the gap. Comparing
  /// fingerprints turns that race into a no-op.
  ///
  /// Built from the id and fire time of every entry — the two things that
  /// decide whether the OS alarm table would actually change — plus the sound
  /// and vibration, which change the notification without moving it.
  String signature(List<PlannedPrayerNotification> plan) => plan
      .map(
        (p) =>
            '${p.id}@${p.fireTime.millisecondsSinceEpoch}'
            ':${p.settings.customSoundPath ?? ''}'
            ':${p.settings.vibration ? 1 : 0}',
      )
      .join('|');
}
