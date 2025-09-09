import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/radio_station_model.dart';

abstract class RadioState extends Equatable {
  const RadioState();

  @override
  List<Object?> get props => [];
}

class RadioInitial extends RadioState {}

class RadioLoading extends RadioState {}

class RadioLoaded extends RadioState {
  final List<RadioStationModel> stations;
  final RadioStationModel? current;
  final bool isPlaying;

  const RadioLoaded(
      {required this.stations, this.current, this.isPlaying = false});

  RadioLoaded copyWith({
    List<RadioStationModel>? stations,
    RadioStationModel? current,
    bool? isPlaying,
  }) {
    return RadioLoaded(
      stations: stations ?? this.stations,
      current: current ?? this.current,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  @override
  List<Object?> get props => [stations, current, isPlaying];
}

class RadioError extends RadioState {
  final String message;
  const RadioError(this.message);

  @override
  List<Object?> get props => [message];
}
