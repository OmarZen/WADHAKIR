import 'package:hijri/hijri_calendar.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class AppDateUtils {
  static String getFormattedHijriDate(
      HijriCalendar date, AppLocalizations? l10n) {
    String month = _getHijriMonthName(date.hMonth, l10n);
    return '${date.hDay} $month ${date.hYear}';
  }

  static String getShortFormattedHijriDate(
      HijriCalendar date, AppLocalizations? l10n) {
    String month = _getShortHijriMonthName(date.hMonth, l10n);
    return '${date.hDay} $month';
  }

  static String _getHijriMonthName(int month, AppLocalizations? l10n) {
    List<String> monthsArabic = [
      l10n?.translate('global.moharom') ?? 'محرم',
      l10n?.translate('global.safar') ?? 'صفر',
      l10n?.translate('global.rabi_al_awwal') ?? 'ربيع الأول',
      l10n?.translate('global.rabi_al_thani') ?? 'ربيع الثاني',
      l10n?.translate('global.jamada_al_awwal') ?? 'جمادى الأولى',
      l10n?.translate('global.jamada_al_thani') ?? 'جمادى الآخرة',
      l10n?.translate('global.rajab') ?? 'رجب',
      l10n?.translate('global.shaban') ?? 'شعبان',
      l10n?.translate('global.ramadan') ?? 'رمضان',
      l10n?.translate('global.shawwal') ?? 'شوال',
      l10n?.translate('global.dhul_kadah') ?? 'ذو القعدة',
      l10n?.translate('global.dhul_hijjah') ?? 'ذو الحجة',
    ];

    return monthsArabic[month - 1];
  }

  static String _getShortHijriMonthName(int month, AppLocalizations? l10n) {
    List<String> monthsArabic = [
      l10n?.translate('global.moharom') ?? 'محرم',
      l10n?.translate('global.safar') ?? 'صفر',
      l10n?.translate('global.rabi_al_awwal') ?? 'ربيع الأول',
      l10n?.translate('global.rabi_al_thani') ?? 'ربيع الثاني',
      l10n?.translate('global.jamada_al_awwal') ?? 'جمادى الأولى',
      l10n?.translate('global.jamada_al_thani') ?? 'جمادى الآخرة',
      l10n?.translate('global.rajab') ?? 'رجب',
      l10n?.translate('global.shaban') ?? 'شعبان',
      l10n?.translate('global.ramadan') ?? 'رمضان',
      l10n?.translate('global.shawwal') ?? 'شوال',
      l10n?.translate('global.dhul_kadah') ?? 'ذو القعدة',
      l10n?.translate('global.dhul_hijjah') ?? 'ذو الحجة',
    ];

    return monthsArabic[month - 1];
  }

  static String getGregorianMonthName(int month, AppLocalizations? l10n) {
    final months = [
      l10n?.translate('global.jan') ?? 'يناير',
      l10n?.translate('global.feb') ?? 'فبراير',
      l10n?.translate('global.mar') ?? 'مارس',
      l10n?.translate('global.apr') ?? 'أبريل',
      l10n?.translate('global.may') ?? 'مايو',
      l10n?.translate('global.jun') ?? 'يونيو',
      l10n?.translate('global.jul') ?? 'يوليو',
      l10n?.translate('global.aug') ?? 'أغسطس',
      l10n?.translate('global.sep') ?? 'سبتمبر',
      l10n?.translate('global.oct') ?? 'أكتوبر',
      l10n?.translate('global.nov') ?? 'نوفمبر',
      l10n?.translate('global.dec') ?? 'ديسمبر',
    ];

    return months[month - 1];
  }
}
