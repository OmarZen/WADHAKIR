import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';

abstract class PrayerTimesState extends Equatable {
  const PrayerTimesState();

  @override
  List<Object?> get props => [];
}

class PrayerTimesInitial extends PrayerTimesState {
  const PrayerTimesInitial();
}

class PrayerTimesLoading extends PrayerTimesState {
  const PrayerTimesLoading();
}

class PrayerTimesLoaded extends PrayerTimesState {
  final Map<DateTime, PrayerTimesModel> prayerTimes;
  final DateTime selectedDate;

  const PrayerTimesLoaded({
    required this.prayerTimes,
    required this.selectedDate,
  });

  PrayerTimesModel? get selectedPrayerTimes {
    final dateKey = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    return prayerTimes[dateKey];
  }

  @override
  List<Object?> get props => [prayerTimes, selectedDate];
}

class PrayerTimesError extends PrayerTimesState {
  final String message;

  const PrayerTimesError(this.message);

  @override
  List<Object?> get props => [message];
}
