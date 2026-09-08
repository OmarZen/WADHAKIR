/// The four groups a backup file is described in, so the export and restore
/// screens can tell the user what is actually in the file instead of showing
/// an opaque key count.
enum BackupSection {
  /// The irreplaceable part: years of salah log, the khatma plan, every dhikr
  /// counter. This is the reason the feature exists.
  worship,

  /// Preferences and every reminder schedule.
  settings,

  /// Calculation method, madhab, per-prayer minute offsets.
  prayerTimes,

  /// The cached coordinates and city name.
  location,
}

/// The value types SharedPreferences can hold, and therefore the only types a
/// backup file may declare.
///
/// The single-letter tags are what goes on disk. They are short because the
/// tag repeats on every entry, and stable because changing one would break
/// every backup file already in a user's Drive.
enum BackupValueType {
  string('s'),
  boolean('b'),
  integer('i'),
  decimal('d'),
  stringList('l');

  final String tag;
  const BackupValueType(this.tag);

  static BackupValueType? fromTag(String tag) {
    for (final t in BackupValueType.values) {
      if (t.tag == tag) return t;
    }
    return null;
  }
}

/// One allowlisted key with a fixed name.
class BackupKeySpec {
  final String key;
  final BackupValueType type;
  final BackupSection section;

  const BackupKeySpec(this.key, this.type, this.section);
}

/// A family of keys generated at runtime, which can only be found by scanning
/// [SharedPreferences.getKeys] for a prefix.
class BackupPrefixSpec {
  final String prefix;
  final BackupValueType type;
  final BackupSection section;

  const BackupPrefixSpec(this.prefix, this.type, this.section);
}

/// What a backup file may contain, and — just as importantly — what it may
/// never contain.
///
/// ## Why an allowlist and not "export everything"
///
/// `SharedPreferences.getKeys()` returns keys written by plugins as well as by
/// this app. Several of them are *device* facts wearing the costume of user
/// data, and copying them to a new phone breaks it silently. The worst example
/// is [_batteryOptPromptedKey] — see [denyKeys]. An allowlist means a key can
/// only ever travel between devices because somebody decided it should.
///
/// ## Scope of this file
///
/// Everything here is expressed in terms of the **Dart** SharedPreferences API
/// and its bare key names. On Android these are physically stored as
/// `flutter.<key>` inside a Jetpack DataStore protobuf, and doubles and string
/// lists are re-encoded as tagged strings. None of that is visible — or may be
/// relied upon — from here. Backup and restore go through the Dart API in both
/// directions, which is the only way the encoding stays correct.
///
/// Stores that live outside the Flutter preference namespace are invisible to
/// `getKeys()` and are therefore out of scope by construction:
/// `HomeWidgetPreferences` (the home-screen widget mirror),
/// `InternalHomeWidgetPreferences` (AOT callback handles),
/// `floating_dhikr_native.xml` (the overlay service's own copy of its config),
/// and the awesome_notifications stores. All of them are derived state that
/// the app rebuilds on the next launch.
class BackupKeys {
  BackupKeys._();

  // ---------------------------------------------------------------------
  // Worship data — the part a lost phone actually destroys.
  // ---------------------------------------------------------------------

  static const List<BackupKeySpec> _worship = [
    // Years of daily prayer records, including the excused-days state.
    BackupKeySpec(
      'salah_tracker_log',
      BackupValueType.string,
      BackupSection.worship,
    ),
    // The khatma plan: goal, progress, dedication and intention.
    BackupKeySpec('wird_plan', BackupValueType.string, BackupSection.worship),
    // Nisab basis, gold/silver prices, the user's asset figures.
    BackupKeySpec(
      'zakat_settings',
      BackupValueType.string,
      BackupSection.worship,
    ),
    // Electronic tasbih: current count, lifetime total, chosen target.
    BackupKeySpec(
      'electronic_tasbih_counter',
      BackupValueType.integer,
      BackupSection.worship,
    ),
    BackupKeySpec(
      'electronic_tasbih_total',
      BackupValueType.integer,
      BackupSection.worship,
    ),
    BackupKeySpec(
      'electronic_tasbih_target',
      BackupValueType.integer,
      BackupSection.worship,
    ),
  ];

  /// Per-dhikr counters, keyed `<prefix><text.hashCode>`.
  ///
  /// These CANNOT be enumerated from the asset JSON, and must not be. The
  /// suffix is `String.hashCode` of the Arabic dhikr text — a Dart VM
  /// implementation detail with no cross-version or cross-platform stability
  /// guarantee. Scanning `getKeys()` for the prefix copies whatever the device
  /// actually holds, which is the only definition that is true by
  /// construction.
  ///
  /// The prefixes are declared at
  /// `home/views/widgets/grids/{pray_azkar,raqia,tasbih}_grid_item.dart` and
  /// consumed in `home/views/widgets/shared/azkar_shared_widgets.dart`;
  /// `prayer_adhkar_` is built by `PrayerAdhkarData.prefsKey`.
  ///
  /// Note `tasbih_` does not collide with `electronic_tasbih_*` above — those
  /// begin with `electronic_`.
  static const List<BackupPrefixSpec> _worshipPrefixes = [
    BackupPrefixSpec(
      'pray_azkar_',
      BackupValueType.integer,
      BackupSection.worship,
    ),
    BackupPrefixSpec('raqia_', BackupValueType.integer, BackupSection.worship),
    BackupPrefixSpec('tasbih_', BackupValueType.integer, BackupSection.worship),
    BackupPrefixSpec(
      'prayer_adhkar_',
      BackupValueType.integer,
      BackupSection.worship,
    ),
  ];

  // ---------------------------------------------------------------------
  // Settings and reminders.
  // ---------------------------------------------------------------------

  static const List<BackupKeySpec> _settings = [
    BackupKeySpec(
      'theme_mode',
      BackupValueType.integer,
      BackupSection.settings,
    ),
    BackupKeySpec(
      'language_code',
      BackupValueType.string,
      BackupSection.settings,
    ),
    BackupKeySpec(
      'show_basmala',
      BackupValueType.boolean,
      BackupSection.settings,
    ),
    BackupKeySpec(
      'text_scale',
      BackupValueType.decimal,
      BackupSection.settings,
    ),
    BackupKeySpec('user_name', BackupValueType.string, BackupSection.settings),
    // Prayer notification schedule: master toggle, per-prayer timing, sound.
    BackupKeySpec(
      'notification_settings',
      BackupValueType.string,
      BackupSection.settings,
    ),
    // Morning/evening/witr/sleep/duha/qiyam/Kahf/after-prayer reminders.
    BackupKeySpec(
      'azkar_reminder_settings',
      BackupValueType.string,
      BackupSection.settings,
    ),
    BackupKeySpec(
      'daily_inspiration_settings',
      BackupValueType.string,
      BackupSection.settings,
    ),
    BackupKeySpec(
      'fasting_reminder_settings',
      BackupValueType.string,
      BackupSection.settings,
    ),
    // Included even though `enabled` needs Android's overlay permission on the
    // target device. Unlike app-lock (see denyKeys) the contents are
    // user-authored and portable — interval, quiet hours, anchor, source,
    // opacity — and losing them means reconfiguring by hand. If the permission
    // is missing the overlay simply does not start, which is the same
    // behaviour as revoking it on the source device.
    BackupKeySpec(
      'floating_dhikr_settings_v1',
      BackupValueType.string,
      BackupSection.settings,
    ),
    BackupKeySpec(
      'feature_nudge_enabled',
      BackupValueType.boolean,
      BackupSection.settings,
    ),
    // One-shot gates that belong with the name they guard: restoring
    // `user_name` without these would make the app ask for a name it already
    // has.
    BackupKeySpec(
      'name_prompt_seen',
      BackupValueType.boolean,
      BackupSection.settings,
    ),
    BackupKeySpec(
      'islamic_background_used',
      BackupValueType.boolean,
      BackupSection.settings,
    ),
  ];

  // ---------------------------------------------------------------------
  // Prayer-time calculation.
  // ---------------------------------------------------------------------

  static const List<BackupKeySpec> _prayerTimes = [
    // A CalculationMethodMapper slug: 'egyptian', 'umm_al_qura', …
    BackupKeySpec(
      'prayer_times_calculation_method',
      BackupValueType.string,
      BackupSection.prayerTimes,
    ),
    // Exactly 'shafi' or 'hanafi' — the Asr rule.
    BackupKeySpec(
      'prayer_times_madhab',
      BackupValueType.string,
      BackupSection.prayerTimes,
    ),
    // NOT JSON: a bare `name:minutes,name:minutes` string built in
    // PrayerTimesCubit. Copied verbatim, never parsed here.
    BackupKeySpec(
      'prayer_time_adjustments',
      BackupValueType.string,
      BackupSection.prayerTimes,
    ),
  ];

  // ---------------------------------------------------------------------
  // Location.
  // ---------------------------------------------------------------------

  static const List<BackupKeySpec> _location = [
    BackupKeySpec(
      'prayer_times_last_latitude',
      BackupValueType.decimal,
      BackupSection.location,
    ),
    BackupKeySpec(
      'prayer_times_last_longitude',
      BackupValueType.decimal,
      BackupSection.location,
    ),
    BackupKeySpec(
      'prayer_times_last_location_name',
      BackupValueType.string,
      BackupSection.location,
    ),
  ];

  /// Every fixed key a backup may carry, in section order.
  static const List<BackupKeySpec> allowKeys = [
    ..._worship,
    ..._settings,
    ..._prayerTimes,
    ..._location,
  ];

  /// Every runtime-generated key family a backup may carry.
  static const List<BackupPrefixSpec> allowPrefixes = _worshipPrefixes;

  /// Keys that exist in the app's own preference namespace and are
  /// deliberately excluded. Each entry is a decision, not an oversight, so
  /// each one carries its reason.
  ///
  /// The deny list is checked FIRST on both export and restore. A key here can
  /// never travel, even if a future edit accidentally adds it above and even
  /// if a hand-edited backup file names it.
  static const Set<String> denyKeys = {
    // The single most damaging key in the app to restore. It is a one-shot
    // "already asked" gate:
    //   if (prefs.getBool('battery_opt_prompted') ?? false) return;
    // Carrying `true` to a new phone means that phone is never asked for a
    // battery-optimisation exemption, so Doze is free to defer or drop every
    // adhan and every reminder — the app's core promise — with no UI anywhere
    // to recover. The new device must ask for itself.
    _batteryOptPromptedKey,

    // The other half of the same gate: when this device last asked and was
    // declined. Carrying it across would import a cooling-off period the new
    // device never earned, delaying a prompt it has not yet shown once.
    _batteryOptDeferredAtKey,

    // An early-return guard on country-based method detection. Leaving it
    // behind is not just safe, it is correct: on the new device the detector
    // runs, sees that a calculation method is already stored (restored from
    // the backup), keeps it, and sets the flag itself. Restoring the flag
    // instead would pin the source device's country forever.
    //
    // The one case that needs care is a restore that REMOVES the method key —
    // see [calcMethodAutoDetectedKey] and BackupService.restore.
    calcMethodAutoDetectedKey,

    // Restoring `true` would let a device skip onboarding, and with it the
    // location permission request that onboarding exists to make. There is
    // nothing to gain: a user reaches the restore screen through Settings, so
    // onboarding is already behind them.
    'onboarding_completed',

    // The value is a list of OTHER apps' Android package names, chosen on the
    // source device, gating a feature that needs three separate Android
    // permission grants (usage access, overlay, accessibility). Restored onto
    // a new phone it either locks nothing or locks apps the user never chose,
    // while the settings screen reports the feature as on. A settings screen
    // that lies is worse than a setting the user re-enters.
    'app_lock_settings',

    // Rotation state for the feature-discovery nudge: which nudges this
    // device has shown, and when. Device-scoped bookkeeping, not a
    // preference. `feature_nudge_enabled` — the actual preference — is
    // allowed above.
    'feature_nudge_last_shown',
    'feature_nudge_shown_ids',

    // Flutter AOT callback handles from the build that wrote them. These live
    // in a separate preference store and so cannot appear in `getKeys()`
    // anyway; they are named here so that stays true by intent rather than by
    // accident.
    'callbackDispatcherHandle',
    'callbackHandle',
  };

  /// Prefix families that may never travel, checked before [allowPrefixes].
  ///
  /// `home_widget.` tags every value the home_widget plugin stores with its
  /// runtime type. The tags must stay in lockstep with the values they
  /// describe, and those values are regenerated on every app resume.
  static const Set<String> denyPrefixes = {'home_widget.'};

  // Kept as literals rather than importing AlarmPermissionHelper: this file is
  // pure data with no Flutter dependency, and the deny list is a contract
  // about strings on disk, not about which class writes them.
  static const String _batteryOptPromptedKey = 'battery_opt_prompted';
  static const String _batteryOptDeferredAtKey = 'battery_opt_deferred_at';

  /// The calculation-method slug, and the denied flag that guards its
  /// auto-detection.
  ///
  /// Named here because [BackupService.restore] has to treat them as a pair.
  /// The flag is denied — a restore must not carry the source device's
  /// "already detected" state — but the two are coupled in one direction:
  /// `_autoDetectCalculationMethod` early-returns while the flag is true, so a
  /// device left with the flag set and NO method stored falls back to the
  /// hardcoded Egyptian parameters and never re-detects. That is silently
  /// wrong prayer times, which is the one failure this app cannot have.
  static const String calculationMethodKey = 'prayer_times_calculation_method';
  static const String calcMethodAutoDetectedKey =
      'prayer_times_calc_method_auto_detected';

  static final Map<String, BackupKeySpec> _byKey = {
    for (final spec in allowKeys) spec.key: spec,
  };

  /// Resolves [key] to its spec, or null if the key may not be backed up.
  ///
  /// This is the single gate. Export asks it about every key on the device;
  /// restore asks it about every key in the file. Neither writes anything it
  /// says no to.
  static BackupKeySpec? specFor(String key) {
    if (denyKeys.contains(key)) return null;
    for (final denied in denyPrefixes) {
      if (key.startsWith(denied)) return null;
    }
    final exact = _byKey[key];
    if (exact != null) return exact;
    for (final prefix in allowPrefixes) {
      if (key.startsWith(prefix.prefix)) {
        return BackupKeySpec(key, prefix.type, prefix.section);
      }
    }
    return null;
  }
}
