class AppConstants {
  // App Info
  static const String appName = 'Wadhakir';
  static const String appVersion = '1.0.0';

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

  // Assets Paths
  static const String langPath = 'assets/lang/';
  static const String arabicLangFile = 'ar.json';
  static const String englishLangFile = 'en.json';
}
