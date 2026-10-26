import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/design/design_tokens.dart';

import '../../cubit/tasbih_cubit.dart';
import '../../cubit/tasbih_state.dart';
import '../../data/tasbih_catalog.dart';
import '../../data/tasbih_models.dart';
import '../tasbih_look.dart';
import '../tasbih_strings.dart';

/// The dhikr being counted, with its neighbours faded at either side.
///
/// Endless: the adhkar are a circle, like the beads, so swiping past the last
/// one arrives back at the first, and auto-advance from the last is a single
/// step forward rather than a long rewind.
class DhikrCarousel extends StatefulWidget {
  const DhikrCarousel({super.key, required this.look, this.compact = false});

  final TasbihLook look;

  /// A short screen: a smaller face and a tighter cap on the text scale.
  final bool compact;

  static const double viewportFraction = 0.62;

  @override
  State<DhikrCarousel> createState() => _DhikrCarouselState();
}

class _DhikrCarouselState extends State<DhikrCarousel> {
  /// How many laps the virtual page index starts into, so the user can swipe
  /// backwards from the first dhikr. A thousand laps is more swiping than
  /// anyone does in one visit.
  static const int _laps = 1000;
  static final int _n = TasbihCatalog.all.length;

  late final PageController _controller = PageController(
    viewportFraction: DhikrCarousel.viewportFraction,
    initialPage: _laps * _n + context.read<TasbihCubit>().state.selectedIndex,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _page => _controller.hasClients && _controller.position.hasPixels
      ? (_controller.page ?? _controller.initialPage.toDouble()).round()
      : _controller.initialPage;

  /// When the wheel last turned the carousel, by the events' own clock.
  Duration? _lastWheelStep;

  /// A mouse wheel turns the carousel one dhikr at a time: down is the next,
  /// up the previous. The PageView scrolls only along its own axis, and a
  /// plain wheel is vertical, so on Windows the wheel would otherwise do
  /// nothing here.
  ///
  /// Steps closer together than one page turn are dropped: a free-spinning
  /// or high-resolution wheel sends a burst of events for one flick, and a
  /// page each would race past the dhikr the user meant.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final dy = event.scrollDelta.dy;
    if (dy == 0) return;
    // Through the resolver, so that a sideways wheel the PageView takes
    // itself is not also counted here.
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      final last = _lastWheelStep;
      if (last != null && event.timeStamp - last < Motion.base) return;
      _lastWheelStep = event.timeStamp;
      final cubit = context.read<TasbihCubit>();
      if (dy > 0) {
        cubit.next();
      } else {
        cubit.previous();
      }
    });
  }

  /// Brings the selected dhikr to the centre by the shortest way round.
  void _syncTo(int index) {
    if (!_controller.hasClients) return;
    final page = _page;
    final current = page % _n;
    if (current == index) return;
    var delta = (index - current) % _n;
    if (delta > _n ~/ 2) delta -= _n;
    final target = page + delta;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: Motion.base,
        curve: Motion.standard,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TasbihCubit>();
    final selected = context.select<TasbihCubit, int>(
      (c) => c.state.selectedIndex,
    );
    final fontSize = widget.compact
        ? 28.0
        : widget.look.focus
        ? 38.0
        : 34.0;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return BlocListener<TasbihCubit, TasbihState>(
      listenWhen: (a, b) => a.selectedIndex != b.selectedIndex,
      listener: (_, state) => _syncTo(state.selectedIndex),
      // Diacritics need the room; past 1.3 the text scale would push two
      // lines of naskh off a small phone.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: widget.compact ? 1.15 : 1.3,
        child: Builder(
          builder: (context) {
            final scaled = MediaQuery.textScalerOf(context).scale(fontSize);
            final height = scaled * _DhikrText.lineHeight * 2 + Spacing.sm;
            return Semantics(
              container: true,
              label: TasbihCatalog.all[selected].text,
              textDirection: TextDirection.rtl,
              customSemanticsActions: {
                CustomSemanticsAction(
                  label: TasbihStrings.tr(context, 'tasbih.next_dhikr'),
                ): cubit.next,
                CustomSemanticsAction(
                  label: TasbihStrings.tr(context, 'tasbih.prev_dhikr'),
                ): cubit.previous,
              },
              child: ExcludeSemantics(
                child: SizedBox(
                  height: height,
                  child: RepaintBoundary(
                    child: Listener(
                      onPointerSignal: _onPointerSignal,
                      // Every pointer drags, the mouse included. Flutter's
                      // default leaves the mouse out, and on Windows a mouse
                      // could then not change the dhikr at all.
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: PointerDeviceKind.values.toSet(),
                        ),
                        child: _pages(cubit, fontSize: fontSize, rtl: rtl),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The endless strip of adhkar, each faded and shrunk by its distance from
  /// the centre.
  Widget _pages(
    TasbihCubit cubit, {
    required double fontSize,
    required bool rtl,
  }) => PageView.builder(
    controller: _controller,
    onPageChanged: (page) => cubit.selectIndex(page % _n),
    itemBuilder: (context, i) => AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final page =
            _controller.hasClients && _controller.position.haveDimensions
            ? _controller.page ?? i.toDouble()
            : _controller.initialPage.toDouble();
        final signed = (i - page).clamp(-1.0, 1.0);
        final d = signed.abs();
        // A neighbour leans toward the centre of its page, so a short dhikr
        // still peeks in from the edge instead of sitting out of sight in the
        // middle of a page that is mostly off screen. Later pages lie to the
        // left in RTL, so their inner edge is their right side.
        return Align(
          alignment: Alignment(signed * (rtl ? 1 : -1), 0),
          child: Opacity(
            opacity: 1 - 0.65 * d,
            child: Transform.scale(scale: 1 - 0.2 * d, child: child),
          ),
        );
      },
      child: _DhikrText(
        text: TasbihCatalog.all[i % _n].text,
        fontSize: fontSize,
        color: widget.look.ink,
      ),
    ),
  );
}

/// A dhikr in ScheherazadeNew, shrunk only as far as it must be to fit two
/// lines. Never ellipsized: a cut-off dhikr is a misquoted one.
class _DhikrText extends StatelessWidget {
  const _DhikrText({
    required this.text,
    required this.fontSize,
    required this.color,
  });

  final String text;
  final double fontSize;
  final Color color;

  static const double lineHeight = 1.6;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        TextStyle style(double size) => TextStyle(
          fontFamily: 'ScheherazadeNew',
          fontSize: size,
          height: lineHeight,
          color: color,
        );
        var size = fontSize;
        while (size > 18) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style(size)),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 2,
            textScaler: scaler,
          )..layout(maxWidth: constraints.maxWidth);
          final fits =
              !painter.didExceedMaxLines &&
              painter.height <= constraints.maxHeight;
          painter.dispose();
          if (fits) break;
          size -= 2;
        }
        return Text(
          text,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          maxLines: 2,
          style: style(size),
        );
      },
    );
  }
}

/// «الهدف 33 · اضغط على الزر للبدء», or «الدورة 2» once a round is done —
/// and for two seconds after a round, «اكتملت الدورة N», announced by
/// TalkBack through a live region.
class DhikrSubtitle extends StatefulWidget {
  const DhikrSubtitle({super.key, required this.look, this.compact = false});

  final TasbihLook look;

  /// On a short screen the beads mode drops its direction pill, so the
  /// subtitle names the direction instead.
  final bool compact;

  static String hintKey(
    TasbihMode mode, {
    bool compact = false,
    bool rtl = true,
  }) => switch (mode) {
    TasbihMode.tap => 'tasbih.hint_tap',
    TasbihMode.beads when compact =>
      rtl ? 'tasbih.drag_hint_rtl' : 'tasbih.drag_hint_ltr',
    TasbihMode.beads => 'tasbih.hint_drag',
    TasbihMode.ring || TasbihMode.focus => 'tasbih.hint_anywhere',
  };

  static const Duration doneFor = Duration(seconds: 2);

  @override
  State<DhikrSubtitle> createState() => _DhikrSubtitleState();
}

class _DhikrSubtitleState extends State<DhikrSubtitle> {
  Timer? _doneTimer;
  int? _doneRound;

  @override
  void dispose() {
    _doneTimer?.cancel();
    super.dispose();
  }

  void _onCompleted(TasbihState state) {
    _doneTimer?.cancel();
    setState(() => _doneRound = state.lastCompletedRound);
    _doneTimer = Timer(DhikrSubtitle.doneFor, () {
      if (mounted) setState(() => _doneRound = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final (
      target,
      rounds,
      mode,
    ) = context.select<TasbihCubit, (int, int, TasbihMode)>(
      (c) =>
          (c.state.selected.target, c.state.selected.roundsToday, c.state.mode),
    );
    final targetText = TasbihStrings.tr(context, 'tasbih.target_n', {
      'n': target,
    });
    final String text;
    if (_doneRound != null) {
      text = TasbihStrings.tr(context, 'tasbih.round_done', {'n': _doneRound!});
    } else if (rounds > 0) {
      text =
          '$targetText · '
          '${TasbihStrings.tr(context, 'tasbih.round_n', {'n': rounds + 1})}';
    } else {
      text =
          '$targetText · '
          '${TasbihStrings.tr(context, DhikrSubtitle.hintKey(mode, compact: widget.compact, rtl: Directionality.of(context) == TextDirection.rtl))}';
    }

    return BlocListener<TasbihCubit, TasbihState>(
      listenWhen: (a, b) => a.completionTick != b.completionTick,
      listener: (_, state) => _onCompleted(state),
      child: Semantics(
        liveRegion: _doneRound != null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: widget.look.muted),
          ),
        ),
      ),
    );
  }
}
