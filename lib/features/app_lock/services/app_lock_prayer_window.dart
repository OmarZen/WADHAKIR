import 'package:wadhakir/data/models/prayer_times_model.dart';

class AppLockPrayerWindow {
  final DateTime windowStart;
  final DateTime nextPrayerStart;

  const AppLockPrayerWindow({
    required this.windowStart,
    required this.nextPrayerStart,
  });

  bool get isActive {
    final now = DateTime.now();
    return (now.isAtSameMomentAs(windowStart) || now.isAfter(windowStart)) &&
        now.isBefore(nextPrayerStart);
  }

  static AppLockPrayerWindow? fromPrayerTimes(
    PrayerTimesModel model,
    DateTime now,
  ) {
    final prayers = <DateTime>[
      model.fajr,
      model.dhuhr,
      model.asr,
      model.maghrib,
      model.isha,
    ];

    final nextPrayer = prayers.firstWhere(
      (time) => now.isBefore(time),
      orElse: () => _nextDayTime(model.fajr, now),
    );

    final nextIndex = prayers.indexOf(nextPrayer);
    if (nextIndex == -1) {
      return AppLockPrayerWindow(
        windowStart: model.isha,
        nextPrayerStart: nextPrayer,
      );
    }

    final windowStart = nextIndex == 0 ? model.fajr : prayers[nextIndex - 1];
    final nextPrayerStart = nextIndex == 0 ? model.dhuhr : prayers[nextIndex];

    return AppLockPrayerWindow(
      windowStart: windowStart,
      nextPrayerStart: nextPrayerStart,
    );
  }

  static DateTime _nextDayTime(DateTime time, DateTime now) {
    final nextDay = now.add(const Duration(days: 1));
    return DateTime(
      nextDay.year,
      nextDay.month,
      nextDay.day,
      time.hour,
      time.minute,
      time.second,
      time.millisecond,
      time.microsecond,
    );
  }
}
