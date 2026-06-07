import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/utils/widget_to_image.dart';
import 'package:wadhakir/features/share/models/share_background.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';
import 'package:wadhakir/features/share/views/widgets/background_picker_bar.dart';
import 'package:wadhakir/features/share/views/widgets/share_background_layer.dart';
import 'package:wadhakir/features/share/views/widgets/share_card.dart';

/// Full-screen preview for the branded share-image flow.
///
/// Flow:
/// 1. Caller routes here via `AppConstants.shareRoute` with a `SharePayload`
///    as `arguments`.
/// 2. The screen renders a live `ShareCard` preview inside a
///    `RepaintBoundary` so we can capture it as a PNG on demand.
/// 3. User picks one of three actions: share-as-image (primary), share
///    text-only (fallback if image generation fails or the user prefers
///    text), or copy text to clipboard.
///
/// Both the on-screen preview and the captured PNG render from the SAME
/// widget instance — there is no second "off-screen" tree to keep in sync.
class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key, required this.payload});

  final SharePayload payload;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  /// Used to locate the RepaintBoundary in the render tree when we capture
  /// the PNG. Must wrap exactly one render object.
  final GlobalKey _boundaryKey = GlobalKey();

  /// True while we're capturing the PNG and waiting for the system share
  /// sheet to dismiss. Disables buttons so the user can't trigger a second
  /// capture mid-flight.
  bool _isSharing = false;

  /// User-chosen card background (gradient preset / color / mosque photo /
  /// own photo). Seeded from the payload's background or the brand default.
  late ShareBackground _background;

  /// Completes when the current background's image is decoded into the cache,
  /// so the capture isn't blank/stale. No-op for gradient/color backgrounds.
  Future<void> _bgReady = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _background = widget.payload.background ?? ShareBackground.brand;
  }

  void _onBackgroundChanged(ShareBackground background) {
    setState(() => _background = background);
    _bgReady = ShareBackgroundLayer.precache(background, context, width: 1080);
  }

  /// The payload actually rendered/captured — the caller's payload with the
  /// currently-selected background applied.
  SharePayload get _payload => widget.payload.withBackground(_background);

  // --------------------------------------------------------------- Actions

  Future<void> _shareImage() async {
    if (_isSharing) return;
    // Snapshot everything that depends on BuildContext BEFORE the first
    // await — analyzer (rightly) flags reading context across async gaps.
    final caption = _caption();
    final subject = widget.payload.categoryLabel;
    final failureMsg = _tr(
      'azkar.share_image_failed',
      'Could not generate image. Sharing as text instead.',
    );
    setState(() => _isSharing = true);
    try {
      final file = await _captureCardToFile();
      if (file == null) {
        if (!mounted) return;
        _showSnack(failureMsg, destructive: true);
        await _shareTextOnlyWith(caption, subject, silent: true);
        return;
      }
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: caption, subject: subject),
      );
    } catch (e, st) {
      debugPrint('ShareScreen.shareImage error: $e\n$st');
      if (!mounted) return;
      _showSnack(failureMsg, destructive: true);
      await _shareTextOnlyWith(caption, subject, silent: true);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareTextOnly() async {
    if (_isSharing) return;
    final caption = _caption();
    final subject = widget.payload.categoryLabel;
    setState(() => _isSharing = true);
    try {
      await _shareTextOnlyWith(caption, subject, silent: true);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  /// Inner text-share that takes the pre-resolved caption + subject so it
  /// can be called from inside another async flow (e.g. as the image-share
  /// fallback) without re-reading BuildContext.
  Future<void> _shareTextOnlyWith(
    String caption,
    String? subject, {
    bool silent = false,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: caption, subject: subject),
      );
    } catch (e, st) {
      debugPrint('ShareScreen.shareText error: $e\n$st');
    }
  }

  Future<void> _copyText() async {
    final caption = _caption();
    final copiedMsg = _tr('azkar.text_copied', 'Copied');
    await Clipboard.setData(ClipboardData(text: caption));
    if (!mounted) return;
    _showSnack(copiedMsg);
  }

  // --------------------------------------------------------------- Helpers

  /// Captures the `ShareCard` to a PNG in the temporary directory. Uses
  /// `pixelRatio: 3.0` so the image is sharp on high-DPI receivers (e.g.
  /// WhatsApp previews on a retina screen).
  ///
  /// Returns `null` on any failure — caller falls back to text share.
  Future<File?> _captureCardToFile() async {
    // Make sure a freshly-chosen photo background is decoded before capture,
    // otherwise the PNG can be blank or show the previous photo.
    await _bgReady;
    if (!mounted) return null;
    return captureBoundaryToPngFile(
      _boundaryKey,
      pixelRatio: 3.0,
      prefix: 'wadhakir-share',
    );
  }

  /// Compose the full caption used by both the image and text share. The
  /// caller can override via `payload.captionOverride`; otherwise we build
  /// "headline\n\nfrom {category} · Wadhakir\nplay store url".
  String _caption() {
    final p = widget.payload;
    if (p.captionOverride != null && p.captionOverride!.isNotEmpty) {
      return p.captionOverride!;
    }
    final lines = <String>[p.headline];
    if (p.secondaryText != null && p.secondaryText!.isNotEmpty) {
      lines.add('');
      lines.add(p.secondaryText!);
    }
    if (p.reference != null && p.reference!.isNotEmpty) {
      lines.add(p.reference!);
    }
    if (p.categoryLabel != null && p.categoryLabel!.isNotEmpty) {
      final from = _tr('azkar.from', 'from');
      lines.add('');
      lines.add('$from ${p.categoryLabel} · ${AppConstants.appName}');
    } else {
      lines.add('');
      lines.add(AppConstants.appName);
    }
    lines.add(AppConstants.playStoreUrl);
    return lines.join('\n');
  }

  String _tr(String key, String fallback) =>
      AppLocalizations.of(context)?.translate(key) ?? fallback;

  void _showSnack(String msg, {bool destructive = false}) {
    showFToast(
      context: context,
      title: Text(msg),
      variant: destructive ? FToastVariant.destructive : FToastVariant.primary,
    );
  }

  /// The capture target. Compact cards are sized to the fixed 4:5 ratio;
  /// passage cards are given a fixed width and grow to content height inside
  /// a scroll view (the RepaintBoundary still captures the FULL card, even
  /// the parts scrolled out of view).
  Widget _buildPreview() {
    if (widget.payload.variant == ShareCardVariant.passage) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: RepaintBoundary(
              key: _boundaryKey,
              child: ShareCard(payload: _payload),
            ),
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
        child: LayoutBuilder(
          builder: (context, c) {
            final maxW = c.maxWidth;
            final maxH = c.maxHeight;
            final byWidth = maxW / ShareCard.aspectRatio;
            final height = byWidth <= maxH ? byWidth : maxH;
            final width = height * ShareCard.aspectRatio;
            return SizedBox(
              width: width,
              height: height,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: ShareCard(payload: _payload),
              ),
            );
          },
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- Build

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1A2A)
          : const Color(0xFFEEF3FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        title: Text(
          _tr('azkar.share_preview_title', 'Share'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildPreview()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Row(
                children: [
                  Icon(
                    Icons.wallpaper_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _tr('islamic_backgrounds.background', 'Background'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            BackgroundPickerBar(
              selected: _background,
              onChanged: _onBackgroundChanged,
            ),
            _ActionBar(
              isSharing: _isSharing,
              shareImageLabel: _tr('azkar.share_as_image', 'Share as image'),
              shareTextLabel: _tr('azkar.share_text_only', 'Share text only'),
              copyLabel: _tr('azkar.share_copy', 'Copy text'),
              onShareImage: _shareImage,
              onShareText: () => _shareTextOnly(),
              onCopy: _copyText,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isSharing,
    required this.shareImageLabel,
    required this.shareTextLabel,
    required this.copyLabel,
    required this.onShareImage,
    required this.onShareText,
    required this.onCopy,
  });

  final bool isSharing;
  final String shareImageLabel;
  final String shareTextLabel;
  final String copyLabel;
  final VoidCallback onShareImage;
  final VoidCallback onShareText;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary CTA — gradient pill that matches the onboarding CTA
          // style so the brand language is consistent.
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
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x4D20497D),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: isSharing ? null : onShareImage,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.white.withValues(alpha: 0.18),
                  child: SizedBox(
                    height: 54,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSharing)
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
                            Icons.image_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        const SizedBox(width: 10),
                        Text(
                          shareImageLabel,
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
                  onPress: isSharing ? null : onShareText,
                  variant: FButtonVariant.outline,
                  prefix: const Icon(Icons.text_snippet_outlined, size: 18),
                  child: Text(shareTextLabel, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FButton(
                  onPress: isSharing ? null : onCopy,
                  variant: FButtonVariant.outline,
                  prefix: const Icon(Icons.copy_rounded, size: 18),
                  child: Text(copyLabel, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
