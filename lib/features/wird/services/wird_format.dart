/// Arabic formatting helpers for the wird feature.
///
/// The app does not initialize `intl` locale date data, so we format Arabic
/// dates with explicit month/weekday maps instead of `DateFormat('…','ar')`
/// (which would throw without `initializeDateFormatting`). Digits are
/// converted to Arabic-Indic to match the reference screenshots.
class WirdFormat {
  const WirdFormat._();

  static const List<String> _arabicMonths = [
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

  // DateTime.weekday: 1 = Monday … 7 = Sunday.
  static const List<String> _arabicWeekdays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const List<String> _arabicIndicDigits = [
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];

  /// Convert all Western digits in [input] to Arabic-Indic digits.
  static String toArabicDigits(Object input) {
    final s = input.toString();
    final buffer = StringBuffer();
    for (final code in s.runes) {
      if (code >= 0x30 && code <= 0x39) {
        buffer.write(_arabicIndicDigits[code - 0x30]);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// "الجمعة، ٢٩ مايو" — weekday, day and Arabic month name.
  static String shortDate(DateTime date) {
    final weekday = _arabicWeekdays[(date.weekday - 1) % 7];
    final month = _arabicMonths[date.month - 1];
    return '$weekday، ${toArabicDigits(date.day)} $month';
  }

  /// "الاثنين، ٢٦ أكتوبر ٢٠٢٦" — weekday, day, month and year.
  static String longDate(DateTime date) {
    final weekday = _arabicWeekdays[(date.weekday - 1) % 7];
    final month = _arabicMonths[date.month - 1];
    return '$weekday، ${toArabicDigits(date.day)} $month ${toArabicDigits(date.year)}';
  }

  /// "٢٦ أكتوبر ٢٠٢٦" — day, month and year (no weekday).
  static String dateWithYear(DateTime date) {
    final month = _arabicMonths[date.month - 1];
    return '${toArabicDigits(date.day)} $month ${toArabicDigits(date.year)}';
  }
}
