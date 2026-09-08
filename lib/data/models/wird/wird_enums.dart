/// Tracking unit for a Quran wird (daily reading plan).
///
/// Mirrors the "وحدة التتبع" options in the setup screen:
/// - [pages]: صفحات — plain Mushaf pages.
/// - [rub]:   ربع (ربع جزء) — a quarter of a juz (4 per juz).
/// - [hizb]:  حزب (نصف جزء) — half a juz (2 per juz).
/// - [juz]:   جزء — a full juz (30 total).
enum WirdUnit { pages, rub, hizb, juz }

/// Goal type for the plan.
///
/// Only [fixedDailyAmount] is implemented for now. [finishByDate] is kept
/// for forward-compatibility (compute the daily amount from a target date).
enum WirdGoalMode { fixedDailyAmount, finishByDate }

/// The intention a khatma is dedicated to.
///
/// إهداء الثواب — dedicating the reward of a completed reading — is one of the
/// most emotionally loaded practices in Arab Muslim life, and is frequently the
/// *reason* a khatma is undertaken at all. Carrying it turns the wird from a
/// progress tracker (which is SaaS-shaped and off-brand) into a devotional act.
enum WirdIntention {
  /// No dedication — the default, and never presented as a missing field.
  none,

  /// For someone who has passed away.
  forDeceased,

  /// For someone who is ill.
  forHealing,

  /// In gratitude.
  forGratitude,

  /// A free-text intention the user wrote.
  custom,
}
