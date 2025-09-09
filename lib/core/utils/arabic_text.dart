import 'package:flutter/material.dart';

/// Utility class for Arabic text translations and formatting
class ArabicText {
  // Prayer names
  static const Map<String, String> prayerNames = {
    'fajr': 'الفجر',
    'sunrise': 'الشروق',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  // Settings related translations
  static const Map<String, String> settings = {
    'settings': 'الإعدادات',
    'calculation_method': 'طريقة الحساب',
    'madhab': 'المذهب',
    'location': 'الموقع',
    'update_location': 'تحديث الموقع',
    'close': 'إغلاق',
    'save': 'حفظ',
    'cancel': 'إلغاء',
  };

  // Calculation methods in Arabic
  static const Map<String, String> calculationMethods = {
    'muslim_world_league': 'رابطة العالم الإسلامي',
    'egyptian': 'الهيئة المصرية العامة للمساحة',
    'karachi': 'جامعة العلوم الإسلامية، كراتشي',
    'umm_al_qura': 'أم القرى، مكة المكرمة',
    'dubai': 'الإمارات العربية المتحدة',
    'qatar': 'قطر',
    'kuwait': 'الكويت',
    'singapore': 'سنغافورة',
    'north_america': 'أمريكا الشمالية',
  };

  // Madhab options in Arabic
  static const Map<String, String> madhabOptions = {
    'shafi': 'الشافعي',
    'hanafi': 'الحنفي',
  };

  // Time-related translations
  static const Map<String, String> timeRelated = {
    'hours': 'ساعات',
    'minutes': 'دقائق',
    'seconds': 'ثواني',
    'hour': 'ساعة',
    'minute': 'دقيقة',
    'second': 'ثانية',
    'until': 'حتى',
    'next_prayer': 'الصلاة القادمة',
    'now': 'الآن',
  };

  // Day names in Arabic
  static const List<String> weekDays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  // Month names in Arabic
  static const List<String> months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  // Hijri month names
  static const List<String> hijriMonths = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  // Helper function to format date in Arabic
  static String formatDate(DateTime date) {
    return '${weekDays[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Helper method to get styled Arabic text
  static Widget styledText(
    String text, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Amiri',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
    );
  }
}
