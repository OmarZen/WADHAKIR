import 'package:flutter/foundation.dart';

/// A short, ready-made Arabic phrase the user can drop onto a background.
@immutable
class BackgroundQuote {
  final String text;
  final String? reference;

  const BackgroundQuote(this.text, [this.reference]);
}

/// Curated short Quran ayat + adhkar that read beautifully on a wallpaper.
/// Kept short on purpose so they fit a 9:16 canvas without shrinking.
class CuratedQuotes {
  const CuratedQuotes._();

  static const List<BackgroundQuote> all = [
    BackgroundQuote(
      'وَذَكِّرْ فَإِنَّ ٱلذِّكْرَىٰ تَنفَعُ ٱلْمُؤْمِنِينَ',
      'الذاريات ٥٥',
    ),
    BackgroundQuote('فَٱذْكُرُونِىٓ أَذْكُرْكُمْ', 'البقرة ١٥٢'),
    BackgroundQuote(
      'أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ',
      'الرعد ٢٨',
    ),
    BackgroundQuote('إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا', 'الشرح ٦'),
    BackgroundQuote('وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ', 'الحديد ٤'),
    BackgroundQuote('حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ', 'آل عمران ١٧٣'),
    BackgroundQuote('رَّبِّ ٱشْرَحْ لِى صَدْرِى', 'طه ٢٥'),
    BackgroundQuote('وَقُل رَّبِّ زِدْنِى عِلْمًا', 'طه ١١٤'),
    BackgroundQuote(
      'لَّآ إِلَٰهَ إِلَّآ أَنتَ سُبْحَٰنَكَ إِنِّى كُنتُ مِنَ ٱلظَّٰلِمِينَ',
      'الأنبياء ٨٧',
    ),
    BackgroundQuote('وَٱصْبِرْ وَمَا صَبْرُكَ إِلَّا بِٱللَّهِ', 'النحل ١٢٧'),
    BackgroundQuote('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', 'حديث شريف'),
    BackgroundQuote('لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', 'حديث شريف'),
    BackgroundQuote(
      'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَىٰ نَبِيِّنَا مُحَمَّد',
      'صلاة على النبي',
    ),
    BackgroundQuote('قليلٌ مستمرٌّ خيرٌ من كثيرٍ منقطع', 'أثر'),
  ];
}
