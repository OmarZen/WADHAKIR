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
  final bool isLoading;

  const RadioLoaded({
    required this.stations,
    this.current,
    this.isPlaying = false,
    this.isLoading = false,
  });

  RadioLoaded copyWith({
    List<RadioStationModel>? stations,
    RadioStationModel? current,
    bool? isPlaying,
    bool? isLoading,
  }) {
    return RadioLoaded(
      stations: stations ?? this.stations,
      current: current ?? this.current,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [stations, current, isPlaying, isLoading];
}

class RadioError extends RadioState {
  final String message;
  final String
      errorType; // 'network', 'timeout', 'format', 'unknown', 'playback'

  const RadioError(this.message, {this.errorType = 'unknown'});

  @override
  List<Object?> get props => [message, errorType];
}
