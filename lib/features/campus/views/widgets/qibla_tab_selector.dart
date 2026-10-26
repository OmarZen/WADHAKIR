import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';

/// The five-way switch under the header: البوصلة · الخريطة · الواقع المعزز ·
/// الظل · الشمس والقمر (fewer on desktop or without a magnetometer).
///
/// ## Height is computed, not measured
/// The AR tab runs its camera *behind* this strip and must pad its safety
/// notice by exactly the strip's height (the Families policy: nothing may
/// cover the notice). Measuring after layout would put the notice under the
/// strip for one frame and then jump, so [heightFor] works the height out
/// from the labels with the same text style the cells use: two lines when any
/// label wraps at this width and text size, one otherwise. Labels are capped
/// at that many lines, so the strip can never be taller than it says.
class QiblaTabSelector extends StatelessWidget {
  final List<QiblaTab> tabs;
  final QiblaTab selected;
  final ValueChanged<QiblaTab> onSelected;

  /// Over the live camera: a flat translucent strip with white content, not a
  /// surface (and not a blur, which would cost a full-screen backdrop filter
  /// every frame of the preview).
  final bool overCamera;

  const QiblaTabSelector({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
    this.overCamera = false,
  });

  static const double _outerH = Spacing.sm;
  static const double _outerV = Spacing.xs + Spacing.xxs;
  static const double _cellH = Spacing.xxs;
  static const double _cellV = Spacing.sm;
  static const double _iconSize = 22;
  static const double _gap = Spacing.xs;
  static const double _labelSize = 12;
  static const double _lineHeight = 1.3;

  static TextStyle _labelStyle(Color color, bool selected) => TextStyle(
    fontFamily: 'Almarai',
    fontSize: _labelSize,
    height: _lineHeight,
    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
    color: color,
  );

  static const StrutStyle _strut = StrutStyle(
    fontFamily: 'Almarai',
    fontSize: _labelSize,
    height: _lineHeight,
    forceStrutHeight: true,
  );

  /// Lines the labels need at [width]: 1, or 2 when any label wraps.
  static int _lines(BuildContext context, List<QiblaTab> tabs, double width) {
    if (tabs.isEmpty) return 1;
    final cellWidth = (width - 2 * _outerH) / tabs.length - 2 * _cellH;
    if (cellWidth <= 0) return 2;
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    for (final tab in tabs) {
      // Bold is the wider weight; measure as if every cell were selected.
      final painter = TextPainter(
        text: TextSpan(
          text: label(context, tab),
          style: _labelStyle(const Color(0xFF000000), true),
        ),
        textDirection: direction,
        textScaler: scaler,
        strutStyle: _strut,
        maxLines: 2,
      )..layout(maxWidth: cellWidth);
      final lines = painter.computeLineMetrics().length;
      painter.dispose();
      if (lines > 1) return 2;
    }
    return 1;
  }

  /// The strip's exact height at [width] in this context.
  static double heightFor(
    BuildContext context, {
    required List<QiblaTab> tabs,
    required double width,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    final line = scaler.scale(_labelSize) * _lineHeight;
    final lines = _lines(context, tabs, width);
    // The 44 dp minimum touch target is met by the icon, gap and one line
    // alone (8 + 22 + 4 + 15.6 + 8 > 44). One pixel of slack absorbs font
    // metric rounding, so the label never overflows its cell by a hair.
    return 2 * _outerV + 2 * _cellV + _iconSize + _gap + lines * line + 1;
  }

  static String label(BuildContext context, QiblaTab tab) {
    switch (tab) {
      case QiblaTab.compass:
        return QiblaStrings.tr(context, 'qibla.tabs.compass', 'البوصلة');
      case QiblaTab.map:
        return QiblaStrings.tr(context, 'qibla.tabs.map', 'الخريطة');
      case QiblaTab.ar:
        return QiblaStrings.tr(context, 'qibla.tabs.ar', 'الواقع المعزز');
      case QiblaTab.shadow:
        return QiblaStrings.tr(context, 'qibla.tabs.shadow', 'الظل');
      case QiblaTab.celestial:
        return QiblaStrings.tr(context, 'qibla.tabs.sun', 'الشمس والقمر');
    }
  }

  static List<List<dynamic>> _icon(QiblaTab tab) {
    switch (tab) {
      case QiblaTab.compass:
        return HugeIcons.strokeRoundedCompass01;
      case QiblaTab.map:
        return HugeIcons.strokeRoundedMaps;
      case QiblaTab.ar:
        return HugeIcons.strokeRoundedAugmentedRealityAr;
      case QiblaTab.shadow:
        return HugeIcons.strokeRoundedContrast;
      case QiblaTab.celestial:
        return HugeIcons.strokeRoundedSunMoon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final accent = AppAccent.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = heightFor(context, tabs: tabs, width: width);
        final lines = _lines(context, tabs, width);

        return Container(
          height: height,
          padding: const EdgeInsets.symmetric(
            horizontal: _outerH,
            vertical: _outerV,
          ),
          decoration: BoxDecoration(
            color: overCamera
                ? Colors.black.withValues(alpha: 0.38)
                : (dark ? theme.scaffoldBackgroundColor : cs.surface),
            border: overCamera
                ? null
                : Border(
                    bottom: BorderSide(
                      color: cs.onSurface.withValues(alpha: 0.06),
                    ),
                  ),
          ),
          child: Row(
            children: [
              for (final tab in tabs)
                Expanded(
                  child: _Cell(
                    label: label(context, tab),
                    icon: _icon(tab),
                    lines: lines,
                    selected: tab == selected,
                    overCamera: overCamera,
                    accent: accent,
                    primary: cs.primary,
                    neutral: cs.onSurface,
                    dark: dark,
                    onPress: () => onSelected(tab),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final List<List<dynamic>> icon;
  final int lines;
  final bool selected;
  final bool overCamera;
  final Color accent;
  final Color primary;
  final Color neutral;
  final bool dark;
  final VoidCallback onPress;

  const _Cell({
    required this.label,
    required this.icon,
    required this.lines,
    required this.selected,
    required this.overCamera,
    required this.accent,
    required this.primary,
    required this.neutral,
    required this.dark,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color fill;
    if (overCamera) {
      fg = Colors.white.withValues(alpha: selected ? 1 : 0.8);
      fill = selected
          ? Colors.white.withValues(alpha: 0.18)
          : Colors.transparent;
    } else {
      fg = selected ? accent : neutral.withValues(alpha: 0.6);
      // The selected cell is a tint, not a fill: the One Glow Rule keeps the
      // saturated fill for whatever the active tab says.
      fill = selected
          ? primary.withValues(alpha: dark ? 0.22 : 0.12)
          : Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QiblaTabSelector._cellH),
      child: Semantics(
        selected: selected,
        child: FTappable(
          onPress: onPress,
          selected: selected,
          semanticsLabel: label,
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : Motion.fast,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: QiblaTabSelector._cellV,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: icon,
                  color: fg,
                  size: QiblaTabSelector._iconSize,
                ),
                const SizedBox(height: QiblaTabSelector._gap),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: lines,
                    overflow: TextOverflow.ellipsis,
                    strutStyle: QiblaTabSelector._strut,
                    style: QiblaTabSelector._labelStyle(fg, selected),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
