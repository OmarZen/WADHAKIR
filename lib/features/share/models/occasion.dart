import 'package:syncfusion_flutter_core/core.dart';

/// A day worth sending someone a card for — roadmap #23.
///
/// ## Why this feature exists at all
///
/// Every Friday, people forward a twelve-year-old JPEG with broken gold
/// ornaments and no source, because nothing better exists. The gap is not
/// technical: the renderer has been in this app since before R4. What is
/// missing is *a sourced dua on a calm background*, ready on the day.
///
/// **Friday is the only one of these that recurs weekly.** Everything else is
/// annual, which means this feature earns its keep fifty-two times a year and
/// the rest is a bonus.
///
/// ## The content rule
///
/// Every dua here is authentic and attributed, and the attribution ships on the
/// card. An unsourced dua forwarded at scale is how fabrications enter
/// circulation — which is exactly what the twelve-year-old JPEG is doing — and
/// an app that does it with better typography has made the problem worse, not
/// better. Nothing goes in this list without a named narration.
enum Occasion {
  /// Weekly. The one that matters most.
  friday(
    'friday',
    'جمعة مباركة',
    'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    'ﷺ «أَكْثِرُوا الصَّلَاةَ عَلَيَّ يَوْمَ الْجُمُعَةِ» — رواه أبو داود',
  ),

  /// 1 Ramadan. The whole month would be noise; the card marks its arrival.
  ramadan(
    'ramadan',
    'رمضان مبارك',
    'اللَّهُمَّ أَهِلَّهُ عَلَيْنَا بِالْيُمْنِ وَالْإِيمَانِ، وَالسَّلَامَةِ وَالْإِسْلَامِ',
    'رواه الترمذي، وقال: حديث حسن',
  ),

  /// 27 Ramadan — the most widely observed of the odd nights.
  laylatAlQadr(
    'laylat_al_qadr',
    'ليلة القدر',
    'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
    'عن عائشة رضي الله عنها — رواه الترمذي وابن ماجه',
  ),

  /// 1 Shawwal.
  eidAlFitr(
    'eid_al_fitr',
    'عيد فطر مبارك',
    'تَقَبَّلَ اللَّهُ مِنَّا وَمِنْكُمْ',
    'أثر عن الصحابة رضي الله عنهم — رواه ابن حجر في «الأمالي» بإسناد حسن',
  ),

  /// 9 Dhul-Hijjah.
  arafah(
    'arafah',
    'يوم عرفة',
    'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    'ﷺ «خَيْرُ الدُّعَاءِ دُعَاءُ يَوْمِ عَرَفَةَ» — رواه الترمذي',
  ),

  /// 10 Dhul-Hijjah.
  eidAlAdha(
    'eid_al_adha',
    'عيد أضحى مبارك',
    'تَقَبَّلَ اللَّهُ مِنَّا وَمِنْكُمْ',
    'أثر عن الصحابة رضي الله عنهم — رواه ابن حجر في «الأمالي» بإسناد حسن',
  ),

  /// 10 Muharram.
  ashura(
    'ashura',
    'يوم عاشوراء',
    'صِيَامُ يَوْمِ عَاشُورَاءَ أَحْتَسِبُ عَلَى اللَّهِ أَنْ يُكَفِّرَ السَّنَةَ الَّتِي قَبْلَهُ',
    'ﷺ — رواه مسلم',
  );

  const Occasion(this.id, this.greeting, this.dua, this.attribution);

  /// Stable id, for localisation keys and for anything stored.
  final String id;

  /// «جمعة مباركة» — the headline of the card.
  final String greeting;

  /// The dua itself.
  final String dua;

  /// Where the dua comes from. **Never optional**, and it ships on the card.
  final String attribution;

  /// Whether this comes round every week rather than every year.
  bool get isWeekly => this == Occasion.friday;
}

/// Decides which occasion, if any, today is.
///
/// Pure, and takes both calendars rather than reading a clock: the Hijri date
/// is what every rule but Friday turns on, and a function that fetched its own
/// `now` could only be tested by waiting for Ramadan.
class OccasionCalendar {
  const OccasionCalendar._();

  /// Hijri month numbers, named so the rules below read as rules.
  static const int _muharram = 1;
  static const int _ramadan = 9;
  static const int _shawwal = 10;
  static const int _dhulHijjah = 12;

  /// The occasion for [gregorian] / [hijri], or null on an ordinary day.
  ///
  /// An annual occasion outranks Friday. Eid falling on a Friday is Eid — a
  /// «جمعة مباركة» card that day would be the app failing to notice the more
  /// significant of the two things happening.
  static Occasion? forDate({
    required DateTime gregorian,
    required HijriDateTime hijri,
  }) {
    final annual = _annualFor(hijri);
    if (annual != null) return annual;
    if (gregorian.weekday == DateTime.friday) return Occasion.friday;
    return null;
  }

  static Occasion? _annualFor(HijriDateTime hijri) {
    return switch ((hijri.month, hijri.day)) {
      (_muharram, 10) => Occasion.ashura,
      (_ramadan, 1) => Occasion.ramadan,
      (_ramadan, 27) => Occasion.laylatAlQadr,
      (_shawwal, 1) => Occasion.eidAlFitr,
      (_dhulHijjah, 9) => Occasion.arafah,
      (_dhulHijjah, 10) => Occasion.eidAlAdha,
      _ => null,
    };
  }
}
