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

  RadioCubit(this.getRadiosUseCase) : super(RadioInitial()) {
    _initAudioSession();
    _initVolumeListener();
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
      // Handle audio focus/interruptions if needed
      session.interruptionEventStream.listen((event) async {
        final currentState = state;
        if (currentState is RadioLoaded) {
          if (event.begin) {
            // Pause on interruption begin
            if (_player.playing) {
              await _player.pause();
              emit(currentState.copyWith(isPlaying: false));
            }
          } else {
            // Optionally resume on end
          }
        }
      });
    } catch (_) {}
  }

  void _initVolumeListener() {
    FlutterVolumeController.addListener((vol) {
      currentVolume = vol;
    });
    FlutterVolumeController.getVolume().then((v) => currentVolume = v);
  }

  Future<void> loadStations({String? language}) async {
    emit(RadioLoading());
    try {
      final stations = await getRadiosUseCase(language: language);
      emit(RadioLoaded(stations: stations, current: null, isPlaying: false));
    } catch (e) {
      emit(RadioError(e.toString()));
    }
  }

  Future<void> playStation(RadioStationModel station) async {
    try {
      // Optimistic UI: show current selection immediately
      final currentState = state;
      if (currentState is RadioLoaded) {
        emit(currentState.copyWith(current: station, isPlaying: false));
      }
      await _player.setUrl(station.url);
      await _player.play();
      final afterPlay = state;
      if (afterPlay is RadioLoaded) {
        emit(afterPlay.copyWith(isPlaying: true));
      }
    } catch (e) {
      emit(RadioError('Failed to play: ${e.toString()}'));
    }
  }

  Future<void> togglePlayPause() async {
    final currentState = state;
    if (currentState is RadioLoaded) {
      if (_player.playing) {
        // Optimistic update: reflect UI immediately
        emit(currentState.copyWith(isPlaying: false));
        try {
          await _player.pause();
        } catch (_) {
          // Revert if pause fails
          final st = state;
          if (st is RadioLoaded) emit(st.copyWith(isPlaying: true));
        }
      } else {
        emit(currentState.copyWith(isPlaying: true));
        try {
          await _player.play();
        } catch (_) {
          final st = state;
          if (st is RadioLoaded) emit(st.copyWith(isPlaying: false));
        }
      }
    }
  }

  Future<void> stop() async {
    await _player.stop();
    final currentState = state;
    if (currentState is RadioLoaded) {
      emit(currentState.copyWith(isPlaying: false));
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

  @override
  Future<void> close() {
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
    return Rx.combineLatest2<bool, Duration, double>(playing$, pos$,
        (isPlaying, pos) {
      if (!isPlaying) return 0.0;
      final ms = pos.inMilliseconds;
      final vol = (currentVolume ?? 0.5).clamp(0.0, 1.0);
      // Multi-frequency composite for a natural feel
      final v = 0.5 +
          0.25 * math.sin(ms * 0.008) +
          0.15 * math.sin(ms * 0.014 + 1.3) +
          0.10 * math.sin(ms * 0.021 + 2.6);
      return (v * vol).clamp(0.0, 1.0);
    }).distinct();
  }
}
