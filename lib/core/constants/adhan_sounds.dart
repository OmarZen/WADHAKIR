/// Constants for Adhan sound files.
///
/// Each selectable adhan carries two references:
///  * [path]        — the Flutter asset, used ONLY for the in-app preview in
///                    the sound picker.
///  * [androidRawRes] — the ASCII `res/raw` resource name (no extension) that
///                    the Android notification CHANNEL bakes in as its sound so
///                    the correct adhan plays reliably even when the app is
///                    killed. (Android channel sound is immutable once created,
///                    hence one channel per sound — see NotificationRepository.)
///
/// [androidRawRes] doubles as the iOS sound reference: the scheduler passes
/// `resource://raw/<androidRawRes>` as `customSound`, and AwnCore's
/// `AudioUtils.getSoundFromResource` keeps only the last path segment (dropping
/// `raw/`) and appends a HARDCODED `.aiff` — resolving to `<androidRawRes>.aiff`
/// at the Runner bundle ROOT. That is why the iOS clips are .aiff (not .caf or
/// .mp3), live in ios/Runner/Sounds/, and must be added to the Runner target as
/// a normal group — a blue folder reference would nest them and break the flat
/// lookup. Regenerate them with ios/Runner/Sounds/generate_adhan_aiff.sh.
///
/// A `null` [path] means the "Default" option → the system notification beep
/// (no baked adhan). `customSoundPath` in the settings model stores [path], and
/// [byAssetPath] resolves it back to the option (and thus its channel key).
class AdhanSounds {
  // Fajr-specific adhan sounds
  static const List<AdhanSoundOption> fajrSounds = [
    AdhanSoundOption(
      key: 'default',
      name: 'الصوت الافتراضي',
      nameEn: 'Default Sound',
      path: null, // null means use system default (short beep)
    ),
    AdhanSoundOption(
      key: 'adhan_fajr_makkah',
      name: 'أذان الفجر - مكة المكرمة',
      nameEn: 'Fajr Adhan - Makkah',
      path: 'assets/adhan_sounds/أذان الفجر - مكه المكرمة.mp3',
      androidRawRes: 'adhan_fajr_makkah',
    ),
    AdhanSoundOption(
      key: 'adhan_fajr_madinah',
      name: 'أذان الفجر - المدينة المنورة',
      nameEn: 'Fajr Adhan - Madinah',
      path: 'assets/adhan_sounds/أذان الفجر - المدينة المنورة.mp3',
      androidRawRes: 'adhan_fajr_madinah',
    ),
    AdhanSoundOption(
      key: 'adhan_fajr_egypt',
      name: 'أذان الفجر - مصر',
      nameEn: 'Fajr Adhan - Egypt',
      path: 'assets/adhan_sounds/أذان الفجر - مصــــر.mp3',
      androidRawRes: 'adhan_fajr_egypt',
    ),
    AdhanSoundOption(
      key: 'adhan_fajr_cairo',
      name: 'أذان الفجر - القاهرة',
      nameEn: 'Fajr Adhan - Cairo',
      path: 'assets/adhan_sounds/أذان-الفجر-مصر.mp3',
      androidRawRes: 'adhan_fajr_cairo',
    ),
  ];

  // Regular prayer adhan sounds (for Dhuhr, Asr, Maghrib, Isha)
  static const List<AdhanSoundOption> regularSounds = [
    AdhanSoundOption(
      key: 'default',
      name: 'الصوت الافتراضي',
      nameEn: 'Default Sound',
      path: null, // null means use system default (short beep)
    ),
    AdhanSoundOption(
      key: 'adhan_makkah_raml',
      name: 'الحرم المكي - محمد رمل',
      nameEn: 'Makkah - Mohammed Raml',
      path: 'assets/adhan_sounds/أذان-الحرم-المكي-محمد-رمل.mp3',
      androidRawRes: 'adhan_makkah_raml',
    ),
    AdhanSoundOption(
      key: 'adhan_makkah_haram',
      name: 'الحرم المكي',
      nameEn: 'Makkah Haram',
      path: 'assets/adhan_sounds/أذان-الحرم-المكي-1.mp3',
      androidRawRes: 'adhan_makkah_haram',
    ),
    AdhanSoundOption(
      key: 'adhan_makkah2',
      name: 'مكة المكرمة',
      nameEn: 'Makkah Al-Mukarramah',
      path: 'assets/adhan_sounds/أذان-مكة-المكرمة-2.mp3',
      androidRawRes: 'adhan_makkah2',
    ),
    AdhanSoundOption(
      key: 'adhan_cairo_rifat',
      name: 'القاهرة - محمد رفعت',
      nameEn: 'Cairo - Mohammed Rifat',
      path: 'assets/adhan_sounds/أذان-القاهرة-محمد-رفعت.mp3',
      androidRawRes: 'adhan_cairo_rifat',
    ),
    AdhanSoundOption(
      key: 'adhan_cairo_abdulbasit',
      name: 'القاهرة - عبد الباسط عبد الصمد',
      nameEn: 'Cairo - Abdulbasit Abdussamad',
      path: 'assets/adhan_sounds/أذان-القاهرة-عبدالباسط-عبد-الصمد.mp3',
      androidRawRes: 'adhan_cairo_abdulbasit',
    ),
    AdhanSoundOption(
      key: 'adhan_cairo_banna',
      name: 'القاهرة - محمد علي البنا',
      nameEn: 'Cairo - Mohammed Ali Al-Banna',
      path: 'assets/adhan_sounds/أذان-القاهرة-محمد-على-البنا.mp3',
      androidRawRes: 'adhan_cairo_banna',
    ),
    AdhanSoundOption(
      key: 'adhan_cairo_hussary',
      name: 'القاهرة - محمود خليل الحصري',
      nameEn: 'Cairo - Mahmoud Khalil Al-Hussary',
      path: 'assets/adhan_sounds/أذان-القاهرة-محمود-خليل-الحصرى.mp3',
      androidRawRes: 'adhan_cairo_hussary',
    ),
    AdhanSoundOption(
      key: 'adhan_cairo_sheesha',
      name: 'القاهرة - أبو العنين شعيشع',
      nameEn: 'Cairo - Abu Al-Enin Sheesha',
      path: 'assets/adhan_sounds/الأذان-القاهرة-أبو-العنين-شعيشع.mp3',
      androidRawRes: 'adhan_cairo_sheesha',
    ),
    AdhanSoundOption(
      key: 'adhan_cairo_nuaynua',
      name: 'القاهرة - أحمد نعينع',
      nameEn: 'Cairo - Ahmed Nuaynua',
      path: 'assets/adhan_sounds/أذان-القاهرة-أحمد-نعينع.mp3',
      androidRawRes: 'adhan_cairo_nuaynua',
    ),
  ];

  /// Every adhan option across both lists, de-duplicated by [key]. Used by the
  /// notification repository to create one Android channel per baked sound.
  static List<AdhanSoundOption> get all {
    final seen = <String>{};
    final result = <AdhanSoundOption>[];
    for (final o in [...fajrSounds, ...regularSounds]) {
      if (o.androidRawRes == null) continue; // skip the "default" beep option
      if (seen.add(o.key)) result.add(o);
    }
    return result;
  }

  /// Get adhan sound path for a specific prayer
  static String? getSoundPath(String? customPath) {
    return customPath;
  }

  /// Check if a sound is the default sound
  static bool isDefaultSound(String? path) {
    return path == null || path.isEmpty;
  }

  /// Resolve a stored `customSoundPath` (a Flutter asset path) back to its
  /// option, so callers can read its [key] and [androidRawRes]. Returns null for
  /// the default (system-beep) option.
  static AdhanSoundOption? byAssetPath(String? path) {
    if (path == null || path.isEmpty) return null;
    for (final o in [...fajrSounds, ...regularSounds]) {
      if (o.path == path) return o;
    }
    return null;
  }
}

/// Model for an adhan sound option
class AdhanSoundOption {
  /// Stable identifier, also the Android channel suffix. `'default'` = beep.
  final String key;
  final String name;
  final String nameEn;

  /// Flutter asset path, used for the in-app preview. Null = system default beep.
  final String? path;

  /// ASCII `res/raw` resource name (no extension). Baked into an Android channel
  /// as its sound, and resolved on iOS to `<androidRawRes>.aiff` in the Runner
  /// bundle — see the class-level docs on [AdhanSounds].
  final String? androidRawRes;

  const AdhanSoundOption({
    required this.key,
    required this.name,
    required this.nameEn,
    required this.path,
    this.androidRawRes,
  });

  bool get isDefault => path == null || path!.isEmpty;
}
