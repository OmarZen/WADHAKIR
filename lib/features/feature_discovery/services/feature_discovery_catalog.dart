import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/features/feature_discovery/models/feature_nudge.dart';

/// The ordered list of feature-discovery nudges. Order = rotation order.
///
/// Each `isEligible` predicate reads an EXISTING settings signal and returns
/// true only while the feature is still un-used / un-enabled — so once the user
/// adopts a feature, its nudge drops out of rotation automatically.
class FeatureDiscoveryCatalog {
  FeatureDiscoveryCatalog._();

  static final List<FeatureNudge> nudges = [
    FeatureNudge(
      id: 'zakat',
      titleAr: 'حاسبة الزكاة',
      bodyAr: 'احسب زكاة مالك بسهولة — جرّب حاسبة الزكاة الآن',
      target: 'open_zakat',
      // No stored zakat settings yet → never opened the calculator.
      isEligible: (p) => p.getString(AppConstants.zakatSettingsKey) == null,
    ),
    FeatureNudge(
      id: 'prayer_reminders',
      titleAr: 'مواقيت الصلاة',
      bodyAr: 'فعّل تذكير مواقيت الصلاة ليصلك التنبيه في وقته',
      target: 'open_prayer_settings',
      isEligible: (p) => !_jsonBool(
        p,
        AppConstants.notificationSettingsKey,
        'masterEnabled',
      ),
    ),
    FeatureNudge(
      id: 'wird',
      titleAr: 'وردك اليومي',
      bodyAr: 'حدّد وردك اليومي من القرآن وابدأ بالتلاوة',
      target: 'open_wird',
      // wird_plan stores `isActive`; absent/false → no active plan.
      isEligible: (p) => !_jsonBool(p, 'wird_plan', 'isActive'),
    ),
    FeatureNudge(
      id: 'azkar_reminders',
      titleAr: 'تذكيرات الأذكار',
      bodyAr: 'فعّل تذكير أذكار الصباح والمساء وأذكار ما بعد الصلاة',
      target: 'open_azkar_reminders',
      isEligible: (p) => !_anyAzkarEnabled(p),
    ),
    FeatureNudge(
      id: 'daily_inspiration',
      titleAr: 'آية وذِكر اليوم',
      bodyAr: 'فعّل تذكير آية ودعاء كل يوم لتبدأ يومك بخير',
      target: 'open_daily_inspiration',
      isEligible: (p) =>
          !_jsonBool(p, AppConstants.dailyInspirationSettingsKey, 'enabled'),
    ),
    FeatureNudge(
      id: 'islamic_backgrounds',
      titleAr: 'خلفية إسلامية',
      bodyAr: 'اصنع خلفية إسلامية جميلة لهاتفك في دقائق',
      target: 'open_backgrounds',
      isEligible: (p) =>
          !(p.getBool(AppConstants.islamicBackgroundUsedKey) ?? false),
    ),
    FeatureNudge(
      id: 'fasting',
      titleAr: 'تذكيرات الصيام',
      bodyAr: 'فعّل تذكيرات صيام الإثنين والخميس والأيام البيض',
      target: 'open_fasting',
      isEligible: (p) => !_anyFastingEnabled(p),
    ),
  ];

  /// Read a boolean field from a JSON-encoded preference; false on any miss.
  static bool _jsonBool(SharedPreferences p, String key, String field) {
    final raw = p.getString(key);
    if (raw == null) return false;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map[field] == true;
    } catch (_) {
      return false;
    }
  }

  static bool _anyAzkarEnabled(SharedPreferences p) {
    final raw = p.getString(AppConstants.azkarReminderSettingsKey);
    if (raw == null) return false;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      const flags = [
        'morningEnabled',
        'eveningEnabled',
        'afterPrayerEnabled',
        'qiyamEnabled',
        'fridayKahfEnabled',
        'witrEnabled',
        'duhaEnabled',
        'sleepEnabled',
      ];
      return flags.any((f) => m[f] == true);
    } catch (_) {
      return false;
    }
  }

  static bool _anyFastingEnabled(SharedPreferences p) {
    final raw = p.getString('fasting_reminder_settings');
    if (raw == null) return false;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      const flags = [
        'monthlyFastingRemindersEnabled',
        'mondayFastingEnabled',
        'thursdayFastingEnabled',
      ];
      return flags.any((f) => m[f] == true);
    } catch (_) {
      return false;
    }
  }
}
