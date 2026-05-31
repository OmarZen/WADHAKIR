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
    String? path,
    StateSetter setModalState,
  ) async {
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
            contentType: AndroidAudioContentType
                .sonification, // Use notification sound type
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage
                .notification, // Controlled by notification volume
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gainTransientMayDuck,
          androidWillPauseWhenDucked: true,
        ),
      );

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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
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

          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                  : theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
              // Pad the bottom by the system gesture/nav inset so the last
              // sound option clears the navigation bar under edge-to-edge.
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12,
                12 + MediaQuery.of(context).viewPadding.bottom,
              ),
              itemCount:
                  widget.soundOptions.length +
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
                final isPlaying = _isPlaying && _playingPath == option.path;

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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.primary.withValues(alpha: 0.08))
            : (isDark
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                  : theme.colorScheme.surface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? isDark
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
                      : theme.colorScheme.primary
                : (isDark
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.2,
                        )
                      : theme.colorScheme.surface),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            option.isDefault ? Icons.notifications : Icons.music_note,
            color: isSelected
                ? isDark
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onPrimary
                : isDark
                ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                : theme.colorScheme.primary,
            size: 18,
          ),
        ),
        title: Text(
          displayName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? isDark
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary
                : isDark
                ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                : theme.colorScheme.onSurface,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play/Stop button (only for non-default sounds)
            if (!option.isDefault)
              Container(
                decoration: BoxDecoration(
                  color: isPlaying
                      ? theme.colorScheme.error.withValues(alpha: 0.15)
                      : theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.stop_circle : Icons.play_circle,
                    color: isPlaying
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    size: 28,
                  ),
                  onPressed: () async {
                    await _playSoundWithModalState(option.path, setModalState);
                  },
                  tooltip: isPlaying ? 'إيقاف' : 'تشغيل',
                ),
              ),

            const SizedBox(width: 6),

            // Selected indicator
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: isDark
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onPrimary,
                  size: 16,
                ),
              ),
          ],
        ),
        onTap: () {
          debugPrint(
            '🎵 Sound option tapped: ${option.name} (path: ${option.path})',
          );
          debugPrint(
            '🎵 Calling widget.onSoundSelected with path: ${option.path}',
          );
          widget.onSoundSelected(option.path);
          debugPrint('🎵 Closing modal...');
          Navigator.pop(context);
          debugPrint('🎵 Modal closed');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: widget.enabled
          ? (isDark
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                : theme.colorScheme.surface)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: widget.enabled ? _showSoundPickerDialog : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.enabled
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.15)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and Arrow
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.enabled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: widget.enabled
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: widget.enabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: widget.enabled
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Current Sound Name
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up,
                      size: 14,
                      color: isDark
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _getCurrentSoundName(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                )
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
