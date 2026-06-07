import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// What kind of background a share card / wallpaper canvas uses.
enum ShareBackgroundKind { gradient, color, asset, file }

/// An immutable description of a card / canvas background. Shared by the
/// branded share card and the Islamic-backgrounds wallpaper maker so both use
/// the exact same presets and rendering.
///
/// Kept pixel-deterministic (no theme/MediaQuery reads downstream) so the
/// on-screen preview and the captured PNG are identical.
@immutable
class ShareBackground {
  final ShareBackgroundKind kind;

  /// Colors for [ShareBackgroundKind.gradient] (2–3 stops).
  final List<Color> gradientColors;

  /// Solid color for [ShareBackgroundKind.color].
  final Color color;

  /// Bundled asset path for [ShareBackgroundKind.asset].
  final String? assetPath;

  /// Device file path for [ShareBackgroundKind.file].
  final String? filePath;

  const ShareBackground._({
    required this.kind,
    this.gradientColors = const [],
    this.color = const Color(0xFF20497D),
    this.assetPath,
    this.filePath,
  });

  const ShareBackground.gradient(List<Color> colors)
    : this._(kind: ShareBackgroundKind.gradient, gradientColors: colors);

  const ShareBackground.color(Color color)
    : this._(kind: ShareBackgroundKind.color, color: color);

  const ShareBackground.asset(String assetPath)
    : this._(kind: ShareBackgroundKind.asset, assetPath: assetPath);

  const ShareBackground.file(String filePath)
    : this._(kind: ShareBackgroundKind.file, filePath: filePath);

  /// True when the background is a photo (asset or device file) — used to
  /// decide whether to overlay a legibility scrim and skip decorative orbs.
  bool get isImage =>
      kind == ShareBackgroundKind.asset || kind == ShareBackgroundKind.file;

  // ----------------------------------------------------------------- presets

  /// The original brand gradient (default share-card look).
  static const ShareBackground brand = ShareBackground.gradient([
    Color(0xFF20497D),
    Color(0xFF3A6BA8),
  ]);

  /// Handcrafted gradient presets ("predesigned backgrounds").
  static const List<ShareBackground> gradientPresets = [
    brand,
    ShareBackground.gradient([
      Color(0xFF0F2027),
      Color(0xFF203A43),
      Color(0xFF2C5364),
    ]), // night
    ShareBackground.gradient([Color(0xFF134E5E), Color(0xFF2E8B6F)]), // emerald
    ShareBackground.gradient([Color(0xFF3E1E68), Color(0xFF5B2A86)]), // royal
    ShareBackground.gradient([Color(0xFF1A2980), Color(0xFF26D0CE)]), // ocean
    ShareBackground.gradient([Color(0xFF8E2DE2), Color(0xFF4A00E0)]), // violet
    ShareBackground.gradient([Color(0xFFB06AB3), Color(0xFF4568DC)]), // dusk
    ShareBackground.gradient([Color(0xFF6D4C41), Color(0xFFC79081)]), // sand
    ShareBackground.gradient([Color(0xFF232526), Color(0xFF414345)]), // charcoal
  ];

  /// Quick solid-color swatches (the picker covers everything else).
  static const List<Color> colorPresets = [
    Color(0xFF20497D),
    Color(0xFF134E5E),
    Color(0xFF2C5364),
    Color(0xFF3E1E68),
    Color(0xFF6D4C41),
    Color(0xFF1B5E20),
    Color(0xFF0D1122),
    Color(0xFF880E4F),
  ];

  /// Number of bundled mosque photos (assets/images/mosques/1..11.jpg).
  static const int mosqueCount = 11;

  /// The bundled mosque photos as backgrounds.
  static List<ShareBackground> get mosquePresets => List.generate(
    mosqueCount,
    (i) => ShareBackground.asset('assets/images/mosques/${i + 1}.jpg'),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShareBackground &&
        other.kind == kind &&
        other.color == color &&
        other.assetPath == assetPath &&
        other.filePath == filePath &&
        listEquals(other.gradientColors, gradientColors);
  }

  @override
  int get hashCode => Object.hash(
    kind,
    color,
    assetPath,
    filePath,
    Object.hashAll(gradientColors),
  );
}
