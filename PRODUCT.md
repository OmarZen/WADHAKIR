# Product

## Register

product

## Users

Muslims of all ages who want their daily faith practice supported by one trustworthy app — not a scattering of single-purpose tools. The primary audience is **Arabic-first** (Arabic is the default UI language; English is the secondary locale), spanning younger, phone-native users through to older users who rely on large, legible text.

Context of use is woven through an ordinary day, often in non-ideal conditions: glancing at prayer times **outdoors in bright sunlight**, opening Qibla in an unfamiliar place, reading Azkar in the morning and before sleep, reaching for the Quran or a dhikr counter in a spare moment, building a consistent salah and wird habit over weeks. Sessions are usually short, frequent, and intentional.

The job to be done: *"Help me keep up my worship — accurately, calmly, and without friction — wherever I am."*

## Product Purpose

Wadhakir is a complete Islamic companion: prayer times with notification scheduling, Qibla (compass + AR camera overlay), Azkar and after-prayer adhkar, Quran reading, Islamic radio, tasbih/dhikr counter, Zakat calculator, a Salah tracker and Wird (reading-pace) progress, daily verse/dua inspiration, shareable Islamic backgrounds, home-screen widgets, and app-lock around prayer windows.

It exists to consolidate the daily worship toolkit into one coherent, Arabic-first experience that users trust enough to return to every day. Success looks like **a durable daily habit**: the app earns a place on the home screen and a glance at every prayer, because it is accurate, calm to use, and respectful of the act of worship it serves — never a chore, never a distraction.

## Brand Personality

**Serene, rooted, and modern — a warm companion for worship.**

- **Serene & reverent** — the app is a quiet space. Generous breathing room, soft motion, nothing that shouts. The mood respects what the user is doing.
- **Rooted & authentic** — grounded in Islamic tradition through considered Arabic and calligraphic typography (Almarai for UI, Jomhuria / Scheherazade / Aref Ruqaa for religious display) and restrained, meaningful ornament. Heritage signals trust.
- **Modern & clean** — crisp, contemporary, uncluttered; a well-built 2026 app, not a dated Islamic-app cliché. Craft is how the tradition is shown respect.
- **Warm & encouraging** — a gentle companion that supports consistency (streaks, trackers, nudges) with kindness and never with guilt or pressure.

Voice: calm, sincere, plainspoken. Encourages, never lectures. Arabic copy is primary and must read naturally, not as a translation of English.

## Anti-references

Wadhakir should explicitly NOT look or feel like:

- **Cluttered Islamic-app kitsch** — no busy gold filigree, mosque-photo gradients layered on everything, neon-green chrome, or ornament for ornament's sake. Restraint is the differentiator.
- **A corporate SaaS dashboard** — no cold fintech/analytics aesthetic, KPI/hero-metric cards, charts-first layouts, or soulless enterprise gray. Worship is not a metrics funnel.
- **A generic, un-themed Material app** — no default purple, stock components, or absence of a point of view. The brand blue and Arabic typography must be felt on every screen.
- **Childish or gamified** — no cartoon mascots, confetti, loud playful color, or reward-theatrics that cheapen the seriousness of worship. Encouragement stays dignified.

## Design Principles

1. **Reverence over decoration.** The content — an ayah, a dhikr, the next prayer, the Qibla — is always the hero. Ornament and chrome earn their place or get cut. When in doubt, remove.
2. **A companion, not a scorekeeper.** Trackers, streaks, and reminders exist to encourage consistency with warmth. Never guilt, never pressure, never game-show reward theatrics around acts of worship.
3. **Arabic-first, truly.** RTL layout and correct Arabic/Quranic shaping are first-class, not retrofitted. Every screen is designed in Arabic first and verified in both directions; calligraphic display type is used with intent.
4. **Calm by default.** Serene pacing, restrained and optional motion, generous spacing. The app lowers the user's temperature rather than raising it.
5. **Trustworthy and legible in the real world.** Accuracy (times, Qibla, Hijri dates) and readability under real conditions — bright outdoor light, large-text users — are non-negotiable. Contrast and clarity beat elegance-by-fading.

## Accessibility & Inclusion

Target **WCAG 2.1 AA** for contrast and touch targets as the working baseline.

Priority needs for this audience:

- **Arabic / RTL correctness (top priority).** Flawless RTL layout mirroring, correct Arabic letter shaping and ligatures, and proper rendering of Quranic/calligraphic fonts. Bidi-correct mixing of Arabic text with Latin numerals/labels.
- **Outdoor / high-contrast readability.** Body and secondary text must hit ≥4.5:1 against their backgrounds so prayer times and Azkar stay legible in direct sunlight. No light-gray-for-elegance body text; favor the ink end of the ramp. (The current `bodyMedium` muted gray `#9A9BA8` on light/white is a known contrast risk to revisit.)
- **Respects system text scaling** for elder-friendly sizing where feasible, and honors light/dark mode (both themes are first-class).
- **Reduced motion** as a courtesy: animation should be calm and never required to operate the app.
