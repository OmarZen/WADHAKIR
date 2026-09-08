import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/features/radio/cubit/radio_cubit.dart';
import 'package:wadhakir/features/radio/cubit/radio_state.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class RadioPlayerBar extends StatelessWidget {
  final VoidCallback? onClose;

  const RadioPlayerBar({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    return BlocBuilder<RadioCubit, RadioState>(
      builder: (context, state) {
        if (state is! RadioLoaded || state.current == null) {
          return const SizedBox.shrink();
        }
        final current = state.current!;

        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => _openNowPlaying(context),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: PlatformUtils.isDesktop ? 24.0 : size.width * 0.04,
                vertical: PlatformUtils.isDesktop ? 12.0 : size.height * 0.012,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: PlatformUtils.isDesktop
                      ? 14.0
                      : size.width * 0.03,
                  vertical: PlatformUtils.isDesktop ? 10.0 : size.height * 0.01,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _RadioIconBox(
                      size: PlatformUtils.isDesktop ? 40.0 : size.width * 0.10,
                    ),
                    SizedBox(
                      width: PlatformUtils.isDesktop
                          ? 10.0
                          : size.width * 0.025,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n?.translate('radio.now_playing') ??
                                'Now Playing',
                            style: TextStyle(
                              fontSize: PlatformUtils.isDesktop
                                  ? 11.0
                                  : size.width * 0.028,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            current.getLocalizedName(languageCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: PlatformUtils.isDesktop
                                  ? 14.0
                                  : size.width * 0.036,
                              fontWeight: FontWeight.w700,
                              fontFamily: languageCode == 'en'
                                  ? null
                                  : 'Almarai',
                            ),
                          ),
                          SizedBox(height: PlatformUtils.isDesktop ? 4.0 : 4.0),
                          _AudioLevelVisualizer(
                            height: PlatformUtils.isDesktop ? 18.0 : 18.0,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: size.width * 0.01),
                    BlocConsumer<RadioCubit, RadioState>(
                      listenWhen: (prev, curr) => prev != curr,
                      listener: (context, st) {},
                      builder: (context, st) {
                        final playing = st is RadioLoaded && st.isPlaying;
                        return FButton(
                          onPress: () =>
                              context.read<RadioCubit>().togglePlayPause(),
                          mainAxisSize: MainAxisSize.min,
                          prefix: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: PlatformUtils.isDesktop ? 18.0 : 18.0,
                          ),
                          child: Text(
                            playing
                                ? (l10n?.translate('radio.pause') ?? 'Pause')
                                : (l10n?.translate('radio.play') ?? 'Play'),
                            style: TextStyle(
                              fontSize: PlatformUtils.isDesktop ? 13.0 : 13.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                    if (onClose != null) ...[
                      SizedBox(width: size.width * 0.01),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.85),
                              theme.colorScheme.secondary.withValues(
                                alpha: 0.95,
                              ),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onClose,
                            customBorder: const CircleBorder(),
                            splashColor: Colors.white.withValues(alpha: 0.3),
                            highlightColor: Colors.white.withValues(alpha: 0.1),
                            child: Container(
                              width: PlatformUtils.isDesktop ? 32 : 36,
                              height: PlatformUtils.isDesktop ? 32 : 36,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.close_rounded,
                                size: PlatformUtils.isDesktop ? 16 : 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openNowPlaying(BuildContext context) {
    final radioCubit = context.read<RadioCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocProvider.value(
          value: radioCubit,
          child: const _NowPlayingSheet(),
        );
      },
    );
  }
}

class _NowPlayingSheet extends StatelessWidget {
  const _NowPlayingSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final isDesktop = PlatformUtils.isDesktop;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.35,
      maxChildSize: 1.0,
      builder: (_, controller) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? size.width * 0.8 : double.infinity,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24.0 : size.width * 0.06,
                  vertical: isDesktop ? 16.0 : size.height * 0.02,
                ),
                child: BlocBuilder<RadioCubit, RadioState>(
                  builder: (context, state) {
                    if (state is! RadioLoaded || state.current == null) {
                      return Center(
                        child: Text(l10n?.translate('radio.title') ?? 'Radio'),
                      );
                    }
                    final current = state.current!;

                    return ListView(
                      controller: controller,
                      // Bottom inset so controls clear the nav bar (edge-to-edge).
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewPadding.bottom,
                      ),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(height: isDesktop ? 16.0 : size.height * 0.02),
                        Center(
                          child: _RadioIconBox(
                            size: isDesktop ? 120.0 : size.width * 0.35,
                          ),
                        ),
                        SizedBox(height: isDesktop ? 16.0 : size.height * 0.02),
                        Text(
                          current.getLocalizedName(languageCode),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop ? 24.0 : size.width * 0.06,
                            fontWeight: FontWeight.w800,
                            fontFamily: languageCode == 'en' ? null : 'Almarai',
                          ),
                        ),
                        SizedBox(height: isDesktop ? 8.0 : size.height * 0.012),
                        Text(
                          l10n?.translate('radio.title') ?? 'Radio',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isDesktop ? 14.0 : size.width * 0.035,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: isDesktop ? 20.0 : size.height * 0.02),
                        _AudioLevelVisualizer(
                          height: isDesktop ? 50.0 : size.width * 0.14,
                        ),
                        SizedBox(height: isDesktop ? 24.0 : size.height * 0.02),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded),
                              iconSize: isDesktop ? 32.0 : size.width * 0.08,
                              onPressed: () =>
                                  context.read<RadioCubit>().previousStation(),
                            ),
                            SizedBox(
                              width: isDesktop ? 12.0 : size.width * 0.02,
                            ),
                            BlocConsumer<RadioCubit, RadioState>(
                              listenWhen: (prev, curr) => prev != curr,
                              listener: (context, st) {},
                              builder: (context, st) {
                                final playing =
                                    st is RadioLoaded && st.isPlaying;
                                return FButton(
                                  onPress: () => context
                                      .read<RadioCubit>()
                                      .togglePlayPause(),
                                  mainAxisSize: MainAxisSize.min,
                                  child: Icon(
                                    playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: isDesktop ? 32.0 : size.width * 0.08,
                                  ),
                                );
                              },
                            ),
                            SizedBox(
                              width: isDesktop ? 12.0 : size.width * 0.02,
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded),
                              iconSize: isDesktop ? 32.0 : size.width * 0.08,
                              onPressed: () =>
                                  context.read<RadioCubit>().nextStation(),
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? 16.0 : size.height * 0.02),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpinningDisc extends StatefulWidget {
  final String text;
  final double size;
  const _SpinningDisc({required this.text, required this.size});

  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.2),
              theme.colorScheme.secondary.withValues(alpha: 0.2),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.text.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: widget.size * 0.35,
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveformBars extends StatefulWidget {
  final bool isActive;
  final double level;
  const _WaveformBars({required this.isActive, required this.level});

  @override
  State<_WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<_WaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.2,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _WaveformBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(12, (i) {
              final t = (_controller.value + i * 0.08) % 1.0;
              final reactive = (widget.level.clamp(0.0, 1.0)) * 30;
              final h = 8 + (t * 20) + reactive;
              return Container(
                width: 4,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _RadioIconBox extends StatelessWidget {
  final double size;
  const _RadioIconBox({required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size * 0.8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.secondary.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.radio_rounded,
        color: theme.colorScheme.primary,
        size: size * 0.3,
      ),
    );
  }
}

class _AudioLevelVisualizer extends StatelessWidget {
  final double height;
  const _AudioLevelVisualizer({required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radio = context.read<RadioCubit>();
    return SizedBox(
      height: height,
      child: StreamBuilder<double>(
        stream: radio.visualLevelStream,
        initialData: 0.0,
        builder: (context, snapshot) {
          final level = (snapshot.data ?? 0.0).clamp(0.0, 1.0);
          final bars = 24;
          final colorA = theme.colorScheme.primary.withValues(alpha: 0.45);
          final colorB = theme.colorScheme.onSurface.withValues(alpha: 0.85);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(bars, (i) {
              final noise = 0.6 + 0.4 * (math.sin(i * 1.7) + 1) / 2;
              final h = 6 + (height - 6) * (0.35 + 0.65 * level * noise);
              final w = 3.0;
              final ratio = i / (bars - 1);
              final color = Color.lerp(colorA, colorB, ratio)!;
              return Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: w,
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
