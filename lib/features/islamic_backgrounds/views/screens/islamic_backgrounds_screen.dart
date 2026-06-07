import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/utils/widget_to_image.dart';
import 'package:wadhakir/features/islamic_backgrounds/services/gallery_saver_service.dart';
import 'package:wadhakir/features/islamic_backgrounds/services/wallpaper_service.dart';
import 'package:wadhakir/features/islamic_backgrounds/views/widgets/background_text_sheet.dart';
import 'package:wadhakir/features/islamic_backgrounds/views/widgets/islamic_canvas.dart';
import 'package:wadhakir/features/share/models/share_background.dart';
import 'package:wadhakir/features/share/views/widgets/background_picker_bar.dart';
import 'package:wadhakir/features/share/views/widgets/share_background_layer.dart';

/// "الخلفيات الإسلامية" — pick a background (gradient / color / mosque photo /
/// own photo), drop an Arabic phrase (custom or ready-made) on it with the app
/// logo fixed at the bottom, then set it as wallpaper, save it, or share it.
class IslamicBackgroundsScreen extends StatefulWidget {
  const IslamicBackgroundsScreen({super.key});

  @override
  State<IslamicBackgroundsScreen> createState() =>
      _IslamicBackgroundsScreenState();
}

class _IslamicBackgroundsScreenState extends State<IslamicBackgroundsScreen> {
  final GlobalKey _canvasKey = GlobalKey();

  /// Decode/output width for the wallpaper canvas. Matches the capture so the
  /// photo background isn't upscaled (capture is pixelRatio 3.5 over a ~360-wide
  /// canvas → ~1260px; 2160 keeps detail headroom from the multi-MP sources).
  static const int _canvasImageWidth = 2160;

  ShareBackground _background = ShareBackground.gradientPresets[1];
  String _text = 'وَذَكِّرْ فَإِنَّ ٱلذِّكْرَىٰ تَنفَعُ ٱلْمُؤْمِنِينَ';
  String? _reference = 'الذاريات ٥٥';
  String _fontFamily = 'ArefRuqaa';
  bool _busy = false;

  /// Text position on the canvas (-1..1 each axis) and zoom — driven by drag,
  /// the size slider, and pinch.
  static const Alignment _defaultTextAlignment = Alignment(0, -0.15);
  Alignment _textAlignment = _defaultTextAlignment;
  double _textScale = 1.0;
  double _scaleGestureStart = 1.0;

  /// Completes when the current background's image is decoded into the cache,
  /// so a capture isn't blank/stale. No-op for gradient/color backgrounds.
  Future<void> _bgReady = Future<void>.value();

  void _onBackgroundChanged(ShareBackground background) {
    setState(() => _background = background);
    _bgReady = ShareBackgroundLayer.precache(
      background,
      context,
      width: _canvasImageWidth,
    );
  }

  static const List<(String, String)> _fonts = [
    ('ArefRuqaa', 'رقعة'),
    ('ScheherazadeNew', 'نسخ'),
    ('Jomhuria', 'جمهورية'),
  ];

  String _tr(String key, String fallback) =>
      AppLocalizations.of(context)?.translate(key) ?? fallback;

  // ------------------------------------------------------------------ actions

  Future<File?> _capture() async {
    // Ensure a freshly-chosen photo background is decoded before snapshotting.
    await _bgReady;
    if (!mounted) return null;
    return captureBoundaryToPngFile(
      _canvasKey,
      pixelRatio: 3.5,
      prefix: 'wadhakir-bg',
    );
  }

  Future<void> _editText() async {
    final quote = await showBackgroundTextSheet(context, initialText: _text);
    if (quote == null) return;
    setState(() {
      _text = quote.text;
      _reference = quote.reference;
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _capture();
      if (file == null) {
        if (!mounted) return;
        _toast(_tr('islamic_backgrounds.failed', 'تعذّر إنشاء الصورة'), bad: true);
        return;
      }
      final ok = await GallerySaverService.saveFile(file.path);
      if (!mounted) return;
      _toast(
        ok
            ? _tr('islamic_backgrounds.saved', 'تم الحفظ في المعرض')
            : _tr('islamic_backgrounds.save_failed', 'تعذّر الحفظ في المعرض'),
        bad: !ok,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (_busy) return;
    final caption = _caption();
    setState(() => _busy = true);
    try {
      final file = await _capture();
      if (file == null) {
        if (!mounted) return;
        _toast(_tr('islamic_backgrounds.failed', 'تعذّر إنشاء الصورة'), bad: true);
        return;
      }
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: caption),
      );
    } catch (e) {
      debugPrint('IslamicBackgroundsScreen.share error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setWallpaper() async {
    if (_busy) return;
    final target = await _pickWallpaperTarget();
    if (target == null) return;
    setState(() => _busy = true);
    try {
      final file = await _capture();
      if (file == null) {
        if (!mounted) return;
        _toast(_tr('islamic_backgrounds.failed', 'تعذّر إنشاء الصورة'), bad: true);
        return;
      }
      final ok = await WallpaperService.setFromFile(file.path, target);
      if (!mounted) return;
      _toast(
        ok
            ? _tr('islamic_backgrounds.wallpaper_set', 'تم تعيين الخلفية')
            : _tr(
                'islamic_backgrounds.wallpaper_failed',
                'تعذّر تعيين الخلفية',
              ),
        bad: !ok,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<WallpaperTarget?> _pickWallpaperTarget() {
    final theme = Theme.of(context);
    return showModalBottomSheet<WallpaperTarget>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(
                _tr('islamic_backgrounds.wallpaper_home', 'الشاشة الرئيسية'),
              ),
              onTap: () => Navigator.pop(ctx, WallpaperTarget.home),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(
                _tr('islamic_backgrounds.wallpaper_lock', 'شاشة القفل'),
              ),
              onTap: () => Navigator.pop(ctx, WallpaperTarget.lock),
            ),
            ListTile(
              leading: const Icon(Icons.smartphone_outlined),
              title: Text(_tr('islamic_backgrounds.wallpaper_both', 'كلاهما')),
              onTap: () => Navigator.pop(ctx, WallpaperTarget.both),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _caption() {
    final lines = <String>[
      _text,
      if (_reference != null && _reference!.isNotEmpty) _reference!,
      '',
      AppConstants.appName,
      AppConstants.playStoreUrl,
    ];
    return lines.join('\n');
  }

  void _toast(String msg, {bool bad = false}) {
    showFToast(
      context: context,
      title: Text(msg),
      variant: bad ? FToastVariant.destructive : FToastVariant.primary,
    );
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _modernHeader(context, theme),
            Expanded(child: _preview()),
            _sizeControls(theme),
            _toolRow(theme),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 16, bottom: 2),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _tr('islamic_backgrounds.background', 'الخلفية'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            BackgroundPickerBar(
              selected: _background,
              onChanged: _onBackgroundChanged,
            ),
            _actionBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _modernHeader(BuildContext context, ThemeData theme) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final onSurface = theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          // Back button — a soft rounded square.
          Material(
            color: onSurface.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: onSurface.withValues(alpha: 0.08)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.maybePop(context),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                  size: 22,
                  color: onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _tr('islamic_backgrounds.home_title', 'الخلفيات الإسلامية'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _tr(
                    'islamic_backgrounds.subtitle',
                    'صمّم خلفية واجعلها لك',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Trailing gradient badge.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF20497D), Color(0xFF3A6BA8)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF20497D).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.wallpaper_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final byWidth = c.maxWidth / IslamicCanvas.aspectRatio;
            final height = byWidth <= c.maxHeight ? byWidth : c.maxHeight;
            final width = height * IslamicCanvas.aspectRatio;
            return SizedBox(
              width: width,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                // ClipRRect rounds the PREVIEW only; the RepaintBoundary inside
                // captures the square, full-bleed canvas for the wallpaper.
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  // Drag = move text; pinch (or the size slider) = resize.
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: (_) => _scaleGestureStart = _textScale,
                    onScaleUpdate: (details) {
                      setState(() {
                        if (details.pointerCount >= 2) {
                          _textScale = (_scaleGestureStart * details.scale)
                              .clamp(0.4, 3.0);
                        }
                        final dx = details.focalPointDelta.dx / (width / 2);
                        final dy = details.focalPointDelta.dy / (height / 2);
                        _textAlignment = Alignment(
                          (_textAlignment.x + dx).clamp(-1.0, 1.0),
                          (_textAlignment.y + dy).clamp(-1.0, 1.0),
                        );
                      });
                    },
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: IslamicCanvas(
                        background: _background,
                        text: _text,
                        reference: _reference,
                        fontFamily: _fontFamily,
                        imageCacheWidth: _canvasImageWidth,
                        textAlignment: _textAlignment,
                        textScale: _textScale,
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

  Widget _sizeControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _tr(
              'islamic_backgrounds.drag_hint',
              'اسحب النص لتحريكه • قرّب بإصبعين أو استخدم الشريط لتغيير الحجم',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.format_size_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              Expanded(
                child: Slider(
                  value: _textScale,
                  min: 0.4,
                  max: 3.0,
                  onChanged: (v) => setState(() => _textScale = v),
                ),
              ),
              IconButton(
                tooltip: _tr('islamic_backgrounds.reset', 'إعادة'),
                icon: const Icon(Icons.restart_alt_rounded),
                onPressed: () => setState(() {
                  _textAlignment = _defaultTextAlignment;
                  _textScale = 1.0;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: FButton(
              onPress: _busy ? null : _editText,
              variant: FButtonVariant.outline,
              prefix: const Icon(Icons.edit_rounded, size: 18),
              child: Text(_tr('islamic_backgrounds.edit_text', 'تعديل النص')),
            ),
          ),
          const SizedBox(width: 10),
          _fontMenu(theme),
        ],
      ),
    );
  }

  Widget _fontMenu(ThemeData theme) {
    return PopupMenuButton<String>(
      initialValue: _fontFamily,
      onSelected: (f) => setState(() => _fontFamily = f),
      itemBuilder: (_) => [
        for (final (family, label) in _fonts)
          PopupMenuItem<String>(
            value: family,
            child: Text(
              label,
              style: TextStyle(fontFamily: family, fontSize: 18),
            ),
          ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.font_download_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              _tr('islamic_backgrounds.font', 'الخط'),
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (WallpaperService.isSupported)
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF20497D), Color(0xFF3A6BA8)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: InkWell(
                    onTap: _busy ? null : _setWallpaper,
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 52,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_busy)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(
                              Icons.wallpaper_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          const SizedBox(width: 10),
                          Text(
                            _tr(
                              'islamic_backgrounds.set_wallpaper',
                              'تعيين كخلفية',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FButton(
                  onPress: _busy ? null : _save,
                  variant: FButtonVariant.outline,
                  prefix: const Icon(Icons.download_rounded, size: 18),
                  child: Text(
                    _tr('islamic_backgrounds.save', 'حفظ في المعرض'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FButton(
                  onPress: _busy ? null : _share,
                  variant: FButtonVariant.outline,
                  prefix: const Icon(Icons.share_rounded, size: 18),
                  child: Text(
                    _tr('islamic_backgrounds.share', 'مشاركة'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
