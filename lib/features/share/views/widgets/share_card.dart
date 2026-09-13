import 'package:flutter/material.dart';
import 'package:wadhakir/features/share/models/share_background.dart';
import 'package:wadhakir/features/share/views/widgets/share_background_layer.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';

/// Visual brand card used both for the on-screen preview and the PNG that
/// gets shared. Renders a 4:5 vertical card with the brand-blue gradient
/// from the new onboarding palette (intentionally avoids
/// `colorScheme.secondary` which is near-black in this app).
///
/// The widget is intentionally *pixel-deterministic* — it never reads
/// `MediaQuery` or `Theme.colorScheme`, so the on-screen preview and the
/// captured PNG look identical regardless of the host app's theme mode or
/// screen size. The caller drops it into a `RepaintBoundary` and captures
/// it via `RenderRepaintBoundary.toImage`.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.payload});

  final SharePayload payload;

  /// Aspect ratio of the rendered card, from [SharePayload.ratio].
  ///
  /// Was a `static const 4/5` until R4. It is a property now because WhatsApp
  /// Status — the region's dominant broadcast surface — is strictly 9:16, and a
  /// 4:5 card posted there is letterboxed badly enough that people screenshot
  /// the app instead of using its share button.
  double get aspectRatio => payload.ratio.value;

  // Fixed brand palette — same as `_OnboardingPalette` so the share card
  // visually descends from the onboarding flow the user just saw. No
  // theme-derived colors, no near-black.
  static const Color _brandGlow = Color(0xFF7BA7D9);
  static const Color _ink = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final background = payload.background ?? ShareBackground.brand;

    // Passage: content-height card that grows with the text so long entries
    // (e.g. the 40 Hadith) stay readable instead of being shrunk to fit a
    // fixed box. The parent gives it a fixed width; height is intrinsic.
    if (payload.variant == ShareCardVariant.passage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: LayoutBuilder(
          builder: (context, c) {
            // A FLOOR, not a fixed ratio.
            //
            // The passage variant exists so a long entry — one of the 40 Hadith
            // — stays readable instead of being shrunk to fit a box, so it must
            // still grow past this. But a SHORT passage in a content-height card
            // comes out almost square, which is the letterboxing problem the
            // ratio was introduced to solve, just arriving from the other side.
            // The floor makes short passages Status-ready and leaves long ones
            // alone.
            final minHeight = c.maxWidth.isFinite
                ? c.maxWidth / payload.ratio.value
                : 0.0;
            return Stack(
              children: [
                Positioned.fill(
                  child: ShareBackgroundLayer(
                    background: background,
                    imageCacheWidth: 1080,
                  ),
                ),
                // Orbs only over flat backgrounds; photos get the scrim instead.
                if (!background.isImage)
                  const Positioned.fill(child: _DecorativeOrbs()),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: _PassageForeground(payload: payload),
                ),
              ],
            );
          },
        ),
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ShareBackgroundLayer(background: background, imageCacheWidth: 1080),
            if (!background.isImage) const _DecorativeOrbs(),
            if (payload.variant == ShareCardVariant.timetable &&
                payload.timetableRows.isNotEmpty)
              _TimetableForeground(payload: payload)
            else
              _CardForeground(payload: payload),
          ],
        ),
      ),
    );
  }
}

/// Foreground for [ShareCardVariant.timetable]: brand strip, the headline as a
/// title, [SharePayload.reference] as the subhead beneath it, then the rows as
/// an aligned two-column table.
///
/// ## Why a `Table` and not a column of `Row`s
///
/// `Table` sizes each column across *all* its rows, so every time lands on one
/// baseline and every label on another. A list of `Row`s would size each line
/// independently and reproduce exactly the raggedness that made the compact
/// variant wrong for this data in the first place.
///
/// Unlike the other two variants this one draws no [SharePayload.categoryLabel]
/// chip: on a card whose headline is already «مواقيت الصلاة» the category would
/// only repeat the title. The field is still worth setting — the share screen
/// uses it as the system-share *subject*.
class _TimetableForeground extends StatelessWidget {
  const _TimetableForeground({required this.payload});
  final SharePayload payload;

  @override
  Widget build(BuildContext context) {
    final subhead = payload.reference ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 32, 26, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BrandStrip(),
          const SizedBox(height: 20),
          Text(
            payload.headline,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ShareCard._ink,
              fontFamily: 'Almarai',
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.4,
              shadows: [
                Shadow(
                  color: Color(0x40000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          if (subhead.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subhead,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontFamily: 'Almarai',
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ],
          Expanded(
            child: Center(child: _TimetableRows(rows: payload.timetableRows)),
          ),
          const SizedBox(height: 12),
          const _Footer(),
        ],
      ),
    );
  }
}

/// The aligned rows themselves. Scaled down (never up) by a [FittedBox] so a
/// narrow card, or an unusually long label, shrinks the table instead of
/// overflowing it — the same guard `_Headline` uses.
class _TimetableRows extends StatelessWidget {
  const _TimetableRows({required this.rows});
  final List<ShareTimetableRow> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth.isFinite ? c.maxWidth : 360.0;
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Table(
              // RTL, so the first column of each row renders on the right.
              textDirection: TextDirection.rtl,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
                2: IntrinsicColumnWidth(),
              },
              children: [
                for (final row in rows)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Text(
                          row.label,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            color: ShareCard._ink,
                            fontFamily: 'Almarai',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: Color(0x33000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // The leader between label and value. A hairline rather
                      // than a row of dots, because the card already speaks
                      // that language — `_BrandStrip` and the passage divider
                      // are both fading hairlines.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.06),
                                Colors.white.withValues(alpha: 0.34),
                                Colors.white.withValues(alpha: 0.06),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Text(
                          row.value,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: ShareCard._ink,
                            fontFamily: 'Almarai',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            // Digits on a fixed advance width, so the times
                            // form a column instead of drifting row to row.
                            fontFeatures: [FontFeature.tabularFigures()],
                            shadows: [
                              Shadow(
                                color: Color(0x33000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
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
    );
  }
}

/// Foreground for [ShareCardVariant.passage]: brand strip, full (non-shrunk)
/// Arabic text, an optional English block under a divider, reference, footer.
/// Sizes to content height.
class _PassageForeground extends StatelessWidget {
  const _PassageForeground({required this.payload});
  final SharePayload payload;

  @override
  Widget build(BuildContext context) {
    final hasEnglish =
        payload.secondaryText != null && payload.secondaryText!.isNotEmpty;
    final hasReference =
        payload.reference != null && payload.reference!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Centred so a passage shorter than the ratio floor sits in the middle
        // of the card rather than clinging to the top with dead space beneath
        // it. With `MainAxisSize.min` under an incoming minHeight, the column
        // takes the larger of its content and that floor, and this distributes
        // whatever is left over.
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BrandStrip(),
          const SizedBox(height: 22),
          Text(
            payload.headline,
            textAlign: TextAlign.center,
            textDirection: payload.headlineRtl
                ? TextDirection.rtl
                : TextDirection.ltr,
            style: TextStyle(
              color: ShareCard._ink,
              fontFamily: payload.headlineRtl ? 'ScheherazadeNew' : 'Almarai',
              fontSize: payload.headlineRtl ? 23 : 17,
              height: payload.headlineRtl ? 1.95 : 1.6,
              fontWeight: FontWeight.w700,
              shadows: const [
                Shadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          if (hasEnglish) ...[
            const SizedBox(height: 18),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              payload.secondaryText!,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontFamily: 'Almarai',
                fontSize: 14.5,
                height: 1.6,
              ),
            ),
          ],
          if (hasReference) ...[
            const SizedBox(height: 18),
            _ReferenceLine(text: payload.reference!),
          ],
          const SizedBox(height: 22),
          _Footer(
            categoryLabel: payload.categoryLabel,
            repetitions: payload.repetitions,
          ),
        ],
      ),
    );
  }
}

/// Two soft radial halos that pin the eye to the center where the headline
/// sits. Pure visual decoration — no interactivity.
class _DecorativeOrbs extends StatelessWidget {
  const _DecorativeOrbs();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: _orb(220, ShareCard._brandGlow.withValues(alpha: 0.40)),
          ),
          Positioned(
            bottom: -100,
            left: -90,
            child: _orb(240, ShareCard._brandGlow.withValues(alpha: 0.28)),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );
}

/// Foreground: top brand strip, centered Arabic headline, optional
/// chip + category + reference, bottom wordmark + link.
class _CardForeground extends StatelessWidget {
  const _CardForeground({required this.payload});
  final SharePayload payload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BrandStrip(),
          Expanded(
            child: Center(child: _Headline(payload: payload)),
          ),
          if (payload.reference != null && payload.reference!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ReferenceLine(text: payload.reference!),
          ],
          const SizedBox(height: 20),
          _Footer(
            categoryLabel: payload.categoryLabel,
            repetitions: payload.repetitions,
          ),
        ],
      ),
    );
  }
}

/// Top strip — Wadhakir logo (icon only) + a subtle ornament line.
class _BrandStrip extends StatelessWidget {
  const _BrandStrip();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.34),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                // If the asset is missing the share still renders — a
                // generic mosque glyph keeps the card meaningful.
                errorBuilder: (_, _, _) => const Icon(
                  Icons.mosque_rounded,
                  color: ShareCard._ink,
                  size: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 1,
          width: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The dhikr / hadith text. Uses `FittedBox` with `BoxFit.scaleDown` so
/// very long entries shrink rather than overflow, but short entries don't
/// blow up to a comical size — the parent constrains width.
class _Headline extends StatelessWidget {
  const _Headline({required this.payload});
  final SharePayload payload;

  @override
  Widget build(BuildContext context) {
    final rtl = payload.headlineRtl;
    // Pick a starting size by length so long azkar fill the card width and
    // wrap nicely instead of being shrunk to a tiny block. The text wraps to
    // the full available width; FittedBox only scales DOWN if it's still too
    // tall, so it never overflows.
    final len = payload.headline.trim().length;
    final double base = len < 40
        ? 32
        : len < 90
        ? 26
        : len < 160
        ? 21
        : len < 280
        ? 17
        : 14;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: LayoutBuilder(
        builder: (context, c) {
          final maxW = c.maxWidth.isFinite ? c.maxWidth : 360.0;
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Text(
                payload.headline,
                textAlign: TextAlign.center,
                textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(
                  color: ShareCard._ink,
                  fontFamily: rtl ? 'ScheherazadeNew' : 'Almarai',
                  fontSize: base,
                  height: 1.7,
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(
                      color: Color(0x40000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReferenceLine extends StatelessWidget {
  const _ReferenceLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontFamily: 'Almarai',
          fontSize: 11,
          fontStyle: FontStyle.italic,
          height: 1.4,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({this.categoryLabel, this.repetitions});
  final String? categoryLabel;
  final int? repetitions;

  @override
  Widget build(BuildContext context) {
    final hasCategory = categoryLabel != null && categoryLabel!.isNotEmpty;
    final hasReps = repetitions != null && repetitions! > 0;
    return Column(
      children: [
        if (hasCategory || hasReps) ...[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (hasCategory) _Chip(label: '· $categoryLabel ·'),
              if (hasReps) _Chip(label: '×$repetitions', emphasis: true),
            ],
          ),
          const SizedBox(height: 14),
        ],
        SizedBox(
          width: 30,
          height: 30,
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
            // If the asset is missing the share still renders — a generic
            // mosque glyph keeps the card branded.
            errorBuilder: (_, _, _) =>
                const Icon(Icons.mosque_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.emphasis = false});
  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: emphasis ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: emphasis ? 0.55 : 0.30),
          width: 1,
        ),
      ),
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          color: ShareCard._ink,
          fontFamily: 'Almarai',
          fontSize: 12,
          fontWeight: emphasis ? FontWeight.w800 : FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
