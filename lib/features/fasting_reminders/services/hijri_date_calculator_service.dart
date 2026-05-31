import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/data/models/fasting/islamic_fasting_day_model.dart';

/// Service for calculating Hijri dates and fasting days
class HijriDateCalculatorService {
  /// Get current Hijri date
  HijriDateTime getCurrentHijriDate() {
    return HijriDateTime.now();
  }

  /// Get upcoming fasting days for current and next month
  List<IslamicFastingDay> getUpcomingFastingDaysForMonth({
    required bool ayyamAlBidEnabled,
    required bool ninthTenthEnabled,
    required bool specialDaysEmphasis,
  }) {
    final now = HijriDateTime.now();
    final currentDay = now.day;
    final currentMonth = now.month;

    final List<IslamicFastingDay> upcomingDays = [];

    // ===== CURRENT MONTH - Add only days that haven't passed =====

    // Add Ayyam al-Bid (13, 14, 15) if enabled and upcoming
    if (ayyamAlBidEnabled) {
      if (currentDay <= 13) {
        upcomingDays.add(IslamicFastingDay.ayyamAlBid13());
      }
      if (currentDay <= 14) {
        upcomingDays.add(IslamicFastingDay.ayyamAlBid14());
      }
      if (currentDay <= 15) {
        upcomingDays.add(IslamicFastingDay.ayyamAlBid15());
      }
    }

    // Add 9th and 10th if enabled and upcoming
    if (ninthTenthEnabled) {
      if (currentDay <= 9) {
        upcomingDays.add(IslamicFastingDay.ninthOfMonth());
      }
      if (currentDay <= 10) {
        upcomingDays.add(IslamicFastingDay.tenthOfMonth());
      }
    }

    // Add special days if enabled for current month
    if (specialDaysEmphasis) {
      // Check if we're in Muharram (month 1)
      if (currentMonth == 1) {
        if (currentDay <= 9) {
          upcomingDays.add(IslamicFastingDay.tasua());
        }
        if (currentDay <= 10) {
          upcomingDays.add(IslamicFastingDay.ashura());
        }
      }

      // Check if we're in Dhul Hijjah (month 12)
      if (currentMonth == 12 && currentDay <= 9) {
        upcomingDays.add(IslamicFastingDay.arafah());
      }
    }

    // ===== NEXT MONTH - Always include to ensure widget shows data =====
    // Monthly recurring days will appear in next month
    final nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;

    if (ayyamAlBidEnabled) {
      upcomingDays.add(IslamicFastingDay.ayyamAlBid13());
      upcomingDays.add(IslamicFastingDay.ayyamAlBid14());
      upcomingDays.add(IslamicFastingDay.ayyamAlBid15());
    }

    if (ninthTenthEnabled) {
      upcomingDays.add(IslamicFastingDay.ninthOfMonth());
      upcomingDays.add(IslamicFastingDay.tenthOfMonth());
    }

    // Add special days for next month if applicable
    if (specialDaysEmphasis) {
      // Check if next month is Muharram (month 1)
      if (nextMonth == 1) {
        upcomingDays.add(IslamicFastingDay.tasua());
        upcomingDays.add(IslamicFastingDay.ashura());
      }

      // Check if next month is Dhul Hijjah (month 12)
      if (nextMonth == 12) {
        upcomingDays.add(IslamicFastingDay.arafah());
      }
    }

    // Remove duplicates and sort by day
    final seen = <String>{};
    final uniqueDays = upcomingDays.where((day) {
      final key = '${day.hijriDay}-${day.nameEn}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    uniqueDays.sort((a, b) => a.hijriDay.compareTo(b.hijriDay));

    return uniqueDays;
  }

  /// Get upcoming fasting days for the entire Hijri year
  /// Used for calendar display to show all fasting days throughout the year
  /// Note: Notifications are still scheduled only for 2 months (current + next)
  List<IslamicFastingDay> getUpcomingFastingDaysForYear({
    required bool ayyamAlBidEnabled,
    required bool ninthTenthEnabled,
    required bool specialDaysEmphasis,
    bool mondayFastingEnabled = false,
    bool thursdayFastingEnabled = false,
  }) {
    final now = HijriDateTime.now();
    final currentDay = now.day;
    final currentMonth = now.month;
    final currentYear = now.year;

    final List<IslamicFastingDay> yearDays = [];

    // Loop through all 12 Hijri months starting from current month
    for (int monthOffset = 0; monthOffset < 12; monthOffset++) {
      int targetMonth = currentMonth + monthOffset;
      // ignore: unused_local_variable
      int targetYear =
          currentYear; // For future use if year-specific logic needed

      // Handle year overflow
      if (targetMonth > 12) {
        targetMonth = targetMonth - 12;
        targetYear++;
      }

      // Skip days that have passed in the current month
      final isCurrentMonth = monthOffset == 0;
      final minDay = isCurrentMonth ? currentDay + 1 : 1;

      // Add Ayyam al-Bid (13, 14, 15) if enabled
      if (ayyamAlBidEnabled) {
        if (minDay <= 13) {
          yearDays.add(IslamicFastingDay.ayyamAlBid13());
        }
        if (minDay <= 14) {
          yearDays.add(IslamicFastingDay.ayyamAlBid14());
        }
        if (minDay <= 15) {
          yearDays.add(IslamicFastingDay.ayyamAlBid15());
        }
      }

      // Add 9th and 10th if enabled
      if (ninthTenthEnabled) {
        if (minDay <= 9) {
          yearDays.add(IslamicFastingDay.ninthOfMonth());
        }
        if (minDay <= 10) {
          yearDays.add(IslamicFastingDay.tenthOfMonth());
        }
      }

      // Add special days if enabled
      if (specialDaysEmphasis) {
        // Check if this month is Muharram (month 1)
        if (targetMonth == 1) {
          if (minDay <= 9) {
            yearDays.add(IslamicFastingDay.tasua());
          }
          if (minDay <= 10) {
            yearDays.add(IslamicFastingDay.ashura());
          }
        }

        // Check if this month is Dhul Hijjah (month 12)
        if (targetMonth == 12 && minDay <= 9) {
          yearDays.add(IslamicFastingDay.arafah());
        }
      }
    }

    // Add weekly fasting (Monday/Thursday) if enabled
    if (mondayFastingEnabled) {
      yearDays.add(IslamicFastingDay.mondayFasting());
    }
    if (thursdayFastingEnabled) {
      yearDays.add(IslamicFastingDay.thursdayFasting());
    }

    // Remove duplicates and sort by day
    final seen = <String>{};
    final uniqueDays = yearDays.where((day) {
      final key = '${day.hijriDay}-${day.nameEn}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    uniqueDays.sort((a, b) => a.hijriDay.compareTo(b.hijriDay));

    return uniqueDays;
  }

  /// Get the next fasting day
  IslamicFastingDay? getNextFastingDay({
    required bool ayyamAlBidEnabled,
    required bool ninthTenthEnabled,
    required bool specialDaysEmphasis,
  }) {
    final upcomingDays = getUpcomingFastingDaysForMonth(
      ayyamAlBidEnabled: ayyamAlBidEnabled,
      ninthTenthEnabled: ninthTenthEnabled,
      specialDaysEmphasis: specialDaysEmphasis,
    );

    return upcomingDays.isNotEmpty ? upcomingDays.first : null;
  }

  /// Calculate days until a specific fasting day
  int? getDaysUntilFastingDay(IslamicFastingDay fastingDay) {
    final now = HijriDateTime.now();
    final currentDay = now.day;
    final targetDay = fastingDay.hijriDay;

    if (targetDay > currentDay) {
      return targetDay - currentDay;
    }

    return null; // Day has passed in current month
  }

  /// Get all special days for the year
  List<IslamicFastingDay> getSpecialDaysForYear() {
    return [
      IslamicFastingDay.tasua(),
      IslamicFastingDay.ashura(),
      IslamicFastingDay.arafah(),
    ];
  }

  /// Check if a date is a fasting day
  bool isFastingDay({
    required int hijriDay,
    required int hijriMonth,
    required bool ayyamAlBidEnabled,
    required bool ninthTenthEnabled,
    required bool specialDaysEmphasis,
  }) {
    // Check Ayyam al-Bid
    if (ayyamAlBidEnabled &&
        (hijriDay == 13 || hijriDay == 14 || hijriDay == 15)) {
      return true;
    }

    // Check 9th and 10th
    if (ninthTenthEnabled && (hijriDay == 9 || hijriDay == 10)) {
      return true;
    }

    // Check special days
    if (specialDaysEmphasis) {
      // Tasua and Ashura in Muharram
      if (hijriMonth == 1 && (hijriDay == 9 || hijriDay == 10)) {
        return true;
      }

      // Arafah in Dhul Hijjah
      if (hijriMonth == 12 && hijriDay == 9) {
        return true;
      }
    }

    return false;
  }

  /// Get fasting days for next month (for proactive notifications)
  List<IslamicFastingDay> getNextMonthFastingDays({
    required bool ayyamAlBidEnabled,
    required bool ninthTenthEnabled,
    required bool specialDaysEmphasis,
  }) {
    final now = HijriDateTime.now();
    final nextMonth = now.month == 12 ? 1 : now.month + 1;

    final List<IslamicFastingDay> nextMonthDays = [];

    // Add Ayyam al-Bid if enabled
    if (ayyamAlBidEnabled) {
      nextMonthDays.add(IslamicFastingDay.ayyamAlBid13());
      nextMonthDays.add(IslamicFastingDay.ayyamAlBid14());
      nextMonthDays.add(IslamicFastingDay.ayyamAlBid15());
    }

    // Add 9th and 10th if enabled
    if (ninthTenthEnabled) {
      nextMonthDays.add(IslamicFastingDay.ninthOfMonth());
      nextMonthDays.add(IslamicFastingDay.tenthOfMonth());
    }

    // Add special days if enabled
    if (specialDaysEmphasis) {
      // Check if next month is Muharram (month 1)
      if (nextMonth == 1) {
        nextMonthDays.add(IslamicFastingDay.tasua());
        nextMonthDays.add(IslamicFastingDay.ashura());
      }

      // Check if next month is Dhul Hijjah (month 12)
      if (nextMonth == 12) {
        nextMonthDays.add(IslamicFastingDay.arafah());
      }
    }

    return nextMonthDays;
  }

  /// Get Hijri date for a specific Gregorian date
  HijriDateTime getHijriFromGregorian(DateTime gregorianDate) {
    // Syncfusion's HijriDateTime constructor takes Gregorian date
    // and automatically converts it to Hijri
    // The constructor parameters are: (gregorianYear, gregorianMonth, gregorianDay)
    final hijriDate = HijriDateTime(
      gregorianDate.year,
      gregorianDate.month,
      gregorianDate.day,
    );

    // The HijriDateTime instance now contains the converted Hijri date
    // We can access it via hijriDate.month, hijriDate.day, hijriDate.year
    return hijriDate;
  }

  /// Get Gregorian date for a specific Hijri date
  DateTime getGregorianFromHijri({
    required int year,
    required int month,
    required int day,
  }) {
    final hijriDate = HijriDateTime(year, month, day);
    return hijriDate.toDateTime();
  }

  /// Calculate the number of days in current Hijri month
  int getDaysInCurrentHijriMonth() {
    final now = HijriDateTime.now();
    return _getDaysInHijriMonth(now.year, now.month);
  }

  /// Get days in a specific Hijri month
  int _getDaysInHijriMonth(int year, int month) {
    // Hijri months alternate between 29 and 30 days
    // This is a simplified calculation, actual length can vary
    final List<int> monthLengths = [
      30,
      29,
      30,
      29,
      30,
      29,
      30,
      29,
      30,
      29,
      30,
      29,
    ];

    // Adjust for leap years (adds day to month 12)
    if (month == 12 && _isHijriLeapYear(year)) {
      return 30;
    }

    return monthLengths[month - 1];
  }

  /// Check if a Hijri year is a leap year
  bool _isHijriLeapYear(int year) {
    // 30-year cycle: leap years are 2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29
    final position = year % 30;
    return [2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29].contains(position);
  }
}
