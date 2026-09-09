class AppConstants {
  // App Info
  static const String appName = 'Wadhakir';
  // No appVersion here on purpose: it was never read, and a hand-maintained
  // copy of the version only ever drifts from pubspec.yaml. Read it at runtime
  // via PackageInfo.fromPlatform() instead (see AboutSectionWidgets).

  // Navigation Routes
  static const String homeRoute = '/';
  static const String homeScreenRoute = '/home';
  static const String quranRoute = '/quran';
  static const String hisnRoute = '/hisn';
  static const String azkarRoute = '/azkar';
  static const String settingsRoute = '/settings';
  static const String surahDetailsRoute = '/surah-details';
  static const String hisnCategoryDetailsRoute = '/hisn-category-details';
  static const String azkarCategoryDetailsRoute = '/azkar-category-details';
  static const String prayerTimesRoute = '/prayer-times';
  static const String campusRoute = '/campus';
  static const String radioRoute = '/radio';
  static const String floatingDhikrSettingsRoute = '/floating-dhikr-settings';
  static const String moonPhasesRoute = '/moon-phases';
  static const String shareRoute = '/share';
  static const String wirdRoute = '/wird';
  static const String islamicBackgroundsRoute = '/islamic-backgrounds';
  static const String zakatRoute = '/zakat';
  static const String dailyInspirationSettingsRoute =
      '/daily-inspiration-settings';
  static const String afterPrayerAdhkarRoute = '/after-prayer-adhkar';
  static const String azkarRemindersSettingsRoute = '/azkar-reminders-settings';
  static const String salahTrackerRoute = '/salah-tracker';

  // External links — used by the branded share-image flow so the caption
  // and the on-card wordmark stay in sync no matter which screen invokes
  // share. Single source of truth for the Play Store URL.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.bloom.wadhakir';
  static const String websiteLabel = 'wadhakir.app';

  // SharedPreferences Keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String showBasmalaKey = 'show_basmala';
  static const String notificationSettingsKey = 'notification_settings';
  static const String appLockSettingsKey = 'app_lock_settings';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String userNameKey = 'user_name';
  static const String textScaleKey = 'text_scale';
  // One-time gate for the existing-user name prompt (set true once the prompt
  // has been shown or onboarding finished, so it never nags again).
  static const String namePromptSeenKey = 'name_prompt_seen';
  static const String zakatSettingsKey = 'zakat_settings';
  static const String dailyInspirationSettingsKey =
      'daily_inspiration_settings';
  static const String azkarReminderSettingsKey = 'azkar_reminder_settings';
  static const String salahTrackerLogKey = 'salah_tracker_log';

  // Feature-discovery / re-engagement nudges
  static const String featureNudgeEnabledKey = 'feature_nudge_enabled';

  /// Escape hatch for the native `AlarmManager` prayer alarms.
  ///
  /// Set true to put this device back on the `awesome_notifications` path
  /// without shipping a build. Absent/false means native, which is the default
  /// for everyone. Reached from Settings by long-pressing the version number.
  static const String nativePrayerAlarmsDisabledKey =
      'native_prayer_alarms_disabled';
  static const String featureNudgeLastShownKey = 'feature_nudge_last_shown';
  static const String featureNudgeShownIdsKey = 'feature_nudge_shown_ids';

  // First-use flags for features that lack another usage signal
  static const String islamicBackgroundUsedKey = 'islamic_background_used';

  // adhkar.json category titles — used as route arguments to deep-link into a
  // specific azkar category from a notification.
  static const String azkarMorningEveningCategory = 'أذكار الصباح والمساء';
  static const String azkarSleepCategory = 'أذكار النوم';

  // Assets Paths
  static const String langPath = 'assets/lang/';
  static const String arabicLangFile = 'ar.json';
  static const String englishLangFile = 'en.json';
}
