import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/share/models/share_background.dart';

/// Horizontal background selector shared by the share screen and the
/// Islamic-backgrounds wallpaper maker. Offers, in order: pick-a-device-photo,
/// open-color-wheel, solid-color swatches, gradient presets, and the bundled
/// mosque photos. Selecting a photo precaches it at output resolution so the
/// capture is sharp.
class BackgroundPickerBar extends StatelessWidget {
  const BackgroundPickerBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ShareBackground selected;
  final ValueChanged<ShareBackground> onChanged;

  static const double _tile = 54;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tiles = <Widget>[
      _ActionTile(
        icon: Icons.add_photo_alternate_outlined,
        label: l10n?.translate('islamic_backgrounds.your_photo') ?? 'صورتك',
        onTap: () => _pickPhoto(context),
      ),
      _ActionTile(
        icon: Icons.palette_outlined,
        label: l10n?.translate('islamic_backgrounds.color') ?? 'لون',
        onTap: () => _pickColor(context),
      ),
      for (final c in ShareBackground.colorPresets)
        _SwatchTile(
          selected:
              selected.kind == ShareBackgroundKind.color && selected.color == c,
          onTap: () => onChanged(ShareBackground.color(c)),
          child: ColoredBox(color: c),
        ),
      for (final g in ShareBackground.gradientPresets)
        _SwatchTile(
          selected: selected == g,
          onTap: () => onChanged(g),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: g.gradientColors,
              ),
            ),
          ),
        ),
      for (final m in ShareBackground.mosquePresets)
        _SwatchTile(
          selected: selected == m,
          // The host screen precaches (and awaits) the full-res decode before
          // capture; the bar just reports the selection.
          onTap: () => onChanged(m),
          child: Image.asset(m.assetPath!, fit: BoxFit.cover, cacheWidth: 140),
        ),
    ];

    return SizedBox(
      height: _tile + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: tiles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => tiles[i],
      ),
    );
  }

  Future<void> _pickColor(BuildContext context) async {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    Color temp = selected.kind == ShareBackgroundKind.color
        ? selected.color
        : const Color(0xFF20497D);
    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              final hex =
                  '#${(temp.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.palette_rounded,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n?.translate(
                                    'islamic_backgrounds.pick_color',
                                  ) ??
                                  'اختر لوناً',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Live preview swatch + hex.
                      Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: temp,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.12,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: temp.withValues(alpha: 0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          hex,
                          style: TextStyle(
                            color: temp.computeLuminance() > 0.5
                                ? Colors.black87
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ColorPicker(
                        pickerColor: temp,
                        onColorChanged: (c) => setLocal(() => temp = c),
                        enableAlpha: false,
                        labelTypes: const [],
                        pickerAreaHeightPercent: 0.62,
                        pickerAreaBorderRadius: BorderRadius.circular(16),
                        portraitOnly: true,
                      ),
                      const SizedBox(height: 4),
                      // Quick preset swatches.
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final c in ShareBackground.colorPresets)
                            GestureDetector(
                              onTap: () => setLocal(() => temp = c),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: temp == c
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                l10n?.translate('common.cancel') ?? 'إلغاء',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(ctx, temp),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                l10n?.translate('common.ok') ?? 'موافق',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    if (result != null) onChanged(ShareBackground.color(result));
  }

  Future<void> _pickPhoto(BuildContext context) async {
    try {
      final XFile? x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2200,
        imageQuality: 92,
      );
      if (x == null) return;
      onChanged(ShareBackground.file(x.path));
    } catch (e) {
      debugPrint('BackgroundPickerBar.pickPhoto error: $e');
    }
  }
}

/// A square action button (pick photo / open color wheel).
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: BackgroundPickerBar._tile,
        height: BackgroundPickerBar._tile,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// A selectable square swatch (color / gradient / photo) with a highlight ring.
class _SwatchTile extends StatelessWidget {
  const _SwatchTile({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: BackgroundPickerBar._tile,
        height: BackgroundPickerBar._tile,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.15),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (selected)
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
