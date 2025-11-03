/// Constants for Adhan sound files
class AdhanSounds {
  // Fajr-specific adhan sounds
  static const List<AdhanSoundOption> fajrSounds = [
    AdhanSoundOption(
      name: 'الصوت الافتراضي',
      nameEn: 'Default Sound',
      path: null, // null means use system default
    ),
    AdhanSoundOption(
      name: 'أذان الفجر - مكة المكرمة',
      nameEn: 'Fajr Adhan - Makkah',
      path: 'assets/adhan_sounds/أذان الفجر - مكه المكرمة.mp3',
    ),
    AdhanSoundOption(
      name: 'أذان الفجر - المدينة المنورة',
      nameEn: 'Fajr Adhan - Madinah',
      path: 'assets/adhan_sounds/أذان الفجر - المدينة المنورة.mp3',
    ),
    AdhanSoundOption(
      name: 'أذان الفجر - مصر',
      nameEn: 'Fajr Adhan - Egypt',
      path: 'assets/adhan_sounds/أذان الفجر - مصــــر.mp3',
    ),
    AdhanSoundOption(
      name: 'أذان الفجر - القاهرة',
      nameEn: 'Fajr Adhan - Cairo',
      path: 'assets/adhan_sounds/أذان-الفجر-مصر.mp3',
    ),
  ];

  // Regular prayer adhan sounds (for Dhuhr, Asr, Maghrib, Isha)
  static const List<AdhanSoundOption> regularSounds = [
    AdhanSoundOption(
      name: 'الصوت الافتراضي',
      nameEn: 'Default Sound',
      path: null, // null means use system default
    ),
    AdhanSoundOption(
      name: 'الحرم المكي - محمد رمل',
      nameEn: 'Makkah - Mohammed Raml',
      path: 'assets/adhan_sounds/أذان-الحرم-المكي-محمد-رمل.mp3',
    ),
    AdhanSoundOption(
      name: 'الحرم المكي',
      nameEn: 'Makkah Haram',
      path: 'assets/adhan_sounds/أذان-الحرم-المكي-1.mp3',
    ),
    AdhanSoundOption(
      name: 'مكة المكرمة',
      nameEn: 'Makkah Al-Mukarramah',
      path: 'assets/adhan_sounds/أذان-مكة-المكرمة-2.mp3',
    ),
    AdhanSoundOption(
      name: 'القاهرة - محمد رفعت',
      nameEn: 'Cairo - Mohammed Rifat',
      path: 'assets/adhan_sounds/أذان-القاهرة-محمد-رفعت.mp3',
    ),
    AdhanSoundOption(
      name: 'القاهرة - عبد الباسط عبد الصمد',
      nameEn: 'Cairo - Abdulbasit Abdussamad',
      path: 'assets/adhan_sounds/أذان-القاهرة-عبدالباسط-عبد-الصمد.mp3',
    ),
    AdhanSoundOption(
      name: 'القاهرة - محمد علي البنا',
      nameEn: 'Cairo - Mohammed Ali Al-Banna',
      path: 'assets/adhan_sounds/أذان-القاهرة-محمد-على-البنا.mp3',
    ),
    AdhanSoundOption(
      name: 'القاهرة - محمود خليل الحصري',
      nameEn: 'Cairo - Mahmoud Khalil Al-Hussary',
      path: 'assets/adhan_sounds/أذان-القاهرة-محمود-خليل-الحصرى.mp3',
    ),
    AdhanSoundOption(
      name: 'القاهرة - أبو العنين شعيشع',
      nameEn: 'Cairo - Abu Al-Enin Sheesha',
      path: 'assets/adhan_sounds/الأذان-القاهرة-أبو-العنين-شعيشع.mp3',
    ),
    AdhanSoundOption(
      name: 'القاهرة - أحمد نعينع',
      nameEn: 'Cairo - Ahmed Nuaynua',
      path: 'assets/adhan_sounds/أذان-القاهرة-أحمد-نعينع.mp3',
    ),
  ];

  /// Get adhan sound path for a specific prayer
  static String? getSoundPath(String? customPath) {
    return customPath;
  }

  /// Check if a sound is the default sound
  static bool isDefaultSound(String? path) {
    return path == null;
  }
}

/// Model for an adhan sound option
class AdhanSoundOption {
  final String name;
  final String nameEn;
  final String? path;

  const AdhanSoundOption({
    required this.name,
    required this.nameEn,
    required this.path,
  });

  bool get isDefault => path == null;
}
