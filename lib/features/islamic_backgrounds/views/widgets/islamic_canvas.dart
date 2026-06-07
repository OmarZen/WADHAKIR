import 'package:flutter/material.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/features/share/models/share_background.dart';
import 'package:wadhakir/features/share/views/widgets/share_background_layer.dart';

/// The designed 9:16 wallpaper canvas: a background, a centered Arabic phrase
/// in calligraphy, and a small fixed app-logo badge pinned to the bottom.
///
/// Pixel-deterministic (no theme/MediaQuery reads) so the on-screen preview and
/// the captured PNG match. Rendered with SQUARE corners so the exported
/// wallpaper is full-bleed — the caller rounds it for the preview only, outside
/// the RepaintBoundary.
class IslamicCanvas extends StatelessWidget {
  const IslamicCanvas({
    super.key,
    required this.background,
    required this.text,
    this.reference,
    this.fontFamily = 'ArefRuqaa',
    this.imageCacheWidth = 1080,
    this.textAlignment = const Alignment(0, -0.15),
    this.textScale = 1.0,
  });

  final ShareBackground background;
  final String text;
  final String? reference;
  final String fontFamily;
  final int imageCacheWidth;

  /// Where the text block sits on the canvas (-1..1 on each axis). Driven by
  /// dragging in the editor.
  final Alignment textAlignment;

  /// User zoom factor for the text block. Driven by the size slider / pinch.
  final double textScale;

  /// Portrait phone ratio.
  static const double aspectRatio = 9 / 16;

  @override
  Widget build(BuildContext context) {
    final hasReference = reference != null && reference!.trim().isNotEmpty;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          // Width-relative font so the default "spreads" nicely and scales
          // with the canvas (deterministic between preview and capture).
          final len = text.trim().length;
          final factor = len < 40
              ? 0.095
              : len < 90
              ? 0.072
              : len < 160
              ? 0.055
              : 0.044;
          final fontSize = (w * factor).clamp(12.0, 64.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              ShareBackgroundLayer(
                background: background,
                imageCacheWidth: imageCacheWidth,
              ),
              // Draggable + scalable text block.
              Align(
                alignment: textAlignment,
                child: Transform.scale(
                  scale: textScale,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w * 0.86),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: fontFamily,
                            fontSize: fontSize,
                            height: 1.7,
                            fontWeight: FontWeight.w600,
                            shadows: const [
                              Shadow(
                                color: Color(0x73000000),
                                blurRadius: 12,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        if (hasReference) ...[
                          SizedBox(height: h * 0.016),
                          Text(
                            reference!,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontFamily: 'Almarai',
                              fontSize: (w * 0.035).clamp(9.0, 22.0),
                              height: 1.4,
                              shadows: const [
                                Shadow(color: Color(0x59000000), blurRadius: 6),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Fixed bottom badge — never moves with the text.
              Positioned(
                left: 0,
                right: 0,
                bottom: h * 0.045,
                child: const Center(child: _LogoBadge()),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Small fixed badge at the bottom of the canvas: app logo + wordmark in a
/// subtle translucent pill (always present, like the reference design).
class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.mosque_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            AppConstants.appName,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Almarai',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
