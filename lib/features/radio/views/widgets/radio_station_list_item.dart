import 'package:flutter/material.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/data/models/radio_station_model.dart';

class RadioStationListItem extends StatelessWidget {
  final RadioStationModel station;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const RadioStationListItem({
    super.key,
    required this.station,
    required this.onTap,
    this.isActive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final iconData = _selectIconForStation(station);

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                    theme.colorScheme.secondary.withValues(alpha: 0.15),
                  ],
                )
              : null,
          color: isActive ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(PlatformUtils.isDesktop
              ? size.width * 0.015
              : size.width * 0.028),
          child: Row(
            children: [
              Container(
                width: PlatformUtils.isDesktop
                    ? size.width * 0.05
                    : size.width * 0.12,
                height: PlatformUtils.isDesktop
                    ? size.width * 0.05
                    : size.width * 0.12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconData,
                  color: theme.colorScheme.primary,
                  size: PlatformUtils.isDesktop
                      ? size.width * 0.02
                      : size.width * 0.06,
                ),
              ),
              SizedBox(
                  width: PlatformUtils.isDesktop ? 12.0 : size.width * 0.03),
              Expanded(
                child: Text(
                  station.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize:
                        PlatformUtils.isDesktop ? 14.0 : size.width * 0.038,
                    color: isLoading ? Colors.grey : null,
                  ),
                ),
              ),
              SizedBox(
                  width: PlatformUtils.isDesktop
                      ? size.width * 0.015
                      : size.width * 0.015),
              Container(
                width: PlatformUtils.isDesktop
                    ? size.width * 0.05
                    : size.width * 0.08,
                height: PlatformUtils.isDesktop
                    ? size.width * 0.05
                    : size.width * 0.08,
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? Padding(
                        padding: EdgeInsets.all(PlatformUtils.isDesktop
                            ? size.width * 0.01
                            : size.width * 0.02),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isActive ? Colors.white : theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        isActive
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color:
                            isActive ? Colors.white : theme.colorScheme.primary,
                        size: PlatformUtils.isDesktop
                            ? size.width * 0.03
                            : size.width * 0.05,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _selectIconForStation(RadioStationModel s) {
  final name = s.name;
  final url = s.url;

  // Keep logic aligned with filters in radio_screen.dart
  if (_isRuqiah(name, url)) {
    return Icons.health_and_safety_rounded; // الرقية الشرعية
  }
  if (_isFatwa(name, url)) return Icons.record_voice_over_rounded; // الفتاوى
  if (_isAdhkar(name, url)) {
    return Icons.self_improvement_rounded; // الأدعية والأذكار
  }
  if (_isQiraat(url)) return Icons.library_music_rounded; // القراءات العشر
  if (_isTafsir(name)) return Icons.menu_book_rounded; // التفسير
  if (_isTranslations(name)) return Icons.translate_rounded; // الترجمات
  if (_isSeerah(name)) return Icons.history_edu_rounded; // السيرة والقصص
  if (_isSeasons(name, url)) return Icons.event_rounded; // مواسم الخير
  if (_isFeatured(name)) return Icons.star_rounded; // تلاوات مميزة

  // Readers fall back and default
  return Icons.radio_rounded;
}

bool _isRuqiah(String n, String u) {
  return n.contains('الرقية') ||
      n.contains('السكينة') ||
      u.contains('roqiah') ||
      u.contains('sakeenah');
}

bool _isFatwa(String n, String u) {
  return n.contains('الفتاوى') ||
      n.contains('الاختيارات الفقهية') ||
      u.contains('fatwa') ||
      u.contains('alaikhtiarat_alfiqhayh_bin_baz');
}

bool _isAdhkar(String n, String u) {
  return n.contains('أذكار الصباح') ||
      n.contains('أذكار المساء') ||
      n.contains('تكبيرات العيد') ||
      u.contains('athkar_sabah') ||
      u.contains('athkar_masa') ||
      u.contains('eid');
}

bool _isQiraat(String u) {
  const qiraatUrls = {
    'ahmed_altrabulsi',
    'ibrahim_aldosari',
    'addokali_mohammad_alalim',
    'aloyoon_alkoshi',
    'alfateh_alzubair',
    'alqaria_yassen',
    'tareq_abdulgani_daawob',
    'abdulbasit_abdulsamad_warsh',
    'abdulrasheed_soufi_assosi',
    'abdulrasheed_soufi_khalaf',
    'omar_alqazabri',
    'mohammad_alabdullah_albizi',
    'mohammad_alabdullah_aldorai',
    'mohammad_abdullkarem_alasbahani',
    'mahmood_alsheimy',
    'mahmoud_khalil_alhussary_warsh',
    'muftah_alsaltany_ibn_thakwan_an_ibn_amr',
    'muftah_alsaltany_aldori_an_abi_amr',
    'muftah_alsaltany_aldorai',
    'waleed_alnaehi',
    'yasser_almazroyee',
  };
  return qiraatUrls.any((p) => u.contains(p));
}

bool _isTafsir(String n) => n.contains('تفسير');

bool _isTranslations(String n) => n.contains('ترجمة معاني القرآن');

bool _isSeerah(String n) => n.contains('السيرة') || n.contains('الصحابة');

bool _isSeasons(String n, String u) {
  return n.contains('رمضان') ||
      n.contains('ستة من شوال') ||
      n.contains('عشر ذي الحجة') ||
      n.contains('عاشوراء') ||
      u.contains('ramadan');
}

bool _isFeatured(String n) {
  return n.contains('تراتيل') ||
      n.contains('الإذاعة العامة') ||
      n.contains('تلاوات') ||
      n.contains('سورة');
}
