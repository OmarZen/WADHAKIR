/// The iOS pending-notification budget, allocated in one place.
///
/// iOS keeps only the **64 soonest-firing** pending notification requests and
/// silently discards the rest: no error, no callback, no log line. An app that
/// is over budget looks perfectly healthy right up until the adhan does not
/// fire — and it fails *soonest-last*, so the reminders a user notices missing
/// are the ones furthest out, long after the cause has scrolled away.
///
/// Before R3 this app sat **right on the edge** of that cap. With every feature
/// switched on, worst case, it asked iOS for about 63 requests: 25 prayer +
/// 12 azkar + 23 fasting (2 weekly + 7 candidate days x 3 reminders) + wird +
/// daily inspiration + a discovery nudge. One more reminder anywhere and iOS
/// would start discarding, furthest-out first, with no error and no log.
///
/// Note the number is 63, not the ~81 the roadmap estimated. That estimate
/// counted the fasting next-month pre-schedule, which
/// `_scheduleHijriCalendarNotifications` has always skipped on iOS. Getting
/// this right mattered: the first draft of this file believed the ~81 and
/// capped fasting at 6, which would have deleted Ayyam al-Bid from every iOS
/// device to make room nothing needed. See [fasting].
///
/// Either way the only protection was a debug `assert` in
/// `NotificationRepositoryImpl.debugAssertPrayerSchedulesSurvived` — which
/// tells a developer on a debug build and tells a user nothing.
///
/// The fix is an *allocation* rather than a scramble. Every scheduler in the
/// app gets a fixed quota here, a test sums the quotas, and the sum is held
/// under [pendingCap]. A feature that wants more slots has to take them from
/// another feature **in this file**, where the trade is visible and reviewable.
///
/// Android has no such cap and is deliberately unbounded — see [capFor].
library;

/// The schedulers that compete for the budget, **in priority order**.
///
/// Declaration order is the priority order: when demand exceeds supply the
/// later entries lose slots first. Prayers are first because they are the
/// product — everything else in this app is an accessory to them.
enum ReminderSlot {
  /// The five daily prayers. `PrayerSchedulePlanner` horizon x 5 prayers.
  prayer,

  /// The safety net beneath everything else — see [floor].
  floorNudge,

  /// `WirdNotificationService`, id 6001. One repeating calendar trigger.
  wird,

  /// `AzkarNotificationService`, ids 7100+. Six fixed-clock reminders plus
  /// seven prayer-driven ones, each a single repeating calendar trigger.
  azkar,

  /// `DailyInspirationNotificationService`. One repeating calendar trigger.
  dailyInspiration,

  /// `FastingNotificationService`, ids 5001-5999. The historical offender:
  /// an un-budgeted fan-out over every Hijri fasting day in the month.
  fasting,
}

/// The iOS pending-request allocation.
abstract final class IosNotificationBudget {
  /// What iOS actually retains. Everything beyond this is discarded silently.
  static const int pendingCap = 64;

  /// Held back for requests that are never part of a plan.
  ///
  /// Only ONE of these is genuinely a *pending* request: the feature-discovery
  /// nudge (id 7200), which is the single transient with a `schedule:` on it
  /// (`feature_discovery_service.dart:152`). Every "try it now" test button —
  /// wird 6099, inspiration 7099, fasting 5999 — calls `createNotification`
  /// with **no schedule**, so it is delivered immediately and never occupies a
  /// pending slot at all. The location notice and the diagnostic are posted the
  /// same way, from Kotlin.
  ///
  /// So this is 1 real slot plus 3 of margin, not 6 of need. Review caught the
  /// original 6 as cargo: it was reserving room against a threat that does not
  /// exist, and the slots it hoarded were taken from reminders that do.
  static const int transientReserve = 4;

  /// The slots a scheduled plan may occupy.
  static const int plannable = pendingCap - transientReserve;

  // --- The allocation -------------------------------------------------------
  //
  // Sums to [allocated]. `ios_notification_budget_test.dart` asserts that it
  // fits in [plannable]; change a number here and that test is the thing that
  // tells you what it cost.

  /// 5 prayers x `PrayerSchedulePlanner.horizonDays(isIOS: true)` (5 days).
  ///
  /// Deliberately unchanged by R3. Prayers fire soonest, so they are the *last*
  /// thing iOS evicts — widening the horizon here would buy the least
  /// protection of anywhere a slot could go, and the slots are not spare: this
  /// allocation runs at 57 of 64. A 7-day iOS horizon is a real option for a
  /// later release, but it costs 10 slots and has to take them from something.
  static const int prayer = 25;

  /// 6 fixed-clock + 7 prayer-driven, all repeating — but only **12** can be
  /// pending at once. `_qiyamFixedId` (7110) and `_qiyamLastThirdId` (7111) are
  /// mutually exclusive: `azkar_notification_service.dart` schedules the first
  /// only under `QiyamMode.fixed` and the second only under
  /// `QiyamMode.lastThird`, and a user has one mode, not both.
  static const int azkar = 12;

  /// Every fasting day in the current Hijri month, up to three reminders each
  /// (eve at Maghrib, suhoor at Fajr-5, advance N days out), plus the two
  /// weekly repeating Monday/Thursday reminders.
  ///
  /// 17 is the true worst case, not a guess: after [monthCandidates] de-dupes
  /// by day, a Hijri month offers at most **five** distinct fasting days
  /// (9, 10, 13, 14, 15 — Tasu'a and Ashura ARE the 9th and the 10th, they do
  /// not add days). 2 weekly + 5 x 3 = 17.
  ///
  /// This was **6** when the change was first written, and that was a mistake
  /// the adversarial review caught. The 6 came from an Android-shaped demand
  /// figure of ~26, but iOS never had that demand:
  /// `_scheduleHijriCalendarNotifications` already skips the next-month
  /// pre-schedule on iOS, so iOS only ever fanned out the current month — about
  /// 12 requests in an ordinary month. Real pre-R3 iOS demand was ~53 of 64,
  /// i.e. **fasting was never the thing pushing iOS over the cap**. Capping it
  /// at 6 would have silently deleted Ayyam al-Bid — a headline feature with
  /// its own toggle — from every iOS device, forever, to protect slots that
  /// nothing was using.
  ///
  /// The lesson is in the number: a budget has to be measured against the
  /// platform it constrains, not the platform the code was written on.
  static const int fasting = 17;

  static const int wird = 1;

  static const int dailyInspiration = 1;

  /// One dead man's switch — see [ReminderFloorService].
  ///
  /// Every other reminder in this app has an expiry: the prayer plan runs five
  /// days, the fasting plan runs to the end of the Hijri month. A user who
  /// stops opening the app eventually falls off the end of all of them and the
  /// app goes completely silent — which is indistinguishable, from the outside,
  /// from an app that is broken.
  ///
  /// This is the floor beneath that: one request armed ten days out and pushed
  /// forward again on every resume. A user who opens the app even weekly never
  /// sees it fire; a user who vanishes gets exactly one calm message. Chosen
  /// over a never-expiring weekly repeater because that one reaches everybody
  /// forever, including the majority whose reminders are working — an
  /// unconditional nag for a conditional problem.
  static const int floor = 1;

  /// What the allocation actually spends.
  static const int allocated =
      prayer + azkar + fasting + wird + dailyInspiration + floor;

  /// Unspent slots. Headroom, not a pool to raid without changing this file.
  static const int unallocated = plannable - allocated;

  /// The cap for [slot], or `null` when there is no cap.
  ///
  /// Returns `null` on Android, which has no pending-request limit: callers
  /// treat `null` as "schedule everything you planned". Passing `isIOS`
  /// explicitly rather than reading `Platform.isIOS` in here is what keeps this
  /// class testable off-device.
  static int? capFor(ReminderSlot slot, {required bool isIOS}) {
    if (!isIOS) return null;
    return switch (slot) {
      ReminderSlot.prayer => prayer,
      ReminderSlot.azkar => azkar,
      ReminderSlot.fasting => fasting,
      ReminderSlot.wird => wird,
      ReminderSlot.dailyInspiration => dailyInspiration,
      ReminderSlot.floorNudge => floor,
    };
  }

  /// Keep only the [cap] soonest entries of [times], in chronological order.
  ///
  /// The shared truncation rule for every scheduler that has more to say than
  /// it has slots. Soonest-first is the only defensible order here: it matches
  /// what iOS itself would keep, so a truncated plan and an over-budget plan
  /// deliver the same notifications — the difference is that this one also
  /// leaves room for the prayers.
  ///
  /// A `null` [cap] (Android) returns the list sorted but unshortened, so
  /// callers need no platform branch of their own.
  static List<T> soonest<T>(
    List<T> times,
    int? cap, {
    required DateTime Function(T) when,
  }) {
    final sorted = [...times]..sort((a, b) => when(a).compareTo(when(b)));
    if (cap == null || sorted.length <= cap) return sorted;
    return sorted.sublist(0, cap);
  }
}

/// A slot counter shared across one scheduling pass.
///
/// Some schedulers cannot decide up front how many requests they will post:
/// the fasting service fans each fasting day out into up to three reminders,
/// and how many of those actually survive depends on prayer times and on the
/// current clock (a reminder whose moment has passed is skipped). Capping the
/// *days* there would not bound the *requests*.
///
/// So the cap travels with the pass instead. The caller visits its candidates
/// in soonest-first order and asks [take] before each request; once the budget
/// is spent every further ask is refused, and what got scheduled is the nearest
/// N — the same set iOS would have kept, minus the silent eviction of everyone
/// else's notifications on the way.
class NotificationSlotBudget {
  /// A budget of exactly [slots] requests.
  NotificationSlotBudget(int slots) : _remaining = slots < 0 ? 0 : slots;

  /// No cap — Android, where the OS imposes none.
  NotificationSlotBudget.unlimited() : _remaining = null;

  /// A budget of [cap] requests, or unlimited when [cap] is `null`.
  ///
  /// Pairs with [IosNotificationBudget.capFor], which returns `null` off iOS.
  factory NotificationSlotBudget.of(int? cap) => cap == null
      ? NotificationSlotBudget.unlimited()
      : NotificationSlotBudget(cap);

  int? _remaining;
  int _taken = 0;

  /// How many requests this pass has claimed.
  int get taken => _taken;

  /// Whether another request would be allowed. Unlimited budgets always are.
  bool get hasRoom => _remaining == null || _remaining! > 0;

  /// Claim one slot. Returns `false` — and claims nothing — when spent.
  ///
  /// Callers must treat `false` as "do not post this one", not as an error:
  /// being over budget is a normal outcome for a user with every reminder
  /// switched on, and the whole point is that it degrades quietly at the
  /// bottom of the priority order rather than silently at the top.
  bool take() {
    if (!hasRoom) return false;
    if (_remaining != null) _remaining = _remaining! - 1;
    _taken++;
    return true;
  }
}
