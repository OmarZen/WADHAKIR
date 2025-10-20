import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:equatable/equatable.dart';

class PrayerTimesModel extends Equatable {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime date;
  final CalculationMethod calculationMethod;
  final Coordinates coordinates;

  const PrayerTimesModel({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    required this.calculationMethod,
    required this.coordinates,
  });

  Map<String, dynamic> toJson() {
    final timeFormat = DateFormat('HH:mm');
    return {
      'fajr': timeFormat.format(fajr),
      'sunrise': timeFormat.format(sunrise),
      'dhuhr': timeFormat.format(dhuhr),
      'asr': timeFormat.format(asr),
      'maghrib': timeFormat.format(maghrib),
      'isha': timeFormat.format(isha),
      'date': date.toIso8601String(),
    };
  }

  factory PrayerTimesModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    DateTime parseTime(String time) {
      final parts = time.split(':');
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    return PrayerTimesModel(
      fajr: parseTime(json['fajr']),
      sunrise: parseTime(json['sunrise']),
      dhuhr: parseTime(json['dhuhr']),
      asr: parseTime(json['asr']),
      maghrib: parseTime(json['maghrib']),
      isha: parseTime(json['isha']),
      date: DateTime.parse(json['date']),
      calculationMethod: CalculationMethod.egyptian,
      coordinates: Coordinates(0, 0), // Default coordinates
    );
  }

  factory PrayerTimesModel.fromPrayerTimes(
    PrayerTimes prayerTimes, {
    required CalculationMethod calculationMethod,
    required Coordinates coordinates,
    required DateTime date,
  }) {
    return PrayerTimesModel(
      fajr: prayerTimes.fajr,
      sunrise: prayerTimes.sunrise,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
      date: date,
      calculationMethod: calculationMethod,
      coordinates: coordinates,
    );
  }

  String formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }

  DateTime get nextPrayer {
    final now = DateTime.now();
    if (now.isBefore(fajr)) return fajr;
    if (now.isBefore(sunrise)) return sunrise;
    if (now.isBefore(dhuhr)) return dhuhr;
    if (now.isBefore(asr)) return asr;
    if (now.isBefore(maghrib)) return maghrib;
    if (now.isBefore(isha)) return isha;

    // If all prayers for today have passed, return tomorrow's Fajr
    final dateComponents =
        DateComponents.from(date.add(const Duration(days: 1)));
    final params = calculationMethod.getParameters();
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);
    return prayerTimes.fajr;
  }

  String get nextPrayerName {
    final now = DateTime.now();
    if (now.isBefore(fajr)) return 'الفجر';
    if (now.isBefore(sunrise)) return 'الشروق';
    if (now.isBefore(dhuhr)) return 'الظهر';
    if (now.isBefore(asr)) return 'العصر';
    if (now.isBefore(maghrib)) return 'المغرب';
    if (now.isBefore(isha)) return 'العشاء';
    return 'الفجر';
  }

  Duration get timeUntilNextPrayer {
    final now = DateTime.now();
    return nextPrayer.difference(now);
  }

  Duration get totalIntervalBetweenPrayers {
    final now = DateTime.now();
    DateTime currentPrayer;

    // Find current prayer time (the last prayer that occurred)
    if (now.isBefore(fajr)) {
      // Before Fajr, use Isha from yesterday
      final yesterdayComponents =
          DateComponents.from(date.subtract(const Duration(days: 1)));
      final params = calculationMethod.getParameters();
      final yesterdayPrayers =
          PrayerTimes(coordinates, yesterdayComponents, params);
      currentPrayer = yesterdayPrayers.isha;
    } else if (now.isBefore(sunrise)) {
      currentPrayer = fajr;
    } else if (now.isBefore(dhuhr)) {
      currentPrayer = sunrise;
    } else if (now.isBefore(asr)) {
      currentPrayer = dhuhr;
    } else if (now.isBefore(maghrib)) {
      currentPrayer = asr;
    } else if (now.isBefore(isha)) {
      currentPrayer = maghrib;
    } else {
      // After Isha
      currentPrayer = isha;
    }

    // Calculate total interval between current and next prayer
    return nextPrayer.difference(currentPrayer);
  }

  @override
  List<Object?> get props => [
        fajr,
        sunrise,
        dhuhr,
        asr,
        maghrib,
        isha,
        date,
        calculationMethod,
        coordinates
      ];
}
