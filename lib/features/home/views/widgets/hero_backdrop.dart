import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The home hero's ground — roadmap R4's typographic hero.
///
/// ## What this replaces, and why the replacement is safer
///
/// The hero used to be one of eleven mosque photographs behind a scrim that
/// reached 0.75 black at the bottom so white type would read. The scrim had to
/// be that heavy because the ground was *unpredictable*: it had to survive
/// whichever of the eleven photos happened to be showing, including the
/// brightest. A photograph you cannot choose is a contrast problem you cannot
/// solve, only over-correct for.
///
/// Drawing the ground in code removes the variable. Every colour below is
/// fixed, so the contrast against white can be computed once and tested —
/// which is what [contrastWithWhite] and its test exist for. R1 spent a
/// release getting contrast right; this is the one part of the hero that is
/// not allowed to regress quietly.
///
/// ## The typography
///
/// «وَذَكِّرْ» — the app's own name, from الذاريات ٥٥, which already ships in
/// `CuratedQuotes` as the first entry. Set very large, very faint, and clipped
/// by the hero's own bounds, so it reads as a ground rather than as a heading
/// competing with the greeting in front of it.
///
/// ## What goes away with the photos
///
/// A `Timer.periodic` firing every 300 seconds and eleven 1080px image decodes,
/// both on the app's most-visited surface. The eleven WebP files stay in the
/// repo — `ShareBackground.mosquePresets` still offers them as share-card
/// backgrounds, where the user picks the photo and the contrast problem is
/// theirs to see.
class HeroBackdrop extends StatelessWidget {
  const HeroBackdrop({super.key, required this.borderRadius});

  final double borderRadius;

  // ---------------------------------------------------------------- Palette
  //
  // The app's existing deep-blue vocabulary — the same family the share card's
  // CTA, the moon screen's accents and the onboarding palette already use. The
  // contrast figures are white-on-colour, measured by [contrastWithWhite] and
  // pinned by `hero_backdrop_test.dart`.

  /// Top of the gradient. 9.1:1 against white on its own.
  ///
  /// Deliberately not `colorScheme.primary`: the hero has to be legible in
  /// light and dark alike, and a ground that follows the theme would need the
  /// contrast solved twice.
  static const Color skyTop = Color(0xFF20497D);

  /// Bottom of the gradient. 17.5:1 — the deepest point, under the greeting
  /// and the countdown, which is where the densest type sits.
  static const Color skyBottom = Color(0xFF0F1A2A);

  /// The halo colour, from the share card's `_brandGlow`.
  static const Color glow = Color(0xFF7BA7D9);

  /// Alpha for the upper halo — **the number that decides whether this hero is
  /// accessible**, and the brightest point on it.
  ///
  /// `ShareCard._DecorativeOrbs` draws the same halos at 0.40, which is right
  /// over a card carrying one line of type. Copied here it takes the lit region
  /// to 5.2:1 — still WCAG AA, but no longer AAA, on the surface this app opens
  /// to. At 0.15 that point measures 7.4:1. Raise it and the test says so.
  static const double glowAlpha = 0.15;

  /// Alpha for the lower halo. Lower again because it sits at the dark end of
  /// the gradient, under the densest type and behind the wordmark.
  static const double glowAlphaLower = 0.12;

  /// Opacity of the «وَذَكِّرْ» wordmark.
  ///
  /// The binding constraint on this whole palette, and not the halos as you
  /// would expect: white over a lit region costs more contrast than the halo
  /// under it does. Clearing AAA *everywhere* including a hypothetical overlap
  /// of the bright halo and the wordmark would need roughly 0.037, which is
  /// invisible. The layout is what saves it — see [_Wordmark], which sits in
  /// the opposite corner from the bright halo, where the measurement is
  /// 11.6:1.
  static const double wordmarkAlpha = 0.07;

  /// The app's name, from الذاريات ٥٥.
  static const String wordmark = 'وَذَكِّرْ';

  /// WCAG relative luminance of [color], per the sRGB definition.
  ///
  /// Here rather than in a test helper so the widget and its test cannot drift
  /// apart on the formula itself.
  static double relativeLuminance(Color color) {
    double channel(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  /// Contrast ratio of [color] against white — the only foreground this hero
  /// uses.
  static double contrastWithWhite(Color color) =>
      1.05 / (relativeLuminance(color) + 0.05);

  /// [color] composited over [base] at [alpha], the way the painter will.
  static Color over(Color color, Color base, double alpha) => Color.from(
    alpha: 1,
    red: color.r * alpha + base.r * (1 - alpha),
    green: color.g * alpha + base.g * (1 - alpha),
    blue: color.b * alpha + base.b * (1 - alpha),
  );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [skyTop, skyBottom],
                  // Weighted towards the dark end: the greeting, the quote and
                  // the countdown all sit in the lower half.
                  stops: [0.0, 0.85],
                ),
              ),
            ),
            const _Halos(),
            const _Wordmark(),
          ],
        ),
      ),
    );
  }
}

/// The two soft radial halos, the same language `ShareCard._DecorativeOrbs`
/// draws — reusing the app's own way of lifting a flat ground rather than
/// inventing a second one. Drawn at [HeroBackdrop.glowAlpha]; see the note
/// there on why not at the share card's 0.40.
class _Halos extends StatelessWidget {
  const _Halos();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -80,
            child: _orb(230, HeroBackdrop.glowAlpha),
          ),
          Positioned(
            bottom: -130,
            left: -90,
            child: _orb(260, HeroBackdrop.glowAlphaLower),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          HeroBackdrop.glow.withValues(alpha: alpha),
          HeroBackdrop.glow.withValues(alpha: 0),
        ],
      ),
    ),
  );
}

/// «وَذَكِّرْ», set large and faint and allowed to run past the hero's edge.
///
/// Positioned rather than centred, for two reasons. The middle of the hero is
/// where the greeting goes, and a wordmark directly behind a line of white type
/// stops being a ground. And `bottomEnd` in this app's RTL layout is the bottom
/// *left* — the opposite corner from the bright halo, and the darkest part of
/// the gradient. That is not decoration: it is what keeps the one place white
/// type and the wordmark share at 11.6:1 rather than 6.2:1. Moving this to the
/// other corner would need [HeroBackdrop.wordmarkAlpha] revisited.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 8, bottom: 4),
          child: Text(
            HeroBackdrop.wordmark,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            // Never scaled. It is a ground, not content: at 1.6x it would
            // grow past the hero and read as a heading.
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: 'ScheherazadeNew',
              fontSize: 96,
              height: 1.0,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: HeroBackdrop.wordmarkAlpha),
            ),
          ),
        ),
      ),
    );
  }
}
