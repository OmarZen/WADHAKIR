---
name: Wadhakir
description: A serene, Arabic-first Islamic companion — prayer times, Qibla, Azkar, Quran, and worship habit tracking.
colors:
  primary: "#20497D"
  ink: "#0D1122"
  neutral-gray: "#9A9BA8"
  light-gray: "#CECACA"
  bg-light: "#F9F9F9"
  surface-light: "#FFFFFF"
  bg-dark: "#121212"
  surface-dark: "#1E1E1E"
  on-dark: "#FFFFFF"
  on-dark-muted: "#CECACA"
  status-on-time: "#27AE60"
  status-late: "#D98E04"
  status-late-dark: "#F0B429"
  cat-morning: "#3498DB"
  cat-evening: "#8E44AD"
  cat-sleep: "#E74C3C"
  cat-prayer: "#27AE60"
  cat-wakeup: "#16A085"
  cat-mosque: "#D35400"
  cat-maathur: "#7FB069"
  cat-quran: "#DAA520"
  cat-midnight: "#9C27B0"
  cat-last-third: "#3F51B5"
typography:
  display:
    fontFamily: "Almarai, sans-serif"
    fontSize: "32px"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.5px"
  headline:
    fontFamily: "Almarai, sans-serif"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "normal"
  title:
    fontFamily: "Almarai, sans-serif"
    fontSize: "16px"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "normal"
  body:
    fontFamily: "Almarai, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "normal"
  label:
    fontFamily: "Almarai, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "normal"
  religious-display:
    fontFamily: "Jomhuria, serif"
    fontSize: "36px"
    fontWeight: 400
    lineHeight: 1
    letterSpacing: "normal"
  quran:
    fontFamily: "ScheherazadeNew, Aref Ruqaa, serif"
    fontSize: "24px"
    fontWeight: 400
    lineHeight: 1.9
    letterSpacing: "normal"
rounded:
  xs: "6px"
  sm: "10px"
  md: "16px"
  lg: "22px"
  xl: "28px"
  full: "9999px"
spacing:
  xxs: "2px"
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
  xxxl: "48px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface-light}"
    rounded: "{rounded.sm}"
    padding: "14px 20px"
  button-outlined:
    textColor: "{colors.primary}"
    rounded: "{rounded.sm}"
    padding: "14px 20px"
  card:
    backgroundColor: "{colors.surface-light}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "16px"
  feature-tile:
    backgroundColor: "{colors.surface-light}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "14px 8px"
  prayer-card:
    backgroundColor: "{colors.surface-light}"
    rounded: "{rounded.lg}"
    padding: "16px"
  prayer-card-next:
    textColor: "{colors.surface-light}"
    rounded: "{rounded.lg}"
    padding: "16px"
  time-chip:
    rounded: "{rounded.sm}"
    padding: "8px 16px"
---

# Design System: Wadhakir

## 1. Overview

**Creative North Star: "The Blue Hour Companion"**

Wadhakir is colored by the blue hour — the deep, calm light just before Fajr and just after Maghrib, when the sky is brand-blue and the day's worship begins and ends. The whole system reaches for that feeling: serene, trustworthy, and warm, a quiet companion that stays beside the worshipper through every prayer of the day rather than a tool that demands attention. The primary blue (`#20497D`) and its near-black ink (`#0D1122`) carry that twilight throughout — on the app bar, on the active prayer, on every primary action — so the brand is *felt* on every screen, never merely applied.

It is **Arabic-first by construction**, not by translation. Layout is designed RTL first and mirrored to LTR; the UI runs on Almarai, while a small family of calligraphic Arabic faces (Jomhuria for religious display titles, Scheherazade New / Aref Ruqaa for Quran and supplication text) carries the heritage. Density is calm: generous breathing room, rounded surfaces, soft ambient depth, and one reserved colored glow that marks only what matters *now* — the next prayer, the active state.

This system explicitly rejects four things. It is **not cluttered Islamic-app kitsch** (no gold filigree, no mosque-photo gradients on everything, no neon green). It is **not a corporate SaaS dashboard** (no KPI cards, no hero-metric template, no enterprise gray). It is **not a generic un-themed Material app** (no default purple, no stock-component anonymity). And it is **not childish or gamified** (no confetti, no mascots, no reward theatrics around acts of worship). Restraint is the differentiator; reverence is the point.

**Key Characteristics:**
- Twilight-blue identity carried by one committed primary, felt on every screen.
- Arabic-first RTL layout with a dedicated calligraphic display tier for religious text.
- Calm density — rounded surfaces, soft ambient depth, one reserved accent glow.
- A category-color system that lets feature screens differentiate without breaking the calm.
- Warmth and encouragement expressed through copy and gentle motion, never gamification.

## 2. Colors

A committed twilight-blue identity over near-white (light) or true-dark (dark) surfaces, with a disciplined category palette reserved for content differentiation.

### Primary
- **Twilight Blue** (`#20497D`): The brand. Carries the app bar, primary buttons, the active/next prayer card, selection, icons, and every primary action. This is the color the whole app is tuned to; it appears on every screen.
- **Midnight Ink** (`#0D1122`): The deep near-black companion to the primary — primary body text on light surfaces, the `primaryColorDark`, and dividers in dark mode. The bottom of the blue hour.

### Secondary
- **Companion Gray** (`#9A9BA8`): A medium neutral for tertiary roles and secondary text. **Caution:** at `#9A9BA8` on `#F9F9F9`/white this fails WCAG AA for body text (~2.6:1); use Midnight Ink at reduced opacity for secondary text instead (see Do's & Don'ts).

### Neutral
- **Cloud** (`#F9F9F9`): Light-mode scaffold background. A true near-white, not a warm cream — the calm is cool, not cozy.
- **Surface White** (`#FFFFFF`): Light-mode cards and elevated surfaces.
- **Light Gray** (`#CECACA`): Light-mode dividers, disabled states, hairline borders.
- **Carbon** (`#121212`) / **Slate Surface** (`#1E1E1E`): Dark-mode background and card surfaces.
- **On-Dark** (`#FFFFFF`) / **On-Dark Muted** (`#CECACA`): Dark-mode primary and secondary text.

### Tertiary — The Category Palette
A fixed set of feature/category accents, each with a brighter dark-mode sibling. Used to color an azkar category, a home-grid context, or a prayer card — **one accent per surface**, never as decoration across the chrome.
- **Morning** `#3498DB` · **Evening** `#8E44AD` · **Sleep** `#E74C3C` · **Prayer** `#27AE60` · **Wake** `#16A085` · **Mosque** `#D35400` · **Ma'thur Du'a** `#7FB069` · **Quran Du'a** `#DAA520` · **Midnight** `#9C27B0` · **Last Third** `#3F51B5`.
- **Status colors** (Salah tracker): On-time = Prayer Green `#27AE60`, Late = Amber `#D98E04` (light) / `#F0B429` (dark), Make-up (qada) = Primary blue, Missed = error red, Not-logged = `onSurface @ 35%`.

### Named Rules
**The One Glow Rule.** Saturated color fill and the colored shadow-glow are reserved for the single most important element on a surface — the *next* prayer, the *active* state, the primary CTA. Everywhere else, color appears only as a low-alpha tint (an icon chip at 12%, a hairline border at 16%). The accent's rarity is what makes it read as "now."

**The Cool-Calm Rule.** The light background is a cool near-white (`#F9F9F9`), never a warm cream/sand/beige. Warmth in Wadhakir comes from copy, typography, and the gold Quran accent — never from a tinted body background.

## 3. Typography

**UI Font:** Almarai (Arabic + Latin sans, fallback `sans-serif`)
**Religious Display Font:** Jomhuria (Arabic display, fallback `serif`) — app-bar titles and worship headings
**Quran / Supplication Font:** Scheherazade New & Aref Ruqaa (classical naskh / ruqʿah, fallback `serif`)

**Character:** One workhorse Arabic sans (Almarai) carries the entire interface — headings, labels, buttons, body, data — for a clean, modern, unified voice. Against it, a calligraphic tier appears *only* for sacred and ceremonial text, so the heritage reads as deliberate reverence rather than decoration. The pairing is a true contrast axis: humanist sans vs. classical Arabic calligraphy, never two similar faces.

### Hierarchy
- **Display** (Almarai 700, 32/28px, lh ~1.1, ls −0.5px): Screen-level headings and large titles.
- **Headline** (Almarai 700, 20px, lh 1.2): Section headers, sheet titles.
- **Title** (Almarai 700, 16px): Card titles, list-row leads, emphasized labels.
- **Body** (Almarai 400, 16px, lh 1.5): Primary reading text. Cap prose at 65–75ch.
- **Label / Secondary** (Almarai 400, 14px, lh 1.5): Captions, secondary metadata, helper text.
- **Religious Display** (Jomhuria 400/600, ~36px, lh 1): App-bar wordmark and worship-screen titles — the ceremonial voice.
- **Quran** (Scheherazade New / Aref Ruqaa 400, ≥24px, lh ~1.9): Quran ayat and ma'thur supplications only, with generous line height for diacritics.

### Named Rules
**The Sacred-Type Rule.** Calligraphic faces (Jomhuria, Scheherazade, Aref Ruqaa) are for sacred and ceremonial text *only*. Never set buttons, form labels, data, or UI chrome in a display face — that is the kitsch trap. UI is always Almarai.

**The Arabic-First Rule.** Every screen is laid out RTL first and verified in both directions. Arabic shaping, ligatures, and diacritic spacing are correctness requirements, not nice-to-haves; numerals and Latin labels are mixed bidi-correctly.

## 4. Elevation

Soft and tonal, not heavy. Surfaces rest on faint ambient shadows and tinted hairline borders rather than hard drop shadows; depth is conveyed mostly through rounding and low-alpha tint layering. The one exception is the **active accent glow**: the *next* prayer card lifts on a colored shadow (the accent at ~35% alpha, large blur, downward offset, negative spread) so it reads as gently illuminated from within — the lantern in the blue hour.

### Shadow Vocabulary
- **Ambient rest** (`box-shadow: 0 2px ~8px rgba(0,0,0,0.05)`; card elevation 2): The default for cards and tiles. Barely-there, just enough to separate surface from background.
- **Accent glow** (`box-shadow: 0 8px 15px -4px {accent} @ 35%`): Reserved for the active/next element only. Colored, never neutral.
- **Dark-mode depth** (`shadow rgba(0,0,0,0.4)`, card elevation 3): Slightly deeper in dark mode where ambient contrast is lower.

### Named Rules
**The Soft-Rest Rule.** Surfaces are nearly flat at rest (ambient shadow ≤ 5% black). Real elevation — colored glow, raised lift — appears only on the active state. If a card looks like it's floating at rest, the shadow is too strong.

## 5. Components

Built on a layered stack: Material `ThemeData` is the source of truth; forui (`FThemeData`) is derived from the same `ColorScheme` so forui components track brand colors and light/dark automatically. Press semantics use forui's `FTappable`; the Quran reader and Syncfusion pickers stay on Material.

**Token note.** The canonical radius scale is `core/design/Radii` (xs 6 / sm 10 / md 16 / lg 22 / xl 28 / pill) and spacing is `core/design/Spacing` (2 / 4 / 8 / 12 / 16 / 24 / 32 / 48 on a 4/8 rhythm). New surfaces use these tokens (e.g. the Salah tracker cards at `md`). A few legacy surfaces predate the scale and carry inline radii — buttons at 12px, feature tiles at 18px, prayer cards at 20px — and should migrate to the nearest token. Touch targets are **44×44 minimum**.

### Buttons
- **Shape:** Gently rounded (12px radius).
- **Primary:** Twilight Blue fill, white text, padding 14×20px, elevation 2. The default action.
- **Outlined:** 1.5px primary border, primary text, transparent fill, same radius and padding. Secondary action.
- **Hover / Focus / Press:** `FTappable` press feedback; ink splashes tinted with the surface accent (white on filled, accent at ~10% on light).

### Cards & Tiles
- **Card** — Corner 16px, white (`#FFFFFF`) / slate (`#1E1E1E`) surface, ambient-rest shadow, internal padding ~16px. The general container.
- **Feature tile** (home grid) — Corner 18px, surface fill, **tinted hairline border** (`primary @ 16%`), a circular tinted icon chip on top (`primary @ 12% light / 22% dark`) over a centered 2-line label. Vertical layout for a scannable 3-column grid. Optional corner badge for progress.
- **Prayer card** — Corner 20px. *Default:* white fill, 1px hairline border, ambient shadow. *Next/active:* accent fill (~98% alpha), 2px accent border, accent glow, a faint Islamic geometric pattern overlay at 8%, and a "next" pill badge. This default↔active duality is the signature pattern.

### Chips & Badges
- **Style:** Pill-shaped (`full` radius), low-alpha tinted background, compact padding (≈4×12px).
- **Status chip** (Salah tracker): icon + label colored by status — on-time green, late amber, qada blue, missed red, not-logged muted. One consistent vocabulary across the today rows, status sheet, make-up section, and prayer card.

### Inputs / Fields
- Forui field vocabulary derived from the brand `ColorScheme`: tinted secondary surfaces (`primary @ 8% light / 18% dark`), muted borders (`onSurface @ 12–16%`), 12px radius to match buttons. Keep one form-control vocabulary across the app.

### Navigation
- **App bar:** Twilight-Blue background, white foreground, centered title set in Jomhuria at ~36px (the religious-display voice), zero elevation, edge-to-edge transparent system bars with light icons. This is the most recognizable brand surface — keep it consistent.

### Signature: The Islamic Pattern Overlay
A low-opacity (~8%) geometric `CustomPaint` lattice used *behind* hero/active surfaces (the next-prayer card). It signals heritage without clutter precisely because it stays faint and reserved — never a full-bleed busy background.

## 6. Do's and Don'ts

### Do:
- **Do** carry the Twilight Blue (`#20497D`) onto every screen — app bar, primary action, or active state — so the brand is felt, not just declared.
- **Do** reserve saturated color fill and the colored glow for the single most important element on a surface (the One Glow Rule). Everywhere else, tint at 8–22% alpha.
- **Do** use a cool near-white (`#F9F9F9`) for light backgrounds; let warmth come from copy, typography, and the gold Quran accent.
- **Do** keep all UI chrome in Almarai; reserve Jomhuria / Scheherazade / Aref Ruqaa for sacred and ceremonial text only.
- **Do** design RTL-first and verify both directions, including Arabic shaping, ligatures, and bidi numeral mixing.
- **Do** use Midnight Ink at reduced opacity (e.g. `onSurface @ 60%`) for secondary text so it stays ≥4.5:1 and readable in sunlight.
- **Do** keep one component vocabulary — same button shape, same status-chip colors, same card radii — across every feature.

### Don't:
- **Don't** ship cluttered Islamic-app kitsch: no gold filigree, no mosque-photo gradients layered on chrome, no neon green, no ornament for ornament's sake. The pattern overlay stays ≤8% and reserved.
- **Don't** build a corporate SaaS dashboard: no KPI/hero-metric cards, no charts-first layouts, no enterprise gray. Worship is not a metrics funnel.
- **Don't** look like a generic un-themed Material app: no default purple, no stock components without the brand blue and Arabic type present.
- **Don't** go childish or gamified: no confetti, no mascots, no reward theatrics. Encouragement stays dignified (the companion, not the scoreboard).
- **Don't** use Companion Gray (`#9A9BA8`) for body or secondary text on light backgrounds — it fails AA (~2.6:1). It is a borders/disabled/icon neutral only.
- **Don't** let surfaces float at rest — ambient shadow stays ≤5% black; real elevation is the active state's job.
- **Don't** set display/calligraphic faces in buttons, labels, data, or any UI chrome.
