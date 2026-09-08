import 'package:flutter/foundation.dart';

/// A one-way latch meaning: **this process must not write app data again.**
///
/// ## The problem it closes
///
/// Restoring a backup replaces the contents of `SharedPreferences` underneath
/// a process whose repositories are all cache-first. `AppSettingsRepositoryImpl`
/// holds `_cachedSettings`, `SalahTrackerRepositoryImpl` holds `_cachedLog`,
/// `WirdRepositoryImpl` holds `_cachedPlan` — every one of them loaded at cold
/// start, every one of them writing the whole blob back on the next change.
/// The first such write after a restore silently replaces what the user just
/// recovered with what they had before it. Logging a single prayer would be
/// enough to undo years of records.
///
/// The restore screen therefore becomes a one-way door: back navigation is
/// blocked and the only exit is closing the app. That removes every path the
/// user can *navigate*, but not the one the framework takes on its own —
/// `didChangeAppLifecycleState(resumed)` runs day-rollover work, and
/// `SalahTrackerCubit.refreshIfStale()` calls `syncPause()`, which writes from
/// the stale cache. Background the app on the success screen, come back after
/// midnight, and the restore is quietly undone.
///
/// ## Why a latch rather than cache invalidation
///
/// Invalidating every repository's cache is the fuller fix and is what the
/// dependency-injection cleanup makes practical. Until then, a latch is the
/// honest one: it needs no repository to remember to cooperate, and a
/// repository added tomorrow is covered by it without being told. The cost is
/// that resume-time housekeeping stops — which is exactly right, because the
/// app is about to be restarted anyway and none of that housekeeping matters.
///
/// Deliberately process-lifetime only. It is never persisted: the whole point
/// is that it dies with the process it is protecting, so the next launch — the
/// one that reads the restored data — starts clean.
class RestartRequired {
  RestartRequired._();

  static bool _latched = false;

  /// True once [markRestoreCompleted] has been called in this process.
  static bool get isLatched => _latched;

  /// Called by the restore, immediately after the data lands.
  ///
  /// One-way on purpose: there is no "actually it is fine now". The only
  /// thing that clears it is a new process.
  static void markRestoreCompleted() {
    _latched = true;
    debugPrint(
      'RestartRequired: latched — background writes are now suppressed '
      'until the app is restarted.',
    );
  }

  @visibleForTesting
  static void resetForTest() => _latched = false;
}
