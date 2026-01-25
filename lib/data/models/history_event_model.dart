class HistoryEvent {
  final int id;
  final String title;
  final String text;
  final String hijriYear;
  final String lunarMonth;
  final String gregorianYear;

  HistoryEvent({
    required this.id,
    required this.title,
    required this.text,
    required this.hijriYear,
    required this.lunarMonth,
    required this.gregorianYear,
  });

  factory HistoryEvent.fromJson(Map<String, dynamic> json) {
    final dateList = json['date'] as List?;
    final dateLength = dateList?.length ?? 0;

    String hijriYear = '';
    String lunarMonth = '';
    String gregorianYear = '';

    if (dateLength >= 2) {
      hijriYear = dateList![0].toString();
      // Check if middle element is lunar month or gregorian year
      final secondElement = dateList[1].toString();
      if (secondElement.contains('الشهر القمري')) {
        lunarMonth = secondElement;
        if (dateLength >= 3) {
          gregorianYear = dateList[2].toString();
        }
      } else {
        gregorianYear = secondElement;
      }
    } else if (dateLength == 1) {
      hijriYear = dateList![0].toString();
    }

    return HistoryEvent(
      id: json['id'],
      title: json['title'],
      text: json['text'],
      hijriYear: hijriYear,
      lunarMonth: lunarMonth,
      gregorianYear: gregorianYear,
    );
  }

  bool matchesSearchQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
        text.toLowerCase().contains(lowerQuery) ||
        hijriYear.toLowerCase().contains(lowerQuery) ||
        lunarMonth.toLowerCase().contains(lowerQuery) ||
        gregorianYear.toLowerCase().contains(lowerQuery);
  }
}
