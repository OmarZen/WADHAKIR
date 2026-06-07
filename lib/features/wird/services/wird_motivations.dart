/// Islamic motivational lines shown for the wird, bucketed by pace.
///
/// Single source of truth shared by the in-app pace banner and the
/// home-screen widget (pushed to the native side as JSON so it can rotate the
/// line daily). Lines are short so they fit a widget row.
class WirdMotivations {
  const WirdMotivations._();

  /// Shown when the user is behind (متأخر) — gentle encouragement to return.
  static const List<String> behind = [
    'قليل مستمر خير من كثير منقطع',
    'لا تيأس، عُد إلى وردك فالله يحب التوّابين',
    'أحبّ الأعمال إلى الله أدومها وإن قلّ',
    'ما فات يُدرَك، فابدأ الآن ولو بصفحة',
  ];

  /// Shown when on schedule — keep going.
  static const List<String> onTrack = [
    'أحسنت! داوم على وردك',
    'نِعمَ العون على الثبات: الاستمرار',
    'بارك الله في وقتك وعملك',
    'وأن تصوموا خير لكم.. والمداومة خير',
  ];

  /// Shown when ahead of schedule (متقدم) — celebrate the eagerness.
  static const List<String> ahead = [
    'ما شاء الله، أنت سابقٌ إلى الخير',
    'وسارعوا إلى مغفرة من ربكم',
    'زادك الله حرصًا وتوفيقًا',
    'أولئك يسارعون في الخيرات',
  ];

  /// Shown when the ختمة is complete.
  static const List<String> finished = [
    'تقبّل الله ختمتك، وابدأ ختمة جديدة',
    'اللهم اجعله حجةً لنا لا علينا',
    'الحمد لله الذي بنعمته تتمّ الصالحات',
  ];

  /// Buckets keyed by the same strings the native widget expects.
  static Map<String, List<String>> get buckets => {
    'behind': behind,
    'ontrack': onTrack,
    'ahead': ahead,
    'finished': finished,
  };

  /// Default line for the in-app banner (rotates daily within a bucket).
  static String pick(List<String> bucket, [DateTime? now]) {
    if (bucket.isEmpty) return '';
    final d = now ?? DateTime.now();
    final dayOfYear = d.difference(DateTime(d.year)).inDays;
    return bucket[dayOfYear % bucket.length];
  }
}
