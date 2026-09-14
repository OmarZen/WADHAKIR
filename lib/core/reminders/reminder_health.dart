import 'package:wadhakir/core/reminders/reminder_ledger_entry.dart';

/// How the app's reminders are doing, in the only grades a user cares about.
enum ReminderHealthStatus {
  /// Reminders are arriving, on time, and making a sound.
  healthy,

  /// They arrive, but late — or something is set up in a way that will make
  /// them late.
  degraded,

  /// They are not arriving.
  broken,

  /// The user turned them off. Not a fault, and the screen must not treat it
  /// as one.
  off,

  /// Not enough has happened yet to say anything honest.
  ///
  /// A fresh install, a ledger that has only just started filling, or settings
  /// that have not loaded. Claiming anything here would be the exact dishonesty
  /// this screen exists to avoid — in **both** directions. A green tick over no
  /// evidence teaches a user to stop believing the screen; an accusation over
  /// no evidence teaches them to stop believing it faster.
  unknown,
}

/// The single thing the screen offers to do about it.
///
/// One, never a list. A screen with four buttons is a screen that has not
/// worked out what is wrong.
enum ReminderHealthAction {
  /// System notification settings for the app.
  openNotificationSettings,

  /// The blocked adhan channel specifically, not the app's whole settings page.
  openChannelSettings,

  /// The Android 12+ exact-alarm permission.
  grantExactAlarms,

  /// The OEM's own autostart / protected-apps screen — item #16.
  ///
  /// Only ever offered when a probe found an activity that can actually handle
  /// the intent. See `OemAutostart`.
  openOemAutostart,

  /// Battery optimisation exemption. Offered only with evidence behind it.
  grantBatteryExemption,

  /// Nothing the user can usefully press.
  none,
}

/// Live platform facts the ledger cannot know.
///
/// Read at the moment the screen opens, never stored: every one of these can be
/// changed by the user in Settings while the app sits in the background, and a
/// cached copy would make the screen confidently wrong.
class ReminderHealthProbe {
  /// Whether the app may post notifications at all.
  final bool notificationsAllowed;

  /// Whether the user's master reminder toggle is on.
  final bool remindersEnabled;

  /// Whether [remindersEnabled] is actually known.
  ///
  /// False while settings are loading, and false if they failed to load. A
  /// screen that assumed "on" would diagnose a device whose owner had switched
  /// reminders off — and could go as far as demanding a battery exemption for
  /// a feature they had deliberately disabled.
  final bool settingsKnown;

  /// Android 12+: whether exact alarms are permitted. True on iOS and on
  /// Android below 12, where the question does not exist.
  final bool exactAlarmsAllowed;

  /// Whether the app is exempt from battery optimisation. True where the
  /// concept does not exist.
  final bool batteryExempt;

  /// Whether an OEM autostart screen was found on this device that can
  /// actually be opened. Decided by probing the intent, never by matching a
  /// manufacturer name — see item #16.
  final bool oemAutostartAvailable;

  /// The adhan channel the OS is currently blocking, or null.
  ///
  /// **Live, not historical.** An earlier draft read this off `muted` rows in
  /// the ledger, which meant a user who muted a channel on Monday and unmuted
  /// it on Tuesday was told it was still muted for a fortnight — and, because
  /// that verdict sits near the top of the ladder, every real fault underneath
  /// stayed hidden for the same fortnight. A certainty has to be read at the
  /// moment it is asserted.
  ///
  /// Carries *which* channel, because there are two — «الأذان» and «أذان
  /// الفجر» — and a button that opens the wrong one shows the user a perfectly
  /// healthy channel and changes nothing.
  final String? mutedAdhanChannelKey;

  /// iOS only: how many scheduled notifications the OS admits to holding.
  ///
  /// Null everywhere else. On Android the equivalent number excludes the five
  /// prayers entirely once native alarms own them, so it means nothing.
  final int? pendingCount;

  /// The platform's ceiling on [pendingCount] — 64 on iOS.
  final int? pendingCapacity;

  const ReminderHealthProbe({
    required this.notificationsAllowed,
    required this.remindersEnabled,
    this.settingsKnown = true,
    this.exactAlarmsAllowed = true,
    this.batteryExempt = true,
    this.oemAutostartAvailable = false,
    this.mutedAdhanChannelKey,
    this.pendingCount,
    this.pendingCapacity,
  });
}

/// One calm sentence, and at most one thing to press.
class ReminderHealthVerdict {
  final ReminderHealthStatus status;

  /// Localisation key for the sentence.
  final String messageKey;

  /// The Arabic the app says when the key is missing — which
  /// `AppLocalizations.translate` signals by returning the key itself.
  final String fallback;

  final ReminderHealthAction action;

  /// What the verdict was read off, for the detail line under the sentence.
  final ReminderHealthEvidence evidence;

  const ReminderHealthVerdict({
    required this.status,
    required this.messageKey,
    required this.fallback,
    required this.action,
    required this.evidence,
  });
}

/// The counts behind a verdict.
///
/// Exposed because the screen shows a quiet second line, and because a verdict
/// nobody can check is a verdict nobody should believe. **Never rendered as a
/// miss-counter** — that is the brand objection the owner's decision turned on.
class ReminderHealthEvidence {
  /// Alarms that reached the user in some form. The denominator.
  ///
  /// Excludes [orphan]: an alarm the ledger no longer contains did not deliver
  /// a prayer anybody was expecting, and counting it would let a run of them
  /// manufacture a healthy verdict out of nothing.
  final int fired;

  /// Of [fired], how many actually made a sound.
  final int sounded;

  /// Of [fired], how many arrived more than [ReminderHealth.lateThreshold]
  /// after the instant they were armed for.
  final int late;

  /// Armed alarms whose moment passed with nothing firing.
  final int lapsed;

  /// Arrived, but the channel was blocked, so silently.
  final int muted;

  /// Arrived silently because the user had silenced their phone. Their choice,
  /// and never a fault.
  final int silenced;

  /// Arrived as a card with **no adhan**, because the platform refused the
  /// foreground service start. A real degradation, and one an earlier draft
  /// counted as a success.
  final int refused;

  /// Alarms that fired without a matching row in the native plan. A developer
  /// signal that the two ledgers have drifted; never shown to a user.
  final int orphan;

  /// The oldest row considered, so the screen can say how far back it is
  /// looking truthfully rather than guessing.
  final DateTime? since;

  const ReminderHealthEvidence({
    this.fired = 0,
    this.sounded = 0,
    this.late = 0,
    this.lapsed = 0,
    this.muted = 0,
    this.silenced = 0,
    this.refused = 0,
    this.orphan = 0,
    this.since,
  });

  bool get isEmpty => fired == 0 && lapsed == 0 && orphan == 0;

  /// Rows that say something about delivery, either way.
  int get observations => fired + lapsed;
}

/// Turns a ledger plus live platform state into one verdict.
///
/// Pure and static on purpose. Everything that makes this hard to get right —
/// the ordering of causes before symptoms, the refusal to claim *anything* on
/// thin evidence, the rule that the battery prompt needs evidence behind it —
/// is decided here, where a test can drive it with a list of rows and a fixed
/// clock and no device at all.
class ReminderHealth {
  ReminderHealth._();

  /// How far back the verdict looks.
  ///
  /// The ledger holds sixty to ninety days; the verdict reads two weeks,
  /// because a user asking "are my reminders working" means *now*, and a device
  /// that was killing alarms last month and has since been fixed should be
  /// allowed to say so.
  ///
  /// **This is a read-time filter, not a prune.** Nothing is deleted. The rule
  /// that the ledger is never bounded against `now` is about what is kept on
  /// disk — a clock jump here makes one verdict wrong until the clock is fixed,
  /// which is recoverable; the same jump applied to retention would destroy the
  /// evidence permanently.
  static const Duration window = Duration(days: 14);

  /// Later than this and an alarm was not delivered at the instant it was
  /// armed for.
  ///
  /// `setAlarmClock` is exempt from Doze, App Standby and Battery Saver, so on
  /// a device behaving itself the skew is seconds. Two minutes is generous
  /// enough that a slow boot or a busy device does not read as a fault.
  static const Duration lateThreshold = Duration(minutes: 2);

  /// How many delivery observations it takes before the ledger is allowed to
  /// decide **anything**.
  ///
  /// This gate used to sit below the fault branches, which made it a guard on
  /// the *healthy* claim only — so a brand-new install whose first adhan came
  /// three minutes late scored one-late-out-of-one, tripped the share test, and
  /// was told its device was at fault and asked for a system-level battery
  /// exemption. Exactly what the screen's own documentation promises never to
  /// do. The gate now guards every ledger-derived verdict in both directions.
  ///
  /// Live platform certainties — blocked notifications, a muted channel,
  /// revoked exact alarms — are not affected. They are read, not inferred.
  static const int minimumEvidence = 3;

  /// How many lapses it takes to call it a pattern.
  ///
  /// Two, not one: a single lapse is what a reboot across a prayer instant, or
  /// a phone that ran flat, legitimately looks like. Two is a device that is
  /// doing it on purpose — and even then only once [minimumEvidence]
  /// observations exist to put it in proportion.
  static const int lapseThreshold = 2;

  /// How many late arrivals it takes when the ledger is small.
  ///
  /// The count test catches the **large** end: hundreds of rows where a
  /// proportion test would be diluted below its threshold.
  static const int lateCountThreshold = 3;

  /// …or this share of them.
  ///
  /// The share test catches the **small** end: a handful of rows where three
  /// late arrivals never accumulate but half of them are late. Both are needed;
  /// either alone is too lenient at one end of the range.
  static const double lateShareThreshold = 0.25;

  /// How much of the delivery record has to be silent-through-refusal before
  /// that becomes the verdict.
  static const double refusedShareThreshold = 0.25;

  static ReminderHealthVerdict evaluate({
    required List<ReminderLedgerEntry> entries,
    required ReminderHealthProbe probe,
    required DateTime now,
  }) {
    final evidence = summarize(entries: entries, now: now);

    ReminderHealthVerdict verdict(
      ReminderHealthStatus status,
      String key,
      String fallback,
      ReminderHealthAction action,
    ) => ReminderHealthVerdict(
      status: status,
      messageKey: key,
      fallback: fallback,
      action: action,
      evidence: evidence,
    );

    // Nothing can be said before it is known whether the user even wants
    // reminders. Assuming "on" here would diagnose a device whose owner had
    // switched the feature off.
    if (!probe.settingsKnown) {
      return verdict(
        ReminderHealthStatus.unknown,
        'reminder_health.too_early',
        'لم يمرّ وقت كافٍ بعد لنقول شيئًا مؤكّدًا عن التذكيرات.',
        ReminderHealthAction.none,
      );
    }

    // The user's own choice comes first, and is not a fault. Reaching the OEM
    // diagnosis with reminders switched off would tell someone their phone is
    // broken because they turned something off on purpose.
    if (!probe.remindersEnabled) {
      return verdict(
        ReminderHealthStatus.off,
        'reminder_health.off',
        'التذكيرات مُطفأة. شغّلها من إعدادات التنبيهات.',
        ReminderHealthAction.none,
      );
    }

    // --- live certainties, which outrank every inference below --------------

    if (!probe.notificationsAllowed) {
      return verdict(
        ReminderHealthStatus.broken,
        'reminder_health.notifications_blocked',
        'إذن الإشعارات موقوف، فلا يصلك أي تذكير.',
        ReminderHealthAction.openNotificationSettings,
      );
    }

    // Strictly below the notification check above, and it must stay there. The
    // native probe behind `mutedAdhanChannelKey` answers through
    // `PrayerNotifier.channelAllowsAlert`, which returns false when
    // notifications are off **app-wide** — so with these two swapped, a user who
    // had simply denied the notification permission would be sent to fix a
    // channel that was never the problem.
    if (probe.mutedAdhanChannelKey != null) {
      return verdict(
        ReminderHealthStatus.broken,
        'reminder_health.channel_muted',
        'قناة الأذان مكتومة في إعدادات النظام، فيصل التنبيه بلا صوت.',
        ReminderHealthAction.openChannelSettings,
      );
    }

    // Causes before symptoms. With exact alarms revoked the scheduler degrades
    // to `setAndAllowWhileIdle`, which is inexact *by design* — so any lateness
    // below is already explained, and fixing the permission is what fixes it.
    // Diagnosing the OEM here would send the user to a vendor screen to solve a
    // problem this app can ask them to solve in one tap.
    if (!probe.exactAlarmsAllowed) {
      return verdict(
        ReminderHealthStatus.degraded,
        'reminder_health.exact_alarms_off',
        'إذن «المنبّهات الدقيقة» موقوف، فقد يتأخّر الأذان عن وقته.',
        ReminderHealthAction.grantExactAlarms,
      );
    }

    // iOS: the OS is holding nothing at all. Not an inference — it is the
    // platform's own answer, and it means every reminder is gone.
    final pending = probe.pendingCount;
    if (pending != null && pending == 0) {
      return verdict(
        ReminderHealthStatus.broken,
        'reminder_health.nothing_scheduled',
        'لا يحتفظ النظام بأي تذكير مجدول الآن. افتح التطبيق لإعادة جدولتها.',
        ReminderHealthAction.none,
      );
    }

    // --- inferences, none of which may speak on thin evidence ---------------

    if (evidence.observations >= minimumEvidence) {
      // Arrived, but silent. `refused` is the platform declining the
      // foreground-service start that owns the audio: the card appears and no
      // adhan plays. An earlier draft counted these as successful deliveries
      // and showed a green tick to someone who had heard nothing for a week.
      if (evidence.refused > 0 &&
          evidence.fired > 0 &&
          evidence.refused / evidence.fired >= refusedShareThreshold) {
        return verdict(
          ReminderHealthStatus.degraded,
          'reminder_health.silent_delivery',
          'التنبيه يصل لكن الأذان لا يُشغَّل على هذا الجهاز.',
          _deviceAction(probe),
        );
      }

      if (evidence.lapsed >= lapseThreshold) {
        return verdict(
          ReminderHealthStatus.broken,
          'reminder_health.device_stopping',
          'هذا الجهاز يوقف التطبيق، فلم تصل بعض التنبيهات في وقتها.',
          _deviceAction(probe),
        );
      }

      if (_isLate(evidence)) {
        return verdict(
          ReminderHealthStatus.degraded,
          'reminder_health.arriving_late',
          'التنبيهات تصل متأخرة قليلًا عن وقتها على هذا الجهاز.',
          _deviceAction(probe),
        );
      }
    }

    // iOS: the cap is saturated, so the soonest 64 are all the OS will keep and
    // anything beyond them was dropped. Nothing for the user to press — opening
    // the app is what re-fills the window, and they have just done that.
    final capacity = probe.pendingCapacity;
    if (pending != null && capacity != null && pending >= capacity) {
      return verdict(
        ReminderHealthStatus.degraded,
        'reminder_health.at_capacity',
        'وصلت التذكيرات المجدولة إلى حدّ النظام، وقد لا تصل أبعدها. '
            'افتح التطبيق كل بضعة أيام.',
        ReminderHealthAction.none,
      );
    }

    // --- what counts as healthy, per platform -------------------------------

    if (evidence.observations >= minimumEvidence) {
      // Every delivery in the window arrived silently because the user has
      // silenced their phone and «يتجاوز الوضع الصامت» is off. Nothing is
      // wrong — but "your reminders arrive on time" alone would be a strange
      // thing to read after a fortnight of hearing nothing, and this is the one
      // screen where a user comes asking exactly that. Say both halves.
      if (evidence.silenced == evidence.fired && evidence.sounded == 0) {
        return verdict(
          ReminderHealthStatus.healthy,
          'reminder_health.healthy_silent',
          'تذكيراتك تصل في وقتها، لكنها بلا صوت لأن هاتفك صامت '
              'و«يتجاوز الوضع الصامت» مُطفأ.',
          ReminderHealthAction.none,
        );
      }

      return verdict(
        ReminderHealthStatus.healthy,
        'reminder_health.healthy',
        'تذكيراتك تصل في وقتها.',
        ReminderHealthAction.none,
      );
    }

    // iOS has no fire path to report from, so `observations` above is
    // permanently zero there and none of this can ever be reached by evidence.
    //
    // Without this branch every iPhone would sit on "not enough time has passed
    // **yet**" forever — a sentence that promises a verdict which can never
    // arrive. What iOS *can* prove is that the OS is holding the schedule, so
    // that is what is claimed, and the wording claims only that. Scheduling is
    // not delivery, and the screen does not pretend otherwise.
    if (pending != null && pending > 0) {
      return verdict(
        ReminderHealthStatus.healthy,
        'reminder_health.healthy_scheduled',
        'تذكيراتك مجدولة ومحفوظة في النظام.',
        ReminderHealthAction.none,
      );
    }

    // Nothing has gone wrong — but "nothing has gone wrong" and "it is working"
    // are different claims when almost nothing has happened.
    return verdict(
      ReminderHealthStatus.unknown,
      'reminder_health.too_early',
      'لم يمرّ وقت كافٍ بعد لنقول شيئًا مؤكّدًا عن التذكيرات.',
      ReminderHealthAction.none,
    );
  }

  /// The one thing worth pressing when the *device* is the problem.
  ///
  /// Item #16 is this function. The OEM screen goes first where one was
  /// actually found, because on the vendors these branches fire on — Xiaomi,
  /// Oppo, Vivo, Transsion — the battery exemption alone does not stop the
  /// vendor's own task killer.
  ///
  /// Where neither exists, it offers nothing. An honest dead end beats a button
  /// that changes nothing.
  static ReminderHealthAction _deviceAction(ReminderHealthProbe probe) {
    if (probe.oemAutostartAvailable) {
      return ReminderHealthAction.openOemAutostart;
    }
    if (!probe.batteryExempt) return ReminderHealthAction.grantBatteryExemption;
    return ReminderHealthAction.none;
  }

  /// True when late arrivals are a pattern rather than an incident.
  ///
  /// Two tests, because either alone is too lenient at one end of the range.
  /// The **count** catches the large end, where a proportion is diluted: 40
  /// late out of 400 is 10%, under the share threshold, and is still forty
  /// missed prayers. The **share** catches the small end, where a count never
  /// accumulates: two late out of four never reaches three, and is still half
  /// of everything this device has done.
  ///
  /// Neither is consulted until [minimumEvidence] observations exist — see the
  /// gate in [evaluate].
  static bool _isLate(ReminderHealthEvidence evidence) {
    if (evidence.late == 0) return false;
    if (evidence.late >= lateCountThreshold) return true;
    if (evidence.fired == 0) return false;
    return evidence.late / evidence.fired >= lateShareThreshold;
  }

  /// Counts what the last [window] of the ledger contains.
  static ReminderHealthEvidence summarize({
    required List<ReminderLedgerEntry> entries,
    required DateTime now,
  }) {
    final cutoff = now.subtract(window).millisecondsSinceEpoch;

    var fired = 0;
    var sounded = 0;
    var late = 0;
    var lapsed = 0;
    var muted = 0;
    var silenced = 0;
    var refused = 0;
    var orphan = 0;
    int? oldest;

    for (final entry in entries) {
      if (entry.atEpochMs < cutoff) continue;
      // Rows dated in the future are the signature of a clock that has since
      // been corrected backwards. Counting them would let one bad NTP sync
      // months ago keep poisoning the verdict.
      if (entry.atEpochMs > now.millisecondsSinceEpoch) continue;

      oldest = oldest == null
          ? entry.atEpochMs
          : (entry.atEpochMs < oldest ? entry.atEpochMs : oldest);

      switch (entry.type) {
        case ReminderEventType.fired:
          if (entry.outcome == ReminderFireOutcome.orphan) {
            // Deliberately NOT counted as a delivery. An alarm the plan no
            // longer contains rang for nobody, and its `due` is its own arrival
            // instant, so it can never be late either — three of them alone
            // would otherwise read as a perfectly healthy week.
            orphan++;
            break;
          }
          fired++;
          switch (entry.outcome) {
            case ReminderFireOutcome.sounded:
              sounded++;
            case ReminderFireOutcome.muted:
              muted++;
            case ReminderFireOutcome.silent:
              silenced++;
            case ReminderFireOutcome.refused:
              refused++;
            case ReminderFireOutcome.orphan:
            case null:
              break;
          }
          final skew = entry.skew;
          if (skew != null && skew > lateThreshold) late++;
        case ReminderEventType.lapsed:
          lapsed++;
        case ReminderEventType.armed:
        case ReminderEventType.pending:
        case ReminderEventType.trigger:
          break;
      }
    }

    return ReminderHealthEvidence(
      fired: fired,
      sounded: sounded,
      late: late,
      lapsed: lapsed,
      muted: muted,
      silenced: silenced,
      refused: refused,
      orphan: orphan,
      // UTC to match `ReminderLedgerEntry.at`, which is also UTC. The screen
      // renders it in the device's locale; building it local here and reading
      // it as UTC there would shift the reported span by the zone offset.
      since: oldest == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(oldest, isUtc: true),
    );
  }
}
