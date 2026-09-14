import 'package:flutter/foundation.dart';

/// The source of "now".
///
/// ## Why this exists
///
/// `DateTime.now()` appears 80-odd times across `lib/`, and every one of them
/// is a place a test cannot reach. That is why the notification layer — the
/// part of this app whose entire job is *being on time* — had no tests at all:
/// there was no way to ask "what does this schedule look like at 04:12 on the
/// night the clocks go back?" without waiting for that night.
///
/// The fix is not to purge `DateTime.now()` everywhere. Most call sites format
/// a date for display and are fine. It is to make the **reliability-critical**
/// paths take their time from an injected [Clock], so their behaviour is a
/// function of their inputs and can be stated in a test.
///
/// Everything here is deliberately trivial. A clock that needs explaining is a
/// clock people work around.
abstract interface class Clock {
  /// The current instant, in local time.
  DateTime now();

  /// Local midnight at the start of today.
  ///
  /// The app keys prayer times, salah-log days and schedule horizons by
  /// normalized day, and re-derives it as `DateTime(n.year, n.month, n.day)`
  /// in a dozen places. Having it here means the day boundary is defined once,
  /// and a fake clock controls it too.
  DateTime today();
}

/// The real clock. Use [systemClock] rather than constructing one.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }
}

/// The single production clock. Injected as a default argument so no caller is
/// forced to thread it, and no caller is prevented from replacing it.
const Clock systemClock = SystemClock();

/// A clock that does not move.
///
/// Lives in `lib/` rather than `test/` on purpose: the scheduling code takes a
/// [Clock] and the tests that matter most for this app are the ones that pin
/// it to an awkward instant — a minute before Fajr, the last day of a horizon,
/// the hour a DST transition repeats.
@visibleForTesting
class FixedClock implements Clock {
  DateTime _now;

  FixedClock(this._now);

  @override
  DateTime now() => _now;

  @override
  DateTime today() => DateTime(_now.year, _now.month, _now.day);

  /// Moves the clock forward. Returns the new instant so a test can read it
  /// back inline.
  DateTime advance(Duration by) => _now = _now.add(by);

  /// Jumps the clock to an exact instant — a timezone change, a user setting
  /// the date by hand, a reboot with a bad RTC.
  ///
  /// Named rather than a `now` setter because [now] is already the getter
  /// method the interface requires.
  void jumpTo(DateTime value) => _now = value;
}
