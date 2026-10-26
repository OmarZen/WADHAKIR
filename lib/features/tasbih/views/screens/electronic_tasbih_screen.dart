import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart'
    show kOverlayStyleLightIcons;
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/core/ui/islamic_decorations.dart';
import 'package:wadhakir/core/widgets/branded_header.dart';

import '../../cubit/tasbih_cubit.dart';
import '../../cubit/tasbih_state.dart';
import '../../data/tasbih_models.dart';
import '../../data/tasbih_repository.dart';
import '../../services/tasbih_feedback.dart';
import '../tasbih_look.dart';
import '../tasbih_strings.dart';
import '../widgets/dhikr_carousel.dart';
import '../widgets/modes/beads_mode.dart';
import '../widgets/modes/focus_mode.dart';
import '../widgets/modes/ring_mode.dart';
import '../widgets/modes/tap_mode.dart';
import '../widgets/tasbih_action_pill.dart';
import '../widgets/tasbih_mode_selector.dart';
import '../widgets/tasbih_stat_chips.dart';

/// السبحة: count adhkar four ways — beads, a button, a ring of dots, or a
/// dark focus screen.
///
/// Owns the [TasbihCubit] and everything tied to this screen's lifetime:
/// saving when the app goes to the background, reapplying keep-screen-on when
/// it comes back, and letting the screen sleep again on the way out.
class ElectronicTasbihScreen extends StatefulWidget {
  const ElectronicTasbihScreen({
    super.key,
    this.feedback,
    this.repository,
    this.now,
  });

  /// Test seams. In the app all three are left null.
  final TasbihFeedback? feedback;
  final TasbihRepository? repository;
  final DateTime Function()? now;

  @override
  State<ElectronicTasbihScreen> createState() => _ElectronicTasbihScreenState();
}

class _ElectronicTasbihScreenState extends State<ElectronicTasbihScreen>
    with WidgetsBindingObserver {
  late final TasbihFeedback _feedback =
      widget.feedback ?? TasbihFeedback.forPlatform();
  late final TasbihCubit _cubit = TasbihCubit(
    repository: widget.repository ?? TasbihRepository(),
    feedback: _feedback,
    now: widget.now,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_feedback.supportsKeepScreenOn) _feedback.setKeepScreenOn(false);
    _feedback.release();
    _cubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _cubit.refreshDay();
        // Every time, not only on a change: the activity can be recreated
        // under the cached engine (MainActivity is an AudioServiceActivity),
        // and a new window starts without the flag.
        _applyScreenOn(_cubit.state);
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _cubit.flush();
    }
  }

  /// Closing the window on Windows asks here, and the process ends straight
  /// after, with no pause on the way, so the debounced taps (up to half a
  /// second of counting) are written now or never.
  @override
  Future<AppExitResponse> didRequestAppExit() async {
    await _cubit.flush();
    return AppExitResponse.exit;
  }

  void _applyScreenOn(TasbihState state) {
    if (!_feedback.supportsKeepScreenOn || state.loading) return;
    _feedback.setKeepScreenOn(state.wantsScreenOn);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<TasbihCubit, TasbihState>(
        listenWhen: (a, b) =>
            a.loading != b.loading || a.wantsScreenOn != b.wantsScreenOn,
        listener: (_, state) => _applyScreenOn(state),
        child: const _TasbihView(),
      ),
    );
  }
}

class _TasbihView extends StatelessWidget {
  const _TasbihView();

  /// On a keyboard (Windows, or a phone with one) Space and Enter count, and
  /// the arrows change the dhikr. Only reached while the screen itself has
  /// the focus — see the `Focus` below — and marked handled, so the app's
  /// default shortcuts do not act on the same key as well.
  KeyEventResult _onKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final cubit = context.read<TasbihCubit>();
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      cubit.increment();
      return KeyEventResult.handled;
    }
    // The arrows follow the carousel: its next dhikr lies to the left in
    // Arabic and to the right in English.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final bool forward;
    if (key == LogicalKeyboardKey.arrowLeft) {
      forward = rtl;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      forward = !rtl;
    } else {
      return KeyEventResult.ignored;
    }
    if (forward) {
      cubit.next();
    } else {
      cubit.previous();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (mode, loading) = context.select<TasbihCubit, (TasbihMode, bool)>(
      (c) => (c.state.mode, c.state.loading),
    );
    final focus = mode == TasbihMode.focus;
    final look = TasbihLook.of(context, focus: focus);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final title = TasbihStrings.tr(context, 'tasbih.title');

    // In focus mode the header turns dark with the screen. BrandedHeader
    // paints from colorScheme.primary, so a local theme is all it takes.
    final header = focus
        ? Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: look.background,
                onPrimary: Colors.white,
              ),
            ),
            child: BrandedHeader(title: title),
          )
        : BrandedHeader(title: title);

    // Light status-bar icons: the top of this screen is always dark (the
    // brand header, or the whole screen in focus mode). Without this the
    // Scaffold inherits dark icons, which vanish against both.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kOverlayStyleLightIcons,
      child: Scaffold(
        backgroundColor: look.background,
        // Autofocused, so the keys count from the moment the screen opens.
        // But a key that bubbles up from a button the user has tabbed to is
        // that button's: Space on «إعادة ضبط» must open its dialog, not
        // count, and the arrows must still move the focus between buttons.
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) => node.hasPrimaryFocus
              ? _onKey(context, event)
              : KeyEventResult.ignored,
          child: AnimatedContainer(
            duration: reduce ? Duration.zero : Motion.slow,
            curve: Motion.standard,
            color: look.background,
            child: Stack(
              children: [
                // The brand's lattice, faint, in place of the reference
                // mockups' mosque silhouettes.
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: IslamicPatternPainter(
                          color: focus ? Colors.white : look.accent,
                          opacity: focus ? 0.06 : 0.05,
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    header,
                    Expanded(
                      child: SafeArea(
                        top: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    Spacing.lg,
                                    Spacing.md,
                                    Spacing.lg,
                                    Spacing.sm,
                                  ),
                                  child: TasbihModeSelector(look: look),
                                ),
                                Expanded(
                                  child: loading
                                      ? const SizedBox.expand()
                                      : _CountingArea(
                                          mode: mode,
                                          look: look,
                                          reduceMotion: reduce,
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: Spacing.sm,
                                    bottom: Spacing.md,
                                  ),
                                  child: TasbihActionPill(look: look),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Everything between the selector and the pill.
class _CountingArea extends StatelessWidget {
  const _CountingArea({
    required this.mode,
    required this.look,
    required this.reduceMotion,
  });

  final TasbihMode mode;
  final TasbihLook look;
  final bool reduceMotion;

  /// Ring and focus count a tap anywhere — their hint says so. Tap mode counts
  /// on its button, and beads on the string, each with its own recogniser.
  bool get _tapAnywhere => mode == TasbihMode.ring || mode == TasbihMode.focus;

  /// Below this height for the whole area — a small phone at a large text
  /// size — the parts tighten: a smaller dhikr, a smaller count, the chips'
  /// text capped. Measured, not guessed from the device, so a tablet in split
  /// screen gets it too.
  static const double compactBelow = 470;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _build(context, compact: constraints.maxHeight < compactBelow),
    );
  }

  Widget _build(BuildContext context, {required bool compact}) {
    final cubit = context.read<TasbihCubit>();
    final body = switch (mode) {
      TasbihMode.beads => BeadsModeBody(look: look, compact: compact),
      TasbihMode.tap => TapModeBody(look: look),
      TasbihMode.ring => RingModeBody(look: look),
      TasbihMode.focus => FocusModeBody(look: look),
    };

    final column = Column(
      children: [
        DhikrCarousel(look: look, compact: compact),
        DhikrSubtitle(look: look, compact: compact),
        const SizedBox(height: Spacing.sm),
        Expanded(
          child: AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : Motion.base,
            child: KeyedSubtree(key: ValueKey(mode), child: body),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: compact ? 1.2 : 1.6,
            child: mode == TasbihMode.focus
                ? TasbihFocusHint(
                    look: look,
                    screenStaysOn: cubit.feedback.supportsKeepScreenOn,
                  )
                : TasbihStatChips(look: look),
          ),
        ),
      ],
    );

    // In ring and focus, one opaque detector over the whole area, carousel
    // included: a clean tap counts, a horizontal drag still pages the
    // carousel (its own recogniser wins the arena once the finger moves past
    // the slop).
    //
    // The same Semantics and detector in every mode, with the tap switched
    // off where it does not belong. Wrapping the column only in some modes
    // would change the widget above it on a mode switch, and Flutter would
    // rebuild everything under it from scratch: the carousel, the subtitle
    // with a «اكتملت الدورة N» still showing, and the switcher whose
    // cross-fade is the whole point of the switch.
    final tapAnywhere = _tapAnywhere;
    return Semantics(
      button: tapAnywhere ? true : null,
      label: tapAnywhere
          ? TasbihStrings.tr(context, 'tasbih.hint_anywhere')
          : null,
      onTap: tapAnywhere ? cubit.increment : null,
      child: GestureDetector(
        behavior: tapAnywhere
            ? HitTestBehavior.opaque
            : HitTestBehavior.deferToChild,
        onTap: tapAnywhere ? cubit.increment : null,
        child: column,
      ),
    );
  }
}
