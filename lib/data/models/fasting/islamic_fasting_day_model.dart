import 'package:equatable/equatable.dart';

/// Enum for different types of Islamic fasting days
enum FastingDayType {
  /// Ayyam al-Bid: 13th, 14th, 15th of each month
  ayyamAlBid,

  /// 9th and 10th of each month (following the Sunnah pattern)
  ninthTenth,

  /// Special days like Ashura, Arafah, etc.
  special,

  /// Weekly fasting (Monday and Thursday)
  weeklyFasting,
}

/// Model representing an Islamic fasting day
/// Contains information about voluntary (Nafl) fasting days
class IslamicFastingDay extends Equatable {
  /// Arabic name of the fasting day
  final String nameAr;

  /// English name of the fasting day
  final String nameEn;

  /// Arabic description of the fasting day
  final String descriptionAr;

  /// English description of the fasting day
  final String descriptionEn;

  /// Hijri month (1-12), null if it recurs monthly
  final int? hijriMonth;

  /// Day of the Hijri month (1-30)
  final int hijriDay;

  /// Whether this day repeats every month
  final bool isMonthlyRecurring;

  /// Whether this is a special day (Ashura, Arafah, etc.)
  final bool isSpecialDay;

  /// List of virtues in Arabic
  final List<String> virtuesAr;

  /// List of virtues in English
  final List<String> virtuesEn;

  /// Reward level (1-5 stars) indicating the significance
  final int rewardLevel;

  /// Type of fasting day
  final FastingDayType type;

  /// Get localized virtues based on language code
  List<String> getVirtues(String languageCode) {
    return languageCode == 'ar' ? virtuesAr : virtuesEn;
  }

  const IslamicFastingDay({
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    this.hijriMonth,
    required this.hijriDay,
    required this.isMonthlyRecurring,
    required this.isSpecialDay,
    required this.virtuesAr,
    required this.virtuesEn,
    required this.rewardLevel,
    required this.type,
  });

  /// Factory constructor for Ayyam al-Bid (13th of the month)
  factory IslamicFastingDay.ayyamAlBid13() {
    return const IslamicFastingDay(
      nameAr: 'اليوم الأول من الأيام البيض',
      nameEn: 'First White Day',
      descriptionAr: 'اليوم الثالث عشر من الشهر الهجري',
      descriptionEn: '13th day of the Hijri month',
      hijriMonth: null,
      hijriDay: 13,
      isMonthlyRecurring: true,
      isSpecialDay: false,
      virtuesAr: [
        'صيام الأيام البيض من السنن المستحبة',
        'حث النبي صلى الله عليه وسلم على صيامها',
      ],
      virtuesEn: [
        'Fasting the White Days is a recommended Sunnah',
        'The Prophet ﷺ encouraged fasting these days',
      ],
      rewardLevel: 4,
      type: FastingDayType.ayyamAlBid,
    );
  }

  /// Factory constructor for Ayyam al-Bid (14th of the month)
  factory IslamicFastingDay.ayyamAlBid14() {
    return const IslamicFastingDay(
      nameAr: 'اليوم الثاني من الأيام البيض',
      nameEn: 'Second White Day',
      descriptionAr: 'اليوم الرابع عشر من الشهر الهجري',
      descriptionEn: '14th day of the Hijri month',
      hijriMonth: null,
      hijriDay: 14,
      isMonthlyRecurring: true,
      isSpecialDay: false,
      virtuesAr: [
        'صيام الأيام البيض من السنن المستحبة',
        'حث النبي صلى الله عليه وسلم على صيامها',
      ],
      virtuesEn: [
        'Fasting the White Days is a recommended Sunnah',
        'The Prophet ﷺ encouraged fasting these days',
      ],
      rewardLevel: 4,
      type: FastingDayType.ayyamAlBid,
    );
  }

  /// Factory constructor for Ayyam al-Bid (15th of the month)
  factory IslamicFastingDay.ayyamAlBid15() {
    return const IslamicFastingDay(
      nameAr: 'اليوم الثالث من الأيام البيض',
      nameEn: 'Third White Day',
      descriptionAr: 'اليوم الخامس عشر من الشهر الهجري',
      descriptionEn: '15th day of the Hijri month',
      hijriMonth: null,
      hijriDay: 15,
      isMonthlyRecurring: true,
      isSpecialDay: false,
      virtuesAr: [
        'صيام الأيام البيض من السنن المستحبة',
        'حث النبي صلى الله عليه وسلم على صيامها',
      ],
      virtuesEn: [
        'Fasting the White Days is a recommended Sunnah',
        'The Prophet ﷺ encouraged fasting these days',
      ],
      rewardLevel: 4,
      type: FastingDayType.ayyamAlBid,
    );
  }

  /// Factory constructor for 9th of the month
  factory IslamicFastingDay.ninthOfMonth() {
    return const IslamicFastingDay(
      nameAr: 'اليوم التاسع من الشهر',
      nameEn: '9th of the Month',
      descriptionAr: 'اليوم التاسع من الشهر الهجري',
      descriptionEn: '9th day of the Hijri month',
      hijriMonth: null,
      hijriDay: 9,
      isMonthlyRecurring: true,
      isSpecialDay: false,
      virtuesAr: [
        'صيام التاسع والعاشر من كل شهر من السنن المستحبة',
      ],
      virtuesEn: [
        'Fasting the 9th and 10th of every month is a recommended Sunnah',
      ],
      rewardLevel: 3,
      type: FastingDayType.ninthTenth,
    );
  }

  /// Factory constructor for 10th of the month
  factory IslamicFastingDay.tenthOfMonth() {
    return const IslamicFastingDay(
      nameAr: 'اليوم العاشر من الشهر',
      nameEn: '10th of the Month',
      descriptionAr: 'اليوم العاشر من الشهر الهجري',
      descriptionEn: '10th day of the Hijri month',
      hijriMonth: null,
      hijriDay: 10,
      isMonthlyRecurring: true,
      isSpecialDay: false,
      virtuesAr: [
        'صيام التاسع والعاشر من كل شهر من السنن المستحبة',
      ],
      virtuesEn: [
        'Fasting the 9th and 10th of every month is a recommended Sunnah',
      ],
      rewardLevel: 3,
      type: FastingDayType.ninthTenth,
    );
  }

  /// Factory constructor for Tasu'a (9th of Muharram)
  factory IslamicFastingDay.tasua() {
    return const IslamicFastingDay(
      nameAr: 'تاسوعاء',
      nameEn: "Tasu'a",
      descriptionAr: 'اليوم التاسع من شهر محرم',
      descriptionEn: '9th day of Muharram',
      hijriMonth: 1,
      hijriDay: 9,
      isMonthlyRecurring: false,
      isSpecialDay: true,
      virtuesAr: [
        'حرص النبي صلى الله عليه وسلم على صيامه',
        'قال صلى الله عليه وسلم: لئن بقيت إلى قابل لأصومن التاسع',
      ],
      virtuesEn: [
        'The Prophet ﷺ was keen to fast it',
        'He ﷺ said: If I live until next year, I will fast the ninth',
      ],
      rewardLevel: 5,
      type: FastingDayType.special,
    );
  }

  /// Factory constructor for Ashura (10th of Muharram)
  factory IslamicFastingDay.ashura() {
    return const IslamicFastingDay(
      nameAr: 'عاشوراء',
      nameEn: 'Ashura',
      descriptionAr: 'اليوم العاشر من شهر محرم',
      descriptionEn: '10th day of Muharram',
      hijriMonth: 1,
      hijriDay: 10,
      isMonthlyRecurring: false,
      isSpecialDay: true,
      virtuesAr: [
        'صيام يوم عاشوراء يكفر السنة الماضية',
        'كان النبي صلى الله عليه وسلم يحرص على صيامه',
        'أخرج مسلم: صيام يوم عاشوراء أحتسب على الله أن يكفر السنة التي قبله',
      ],
      virtuesEn: [
        'Fasting Ashura expiates the past year',
        'The Prophet ﷺ was keen to fast it',
        'Muslim narrated: Fasting Ashura, I hope Allah will expiate the year before it',
      ],
      rewardLevel: 5,
      type: FastingDayType.special,
    );
  }

  /// Factory constructor for Day of Arafah (9th of Dhul Hijjah)
  factory IslamicFastingDay.arafah() {
    return const IslamicFastingDay(
      nameAr: 'يوم عرفة',
      nameEn: 'Day of Arafah',
      descriptionAr: 'اليوم التاسع من شهر ذي الحجة',
      descriptionEn: '9th day of Dhul Hijjah',
      hijriMonth: 12,
      hijriDay: 9,
      isMonthlyRecurring: false,
      isSpecialDay: true,
      virtuesAr: [
        'صيام يوم عرفة يكفر السنة الماضية والقادمة',
        'قال صلى الله عليه وسلم: صيام يوم عرفة أحتسب على الله أن يكفر السنة التي قبله والسنة التي بعده',
        'من أفضل أيام السنة',
      ],
      virtuesEn: [
        'Fasting Arafah expiates the past and coming year',
        'He ﷺ said: Fasting Arafah, I hope Allah will expiate the year before and after it',
        'One of the best days of the year',
      ],
      rewardLevel: 5,
      type: FastingDayType.special,
    );
  }

  /// Factory constructor for Monday fasting
  factory IslamicFastingDay.mondayFasting() {
    return const IslamicFastingDay(
      nameAr: 'صيام يوم الاثنين',
      nameEn: 'Monday Fasting',
      descriptionAr: 'صيام يوم الاثنين من كل أسبوع',
      descriptionEn: 'Fasting every Monday',
      hijriMonth: null,
      hijriDay: 1, // Monday (weekday marker)
      isMonthlyRecurring: false,
      isSpecialDay: false,
      virtuesAr: [
        'كان النبي صلى الله عليه وسلم يصوم الاثنين والخميس',
        'ذلك يوم ولدت فيه، ويوم بعثت فيه',
        'تعرض فيه الأعمال على الله',
      ],
      virtuesEn: [
        'The Prophet ﷺ used to fast Mondays and Thursdays',
        'That is the day I was born and the day I was sent as a prophet',
        'Deeds are presented to Allah on this day',
      ],
      rewardLevel: 4,
      type: FastingDayType.weeklyFasting,
    );
  }

  /// Factory constructor for Thursday fasting
  factory IslamicFastingDay.thursdayFasting() {
    return const IslamicFastingDay(
      nameAr: 'صيام يوم الخميس',
      nameEn: 'Thursday Fasting',
      descriptionAr: 'صيام يوم الخميس من كل أسبوع',
      descriptionEn: 'Fasting every Thursday',
      hijriMonth: null,
      hijriDay: 4, // Thursday (weekday marker)
      isMonthlyRecurring: false,
      isSpecialDay: false,
      virtuesAr: [
        'كان النبي صلى الله عليه وسلم يصوم الاثنين والخميس',
        'تعرض فيه الأعمال على الله',
        'من السنن النبوية المستحبة',
      ],
      virtuesEn: [
        'The Prophet ﷺ used to fast Mondays and Thursdays',
        'Deeds are presented to Allah on this day',
        'A recommended prophetic tradition',
      ],
      rewardLevel: 4,
      type: FastingDayType.weeklyFasting,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'hijriMonth': hijriMonth,
      'hijriDay': hijriDay,
      'isMonthlyRecurring': isMonthlyRecurring,
      'isSpecialDay': isSpecialDay,
      'virtuesAr': virtuesAr,
      'virtuesEn': virtuesEn,
      'rewardLevel': rewardLevel,
      'type': type.index,
    };
  }

  /// Create from JSON
  factory IslamicFastingDay.fromJson(Map<String, dynamic> json) {
    return IslamicFastingDay(
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      descriptionAr: json['descriptionAr'] as String,
      descriptionEn: json['descriptionEn'] as String,
      hijriMonth: json['hijriMonth'] as int?,
      hijriDay: json['hijriDay'] as int,
      isMonthlyRecurring: json['isMonthlyRecurring'] as bool,
      isSpecialDay: json['isSpecialDay'] as bool,
      virtuesAr: (json['virtuesAr'] as List<dynamic>).cast<String>(),
      virtuesEn: (json['virtuesEn'] as List<dynamic>).cast<String>(),
      rewardLevel: json['rewardLevel'] as int,
      type: FastingDayType.values[json['type'] as int],
    );
  }

  @override
  List<Object?> get props => [
        nameAr,
        nameEn,
        descriptionAr,
        descriptionEn,
        hijriMonth,
        hijriDay,
        isMonthlyRecurring,
        isSpecialDay,
        virtuesAr,
        virtuesEn,
        rewardLevel,
        type,
      ];

  @override
  String toString() {
    return 'IslamicFastingDay(nameEn: $nameEn, day: $hijriDay, '
        'month: $hijriMonth, type: $type)';
  }
}
