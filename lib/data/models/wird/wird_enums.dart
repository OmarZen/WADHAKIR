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
