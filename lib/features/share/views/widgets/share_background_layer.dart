import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wadhakir/features/share/models/share_background.dart';

/// Renders a [ShareBackground] as a fill layer for a share card / wallpaper
/// canvas, with an optional dark legibility scrim over photo backgrounds so
/// white text and the logo stay readable.
///
/// Pixel-deterministic: reads nothing from theme/MediaQuery, so the on-screen
/// preview and captured PNG match. Photos are decoded at [imageCacheWidth] to
/// keep the large bundled mosque JPEGs from blowing up memory.
class ShareBackgroundLayer extends StatelessWidget {
  const ShareBackgroundLayer({
    super.key,
    required this.background,
    this.scrim = true,
    this.imageCacheWidth,
  });

  final ShareBackground background;

  /// Whether to overlay the dark gradient scrim on photo backgrounds.
  final bool scrim;

  /// Decode width for asset/file photos (null = full size). Set to the target
  /// output pixel width (e.g. 1080) for crisp wallpapers, or small for thumbs.
  final int? imageCacheWidth;

  /// Warm the image cache for an image-backed [background] at the SAME decode
  /// width the layer uses ([width]), so a subsequent capture isn't blank/stale.
  /// Returns immediately for gradient/color backgrounds. The returned future
  /// completes once the first frame is available in the cache.
  static Future<void> precache(
    ShareBackground background,
    BuildContext context, {
    int width = 1080,
  }) {
    switch (background.kind) {
      case ShareBackgroundKind.asset:
        return precacheImage(
          ResizeImage(AssetImage(background.assetPath!), width: width),
          context,
        );
      case ShareBackgroundKind.file:
        return precacheImage(
          ResizeImage(FileImage(File(background.filePath!)), width: width),
          context,
        );
      case ShareBackgroundKind.gradient:
      case ShareBackgroundKind.color:
        return Future<void>.value();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _background(),
        if (background.isImage && scrim) const _LegibilityScrim(),
      ],
    );
  }

  Widget _background() {
    switch (background.kind) {
      case ShareBackgroundKind.gradient:
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: background.gradientColors.isEmpty
                  ? ShareBackground.brand.gradientColors
                  : background.gradientColors,
            ),
          ),
        );
      case ShareBackgroundKind.color:
        return ColoredBox(color: background.color);
      case ShareBackgroundKind.asset:
        return Image.asset(
          background.assetPath!,
          fit: BoxFit.cover,
          cacheWidth: imageCacheWidth,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: Color(0xFF20497D)),
        );
      case ShareBackgroundKind.file:
        return Image.file(
          File(background.filePath!),
          fit: BoxFit.cover,
          cacheWidth: imageCacheWidth,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: Color(0xFF20497D)),
        );
    }
  }
}

/// Dark top-and-bottom gradient that keeps light text/logo legible over busy
/// photo backgrounds without fully hiding the image.
class _LegibilityScrim extends StatelessWidget {
  const _LegibilityScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x99000000),
            Color(0x26000000),
            Color(0x59000000),
            Color(0xB3000000),
          ],
          stops: [0.0, 0.35, 0.68, 1.0],
        ),
      ),
    );
  }
}
