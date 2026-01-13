import 'package:equatable/equatable.dart';

class PrayerTime extends Equatable {
  final String name;
  final String time;
  final bool isNext;

  const PrayerTime({
    required this.name,
    required this.time,
    this.isNext = false,
  });

  PrayerTime copyWith({String? name, String? time, bool? isNext}) {
    return PrayerTime(
      name: name ?? this.name,
      time: time ?? this.time,
      isNext: isNext ?? this.isNext,
    );
  }

  @override
  List<Object?> get props => [name, time, isNext];
}
