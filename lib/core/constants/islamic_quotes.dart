class IslamicQuote {
  final String text;
  final String source;

  const IslamicQuote({required this.text, required this.source});
}

class IslamicQuotes {
  static List<IslamicQuote> get quotes => const [
    IslamicQuote(
      text:
          "إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى",
      source: "متفق عليه",
    ),
    IslamicQuote(
      text: "من حسن إسلام المرء تركه ما لا يعنيه",
      source: "رواه الترمذي",
    ),
    IslamicQuote(text: "الدال على الخير كفاعله", source: "رواه الترمذي"),
    IslamicQuote(text: "طلب العلم فريضة على كل مسلم", source: "رواه ابن ماجه"),
    IslamicQuote(
      text: "إن الله رفيقٌ يحب الرفق في الأمر كله",
      source: "رواه البخاري ومسلم",
    ),
    IslamicQuote(text: "الكلمة الطيبة صدقة", source: "رواه البخاري ومسلم"),
    IslamicQuote(
      text: "لا يؤمن أحدكم حتى يحب لأخيه ما يحب لنفسه",
      source: "رواه البخاري ومسلم",
    ),
    IslamicQuote(
      text: "المسلم من سلم المسلمون من لسانه ويده",
      source: "رواه البخاري ومسلم",
    ),
    IslamicQuote(
      text: "إن الله لا ينظر إلى صوركم وأموالكم، ولكن ينظر إلى قلوبكم وأعمالكم",
      source: "رواه مسلم",
    ),
    IslamicQuote(text: "خيركم من تعلم القرآن وعلمه", source: "رواه البخاري"),
    IslamicQuote(
      text: "افعل الخير مهما استصغرته فإنك لا تدري أي حسنة تدخلك الجنة",
      source: "حكمة إسلامية",
    ),
    IslamicQuote(
      text: "﴿وَمَنْ يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا﴾",
      source: "سورة الطلاق: 2",
    ),
    IslamicQuote(
      text: "﴿فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ۝ إِنَّ مَعَ الْعُسْرِ يُسْرًا﴾",
      source: "سورة الشرح: 5-6",
    ),
    IslamicQuote(
      text: "﴿وَاذْكُرُوا اللَّهَ كَثِيرًا لَّعَلَّكُمْ تُفْلِحُونَ﴾",
      source: "سورة الجمعة: 10",
    ),
    IslamicQuote(
      text: "﴿وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَى﴾",
      source: "سورة الضحى: 5",
    ),
    IslamicQuote(
      text: "﴿إِنَّ اللَّهَ مَعَ الصَّابِرِينَ﴾",
      source: "سورة البقرة: 153",
    ),
    IslamicQuote(
      text: "﴿وَاللَّهُ يُحِبُّ الصَّابِرِينَ﴾",
      source: "سورة آل عمران: 146",
    ),
    IslamicQuote(
      text: "﴿وَقُل رَّبِّ زِدْنِي عِلْمًا﴾",
      source: "سورة طه: 114",
    ),
    IslamicQuote(
      text: "﴿ادْعُونِي أَسْتَجِبْ لَكُمْ﴾",
      source: "سورة غافر: 60",
    ),
    IslamicQuote(
      text: "﴿وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ﴾",
      source: "سورة الطلاق: 3",
    ),
  ];

  static IslamicQuote getRandomQuote() {
    final random = DateTime.now().millisecond % quotes.length;
    return quotes[random];
  }
}
