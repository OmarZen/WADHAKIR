import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:wadhakir/data/models/radio_station_model.dart';
import 'package:wadhakir/features/radio/cubit/radio_state.dart';
import 'package:wadhakir/domain/usecases/get_radios_usecase.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

class RadioCubit extends Cubit<RadioState> {
  final GetRadiosUseCase getRadiosUseCase;
  final AudioPlayer _player = AudioPlayer();
  double? currentVolume;
  StreamSubscription? _playerStateSubscription;

  RadioCubit(this.getRadiosUseCase) : super(RadioInitial()) {
    _initAudioSession();
    _initVolumeListener();
    _initPlayerStateListener();
  }

  void _initPlayerStateListener() {
    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      final currentState = state;
      if (currentState is RadioLoaded) {
        final isPlaying = playerState.playing;
        final isLoading =
            playerState.processingState == ProcessingState.loading ||
            playerState.processingState == ProcessingState.buffering;

        // Only emit if state actually changed
        if (currentState.isPlaying != isPlaying ||
            currentState.isLoading != isLoading) {
          emit(
            currentState.copyWith(isPlaying: isPlaying, isLoading: isLoading),
          );
        }
      }
    });
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);

      // Handle audio focus/interruptions
      session.interruptionEventStream.listen((event) async {
        final currentState = state;
        if (currentState is RadioLoaded) {
          if (event.begin) {
            // Pause on interruption begin
            if (_player.playing) {
              await _player.pause();
              // State will be updated by player state listener
            }
          } else {
            // Could optionally resume on end, but let user control it
          }
        }
      });

      // Handle becoming noisy (headphones unplugged)
      session.becomingNoisyEventStream.listen((_) async {
        final currentState = state;
        if (currentState is RadioLoaded && _player.playing) {
          await _player.pause();
          // State will be updated by player state listener
        }
      });
    } catch (e) {
      log('AudioSession init error: $e');
    }
  }

  void _initVolumeListener() {
    FlutterVolumeController.addListener((vol) {
      currentVolume = vol;
    });
    FlutterVolumeController.getVolume().then((v) => currentVolume = v);
  }

  Future<void> loadStations({String? language}) async {
    // Preserve current playback state
    final currentState = state;
    RadioStationModel? currentStation;
    bool isPlaying = false;
    bool isLoading = false;

    if (currentState is RadioLoaded) {
      currentStation = currentState.current;
      isPlaying = currentState.isPlaying;
      isLoading = currentState.isLoading;
    }

    emit(RadioLoading());
    try {
      final stations = await getRadiosUseCase(language: language);

      // Find the current station in the new list (in case it was updated)
      RadioStationModel? updatedCurrentStation;
      if (currentStation != null) {
        updatedCurrentStation = stations.firstWhere(
          (station) => station.id == currentStation!.id,
          orElse: () => currentStation!,
        );
      }

      emit(
        RadioLoaded(
          stations: stations,
          current: updatedCurrentStation,
          isPlaying: isPlaying,
          isLoading: isLoading,
        ),
      );
    } catch (e) {
      emit(RadioError(e.toString()));
    }
  }

  Future<void> playStation(RadioStationModel station) async {
    final currentState = state;
    if (currentState is! RadioLoaded) return;

    try {
      // Show loading state immediately
      emit(
        currentState.copyWith(
          current: station,
          isPlaying: false,
          isLoading: true,
        ),
      );

      // Stop current playback if any
      if (_player.playing) {
        await _player.stop();
      }

      // Set URL and start playback
      await _player.setUrl(station.url);
      await _player.play();

      // Player state listener will handle updating isPlaying and isLoading
    } catch (e) {
      // Revert loading state on error
      final errorState = state;
      if (errorState is RadioLoaded) {
        emit(errorState.copyWith(isLoading: false));
      }
      emit(RadioError('Failed to play station: ${e.toString()}'));
    }
  }

  Future<void> togglePlayPause() async {
    final currentState = state;
    if (currentState is! RadioLoaded || currentState.isLoading) return;

    try {
      // Show loading state immediately
      emit(currentState.copyWith(isLoading: true));

      if (_player.playing) {
        await _player.pause();
      } else {
        if (currentState.current == null) {
          // No station selected, can't play
          emit(currentState.copyWith(isLoading: false));
          return;
        }
        await _player.play();
      }

      // Player state listener will handle updating isPlaying and isLoading
    } catch (e) {
      // Revert loading state on error
      final errorState = state;
      if (errorState is RadioLoaded) {
        emit(errorState.copyWith(isLoading: false));
      }
      emit(RadioError('Failed to toggle playback: ${e.toString()}'));
    }
  }

  Future<void> stop() async {
    await _player.stop();
    final currentState = state;
    if (currentState is RadioLoaded) {
      emit(currentState.copyWith(isPlaying: false, current: null));
    }
  }

  Future<void> _playByIndex(int index) async {
    final currentState = state;
    if (currentState is! RadioLoaded) return;
    if (currentState.stations.isEmpty) return;
    final safeIndex =
        (index % currentState.stations.length + currentState.stations.length) %
        currentState.stations.length;
    final target = currentState.stations[safeIndex];
    await playStation(target);
  }

  Future<void> nextStation() async {
    final currentState = state;
    if (currentState is! RadioLoaded) return;
    final idx = _currentIndex(currentState);
    await _playByIndex(idx + 1);
  }

  Future<void> previousStation() async {
    final currentState = state;
    if (currentState is! RadioLoaded) return;
    final idx = _currentIndex(currentState);
    await _playByIndex(idx - 1);
  }

  int _currentIndex(RadioLoaded s) {
    final currentId = s.current?.id;
    final idx = s.stations.indexWhere((e) => e.id == currentId);
    return idx >= 0 ? idx : 0;
  }

  // Helper getters for current playback state
  RadioStationModel? get currentStation {
    final currentState = state;
    return currentState is RadioLoaded ? currentState.current : null;
  }

  bool get isCurrentlyPlaying {
    final currentState = state;
    return currentState is RadioLoaded ? currentState.isPlaying : false;
  }

  bool get isCurrentlyLoading {
    final currentState = state;
    return currentState is RadioLoaded ? currentState.isLoading : false;
  }

  @override
  Future<void> close() {
    _playerStateSubscription?.cancel();
    FlutterVolumeController.removeListener();
    _player.dispose();
    return super.close();
  }

  // Emits a pseudo audio level [0..1] synced to playback position and volume,
  // suitable for driving a visualizer without tapping raw PCM.
  Stream<double> get visualLevelStream {
    // When not playing, emit zeros.
    final playing$ = _player.playingStream.startWith(_player.playing);
    final pos$ = _player.positionStream.startWith(Duration.zero);
    return Rx.combineLatest2<bool, Duration, double>(playing$, pos$, (
      isPlaying,
      pos,
    ) {
      if (!isPlaying) return 0.0;
      final ms = pos.inMilliseconds;
      final vol = (currentVolume ?? 0.5).clamp(0.0, 1.0);
      // Multi-frequency composite for a natural feel
      final v =
          0.5 +
          0.25 * math.sin(ms * 0.008) +
          0.15 * math.sin(ms * 0.014 + 1.3) +
          0.10 * math.sin(ms * 0.021 + 2.6);
      return (v * vol).clamp(0.0, 1.0);
    }).distinct();
  }
}
