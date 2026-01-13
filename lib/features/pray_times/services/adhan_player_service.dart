import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

/// Service to play adhan with volume button and flip-to-mute controls
class AdhanPlayerService {
  static final AdhanPlayerService _instance = AdhanPlayerService._internal();
  factory AdhanPlayerService() => _instance;
  AdhanPlayerService._internal();

  AudioPlayer? _audioPlayer;
  StreamSubscription? _volumeSubscription;
  StreamSubscription? _accelerometerSubscription;
  double? _initialVolume;
  bool _isPlaying = false;

  /// Play adhan sound with volume and flip-to-mute controls
  Future<void> playAdhan({
    required String? soundPath,
    required VoidCallback onComplete,
  }) async {
    if (_isPlaying) {
      debugPrint('🔔 Adhan already playing, skipping...');
      return;
    }

    _isPlaying = true;
    debugPrint('🔔 ═══════════════════════════════════════════════════');
    debugPrint('🔔 Starting Adhan playback');
    debugPrint('🔔 Sound path: ${soundPath ?? "default system sound"}');

    try {
      // If no custom sound, use system default (don't play anything)
      if (soundPath == null) {
        debugPrint('🔔 Using default system notification sound');
        _isPlaying = false;
        onComplete();
        return;
      }

      // Create audio player
      _audioPlayer = AudioPlayer();

      // Configure audio session for alarm/notification
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.duckOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.sonification,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.alarm, // Use alarm volume
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ),
      );

      // Load and play the sound
      await _audioPlayer!.setAsset(soundPath);
      debugPrint('🔔 Sound loaded successfully');

      // Setup volume button listener
      await _setupVolumeListener();

      // Setup flip-to-mute listener
      await _setupFlipListener();

      // Start playback
      debugPrint('🔔 Starting playback...');
      await _audioPlayer!.play();

      // Listen for completion
      _audioPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          debugPrint('🔔 Adhan playback completed');
          stopAdhan();
          onComplete();
        }
      });

      debugPrint(
        '🔔 Adhan playing - Press volume buttons or flip phone to stop',
      );
      debugPrint('🔔 ═══════════════════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ Error playing adhan: $e');
      _isPlaying = false;
      stopAdhan();
      onComplete();
    }
  }

  /// Setup volume button listener to stop adhan
  Future<void> _setupVolumeListener() async {
    try {
      // Get initial volume
      _initialVolume = await FlutterVolumeController.getVolume();
      debugPrint('🔔 Initial volume: $_initialVolume');

      // Listen for volume changes
      FlutterVolumeController.addListener((volume) {
        debugPrint('🔔 Volume changed: $_initialVolume → $volume');

        // If volume changed (user pressed volume button), stop adhan
        if (_initialVolume != null && volume != _initialVolume) {
          debugPrint('🔔 Volume button pressed - stopping adhan');
          stopAdhan();
        }
      });
    } catch (e) {
      debugPrint('⚠️  Could not setup volume listener: $e');
    }
  }

  /// Setup accelerometer listener for flip-to-mute
  Future<void> _setupFlipListener() async {
    try {
      // Track face-up/face-down orientation
      bool? wasFaceUp;

      _accelerometerSubscription =
          accelerometerEventStream(
            samplingPeriod: SensorInterval.normalInterval,
          ).listen((AccelerometerEvent event) {
            // Z-axis: positive = face up, negative = face down
            // When phone is face up: z ≈ 9.8 (gravity)
            // When phone is face down: z ≈ -9.8
            final double z = event.z;

            // Determine current orientation (with threshold to avoid jitter)
            bool isFaceUp = z > 5.0; // Phone facing up
            bool isFaceDown = z < -5.0; // Phone facing down

            if (isFaceUp && wasFaceUp == null) {
              // Initial state - phone is face up
              wasFaceUp = true;
              debugPrint('🔔 Phone is face up (z: ${z.toStringAsFixed(2)})');
            } else if (isFaceDown && wasFaceUp == true) {
              // Phone flipped from face-up to face-down
              debugPrint(
                '🔔 Phone flipped face down (z: ${z.toStringAsFixed(2)}) - stopping adhan',
              );
              stopAdhan();
            }
          });

      debugPrint('🔔 Flip-to-mute listener activated');
    } catch (e) {
      debugPrint('⚠️  Could not setup flip listener: $e');
    }
  }

  /// Stop adhan playback and cleanup
  void stopAdhan() {
    if (!_isPlaying) return;

    debugPrint('🔔 Stopping adhan playback...');

    // Stop audio
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;

    // Remove volume listener
    FlutterVolumeController.removeListener();
    _volumeSubscription?.cancel();
    _volumeSubscription = null;

    // Remove accelerometer listener
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;

    _initialVolume = null;
    _isPlaying = false;

    debugPrint('🔔 Adhan stopped and cleaned up');
  }

  /// Check if adhan is currently playing
  bool get isPlaying => _isPlaying;

  /// Dispose the service
  void dispose() {
    stopAdhan();
  }
}
