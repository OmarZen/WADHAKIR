import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Entry point Flutter uses for the overlay engine. Must be a top-level
/// function annotated with `@pragma('vm:entry-point')` so the Dart VM can
/// invoke it after the overlay is shown.
///
/// IMPORTANT: this runs in a SEPARATE Flutter engine — bindings are not
/// pre-initialized, and the engine doesn't know about the host app's
/// Scaffold/MediaQuery/theme. Keep the widget tree as small as possible
/// and avoid Scaffold here — it expects MediaQuery which can be wonky in
/// an overlay window (we saw `Width is zero. 0,0` from FlutterRenderer
/// when Scaffold was used).
@pragma('vm:entry-point')
void floatingDhikrOverlayEntry() {
  WidgetsFlutterBinding.ensureInitialized();
  dev.log('floatingDhikrOverlayEntry: starting', name: 'FloatingDhikrOverlay');
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // Transparent root so the host app/wallpaper shows through.
      color: const Color(0x00000000),
      home: const _PillBarRoot(),
    ),
  );
}

/// Minimal root widget — Material(transparent) + the pill bar widget.
/// Matches the structure used by flutter_overlay_window's official example,
/// which is the only structure that renders reliably across OEM skins.
class _PillBarRoot extends StatelessWidget {
  const _PillBarRoot();

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: _PillBar());
  }
}

class _PillBar extends StatefulWidget {
  const _PillBar();

  @override
  State<_PillBar> createState() => _PillBarState();
}

class _PillBarState extends State<_PillBar>
    with SingleTickerProviderStateMixin {
  String _text = 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ';
  double _opacity = 0.95;
  // Anchor sent from the main isolate. Drives whether the pill sits at the
  // top or bottom of the overlay window (and which edge gets the larger
  // clearance from status bar / gesture nav bar).
  String _anchor = 'topBar';
  late final AnimationController _fade;

  bool get _isBottomAnchored =>
      _anchor == 'bottomBar' ||
      _anchor == 'bottomLeft' ||
      _anchor == 'bottomRight';

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();

    // Receive the dhikr text + opacity + anchor from the main isolate.
    FlutterOverlayWindow.overlayListener.listen((event) {
      dev.log('PillBar received event: $event', name: 'FloatingDhikrOverlay');
      try {
        final raw = event is String
            ? event
            : (event is Map ? jsonEncode(event) : null);
        if (raw == null) return;
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _text = (data['text'] as String?) ?? _text;
          _opacity = ((data['opacity'] as num?)?.toDouble() ?? _opacity).clamp(
            0.5,
            1.0,
          );
          _anchor = (data['anchor'] as String?) ?? _anchor;
        });
      } catch (e) {
        dev.log('PillBar decode error: $e', name: 'FloatingDhikrOverlay');
      }
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      dev.log('closeOverlay error: $e', name: 'FloatingDhikrOverlay');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pill alignment + padding depends on which anchor the user picked.
    // The overlay window itself is positioned by Android's WindowManager
    // at the screen edge; inside that window we further nudge the pill
    // away from the matching edge so the status bar / notch / gesture
    // indicator never clips it.
    final bottomAnchored = _isBottomAnchored;
    // Pull the pill a bit further away from the very edge of the screen so
    // it sits "inside" the content area rather than hugging the notch /
    // gesture indicator. Side padding is wider too so the banner stretches
    // visibly across the screen.
    final padding = bottomAnchored
        ? const EdgeInsets.fromLTRB(12, 12, 12, 180)
        : const EdgeInsets.fromLTRB(12, 180, 12, 12);
    final alignment = bottomAnchored
        ? Alignment.bottomCenter
        : Alignment.topCenter;

    return SizedBox.expand(
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic),
        child: Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Container(
              margin: padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF20497D).withValues(alpha: _opacity),
                    const Color(0xFF2C5A92).withValues(alpha: _opacity),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.32),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D1122).withValues(alpha: 0.50),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Text(
                      _text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Almarai',
                        fontSize: 18,
                        // height: 1.4,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      // maxLines: 3,
                      // overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _close,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
