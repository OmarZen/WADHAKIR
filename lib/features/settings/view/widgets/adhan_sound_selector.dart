import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../../../../core/constants/adhan_sounds.dart';
import '../../../../core/localization/app_localizations.dart';

class AdhanSoundSelector extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? currentSoundPath;
  final List<AdhanSoundOption> soundOptions;
  final Function(String?) onSoundSelected;
  final bool enabled;

  const AdhanSoundSelector({
    super.key,
    required this.title,
    this.subtitle,
    required this.currentSoundPath,
    required this.soundOptions,
    required this.onSoundSelected,
    this.enabled = true,
  });

  @override
  State<AdhanSoundSelector> createState() => _AdhanSoundSelectorState();
}

class _AdhanSoundSelectorState extends State<AdhanSoundSelector> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingPath;
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _getCurrentSoundName() {
    final l10n = context.l10n;
    final isArabic = l10n?.locale.languageCode == 'ar';

    if (widget.currentSoundPath == null) {
      return isArabic ? 'الصوت الافتراضي' : 'Default Sound';
    }

    final option = widget.soundOptions.firstWhere(
      (opt) => opt.path == widget.currentSoundPath,
      orElse: () => widget.soundOptions.first,
    );

    return isArabic ? option.name : option.nameEn;
  }

  // Play sound with modal state update
  Future<void> _playSoundWithModalState(
      String? path, StateSetter setModalState) async {
    try {
      // If clicking the same sound that's playing, stop it
      if (_isPlaying && _playingPath == path) {
        await _audioPlayer.stop();
        setModalState(() {
          _isPlaying = false;
          _playingPath = null;
        });
        setState(() {
          _isPlaying = false;
          _playingPath = null;
        });
        return;
      }

      // Stop any currently playing sound
      if (_isPlaying) {
        await _audioPlayer.stop();
      }

      // Don't play if path is null (default sound)
      if (path == null) {
        setModalState(() {
          _isPlaying = false;
          _playingPath = null;
        });
        setState(() {
          _isPlaying = false;
          _playingPath = null;
        });
        return;
      }

      // Configure audio session for notification/ring mode (not media)
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType
              .sonification, // Use notification sound type
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage
              .notification, // Controlled by notification volume
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: true,
      ));

      await _audioPlayer.setAsset(path);

      // Update UI to show playing state BEFORE starting playback
      setModalState(() {
        _isPlaying = true;
        _playingPath = path;
      });
      setState(() {
        _isPlaying = true;
        _playingPath = path;
      });

      await _audioPlayer.play();

      // Auto-stop after playback completes
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setModalState(() {
            _isPlaying = false;
            _playingPath = null;
          });
          setState(() {
            _isPlaying = false;
            _playingPath = null;
          });
        }
      });
    } catch (e) {
      debugPrint('Error playing sound: $e');
      setModalState(() {
        _isPlaying = false;
        _playingPath = null;
      });
      setState(() {
        _isPlaying = false;
        _playingPath = null;
      });
    }
  }

  void _showSoundPickerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return _buildSoundPickerSheet(setModalState);
        },
      ),
    );
  }

  Widget _buildSoundPickerSheet(StateSetter setModalState) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset:
              Offset(0, MediaQuery.of(context).size.height * 0.7 * (1 - value)),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title with gradient background
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Sound options list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    itemCount: widget.soundOptions.length +
                        1, // +1 for default option at top
                    itemBuilder: (context, index) {
                      // Default sound option
                      if (index == 0) {
                        final isSelected = widget.currentSoundPath == null;
                        return _buildSoundOption(
                          option: const AdhanSoundOption(
                            name: 'الصوت الافتراضي',
                            nameEn: 'Default Sound',
                            path: null,
                          ),
                          isSelected: isSelected,
                          isPlaying: false, // Default sound can't be previewed
                          theme: theme,
                          setModalState: setModalState,
                          index: index,
                        );
                      }

                      // Regular sound options
                      final option = widget.soundOptions[index - 1];
                      // Skip if this is already a default option in the list
                      if (option.path == null) {
                        return const SizedBox.shrink();
                      }

                      final isSelected = option.path == widget.currentSoundPath;
                      final isPlaying =
                          _isPlaying && _playingPath == option.path;

                      return _buildSoundOption(
                        option: option,
                        isSelected: isSelected,
                        isPlaying: isPlaying,
                        theme: theme,
                        setModalState: setModalState,
                        index: index,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSoundOption({
    required AdhanSoundOption option,
    required bool isSelected,
    required bool isPlaying,
    required ThemeData theme,
    required StateSetter setModalState,
    required int index,
  }) {
    final l10n = context.l10n;
    final isArabic = l10n?.locale.languageCode == 'ar';
    final displayName = isArabic ? option.name : option.nameEn;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                        ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    option.isDefault ? Icons.notifications : Icons.music_note,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 24,
                  ),
                ),
                title: Text(
                  displayName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Play/Stop button (only for non-default sounds)
                    if (!option.isDefault)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        builder: (context, btnValue, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * btnValue),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isPlaying
                                    ? theme.colorScheme.error
                                        .withValues(alpha: 0.15)
                                    : theme.colorScheme.primary
                                        .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.stop_circle
                                      : Icons.play_circle,
                                  color: isPlaying
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary,
                                  size: 32,
                                ),
                                onPressed: () async {
                                  await _playSoundWithModalState(
                                      option.path, setModalState);
                                },
                                tooltip: isPlaying ? 'إيقاف' : 'تشغيل',
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(width: 8),

                    // Selected indicator
                    if (isSelected)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        builder: (context, checkValue, child) {
                          return Transform.scale(
                            scale: checkValue,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary
                                        .withValues(alpha: 0.8),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                onTap: () {
                  debugPrint(
                      '🎵 Sound option tapped: ${option.name} (path: ${option.path})');
                  debugPrint(
                      '🎵 Calling widget.onSoundSelected with path: ${option.path}');
                  widget.onSoundSelected(option.path);
                  debugPrint('🎵 Closing modal...');
                  Navigator.pop(context);
                  debugPrint('🎵 Modal closed');
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: widget.enabled
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.1),
                        ],
                      )
                    : null,
                color: widget.enabled
                    ? null
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.enabled
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: ListTile(
                enabled: widget.enabled,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: widget.enabled
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                            ],
                          )
                        : null,
                    color: widget.enabled
                        ? null
                        : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: widget.enabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 24,
                  ),
                ),
                title: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: widget.enabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                            theme.colorScheme.primary.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getCurrentSoundName(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: widget.enabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
                onTap: widget.enabled ? _showSoundPickerDialog : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
