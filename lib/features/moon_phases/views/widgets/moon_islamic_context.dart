import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

import '../../data/moon_phase.dart';

/// Religious + observational content shown on the moon detail screen.
///
/// Two public widgets:
///   * [MoonIslamicContext] — three calm card sections covering the moon
///     as a sign of Allah, the miracle of the moon-splitting, and the
///     lunar calendar's role in Islam.
///   * [CrescentSightingCard] — practical hilāl-sighting tips, shown only
///     for phases where sighting matters (new moon + waxing crescent).
///
/// Both keep the existing night-sky aesthetic (white-on-dark text on the
/// detail screen's `#0F1A2A` background) but pin every accent to the
/// brand-blue palette — `colorScheme.secondary` (`#0D1122`, near-black)
/// is intentionally never read.

class MoonIslamicContext extends StatelessWidget {
  const MoonIslamicContext({super.key, required this.l10n});

  final AppLocalizations? l10n;

  static const Color _brandAccent = Color(0xFF3A6BA8);
  static const Color _brandGlow = Color(0xFF7BA7D9);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            label:
                l10n?.translate('moon_phases.islamic_section_title') ??
                'القمر في الإسلام',
          ),
          const SizedBox(height: Spacing.md),
          _VerseCard(
            arabicVerse:
                'هُوَ ٱلَّذِى جَعَلَ ٱلشَّمْسَ ضِيَآءًۭ وَٱلْقَمَرَ نُورًۭا '
                'وَقَدَّرَهُۥ مَنَازِلَ لِتَعْلَمُوا۟ عَدَدَ ٱلسِّنِينَ '
                'وَٱلْحِسَابَ',
            reference:
                l10n?.translate('moon_phases.verse_yunus_ref') ??
                'سورة يونس · الآية 5',
            commentary:
                l10n?.translate('moon_phases.verse_yunus_explain') ??
                'القمر آية من آيات الله، جعله نوراً وقدّر له منازل '
                    'يستدلّ بها الناس على عدد السنين وحساب الأوقات.',
          ),
          const SizedBox(height: Spacing.md),
          _VerseCard(
            arabicVerse: 'ٱقْتَرَبَتِ ٱلسَّاعَةُ وَٱنشَقَّ ٱلْقَمَرُ',
            reference:
                l10n?.translate('moon_phases.verse_qamar_ref') ??
                'سورة القمر · الآية 1',
            badge:
                l10n?.translate('moon_phases.splitting_badge') ??
                'انشقاق القمر',
            commentary:
                l10n?.translate('moon_phases.splitting_explain') ??
                'انشقاق القمر معجزة ظاهرة للنبي ﷺ، رآها أهل مكة وانشطر '
                    'القمر فلقتين ثم التأم. رواها البخاري ومسلم عن أنس وابن '
                    'مسعود وابن عباس رضي الله عنهم. وهي دليل على صدق رسالته '
                    '— وعلامة من علامات اقتراب الساعة.',
          ),
          const SizedBox(height: Spacing.md),
          _VerseCard(
            arabicVerse:
                'يَسْـَٔلُونَكَ عَنِ ٱلْأَهِلَّةِ ۖ قُلْ هِىَ مَوَٰقِيتُ '
                'لِلنَّاسِ وَٱلْحَجِّ',
            reference:
                l10n?.translate('moon_phases.verse_baqarah_ref') ??
                'سورة البقرة · الآية 189',
            commentary:
                l10n?.translate('moon_phases.verse_baqarah_explain') ??
                'بالأهلّة تُعرف الشهور القمرية: شهر رمضان للصيام، شهور '
                    'الحج، وبه تضبط مواقيت العبادات والمعاملات في حياة '
                    'المسلم.',
          ),
          const SizedBox(height: Spacing.md),
          _ImportanceBullets(l10n: l10n),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                MoonIslamicContext._brandGlow,
                MoonIslamicContext._brandAccent,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Almarai',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Card that frames one Quranic āyah with its reference + a brief
/// commentary. Optional [badge] used when a verse anchors a known event
/// (e.g. "انشقاق القمر").
class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.arabicVerse,
    required this.reference,
    required this.commentary,
    this.badge,
  });

  final String arabicVerse;
  final String reference;
  final String commentary;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MoonIslamicContext._brandAccent.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: MoonIslamicContext._brandAccent.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: MoonIslamicContext._brandGlow.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(
                  color: MoonIslamicContext._brandGlow.withValues(alpha: 0.55),
                ),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: MoonIslamicContext._brandGlow,
                  fontFamily: 'Almarai',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
          // Quranic verse — large, ScheherazadeNew, RTL. Reads as the
          // primary visual element of the card.
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              arabicVerse,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'ScheherazadeNew',
                fontSize: 22,
                height: 1.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Center(
            child: Text(
              reference,
              style: TextStyle(
                color: MoonIslamicContext._brandGlow.withValues(alpha: 0.92),
                fontFamily: 'Almarai',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.10)),
          const SizedBox(height: Spacing.md),
          // Commentary — slightly muted body text, RTL because all
          // commentaries here are Arabic.
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              commentary,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontFamily: 'Almarai',
                fontSize: 13,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bulleted list under the verses summarising why lunar timing matters
/// in Islam — Ramadan, Eid, Hajj, white days, etc. Kept short and
/// declarative so it doesn't compete with the verse cards.
class _ImportanceBullets extends StatelessWidget {
  const _ImportanceBullets({required this.l10n});
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[
      (
        Icons.calendar_month_rounded,
        l10n?.translate('moon_phases.importance_hijri') ??
            'يبدأ الشهر الهجري برؤية الهلال الجديد بعد غروب الشمس.',
      ),
      (
        Icons.restaurant_outlined,
        l10n?.translate('moon_phases.importance_ramadan') ??
            'صيام رمضان وعيد الفطر يحدّدان برؤية هلال شعبان ورمضان وشوال.',
      ),
      (
        Icons.mosque_rounded,
        l10n?.translate('moon_phases.importance_hajj') ??
            'موسم الحج يقع في شهر ذي الحجة، ويعتمد بدؤه على هلاله.',
      ),
      (
        Icons.brightness_high_rounded,
        l10n?.translate('moon_phases.importance_ayyam_al_bid') ??
            'الأيام البيض (13–15) أكثر الليالي إضاءة، يستحب فيها الصيام.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.translate('moon_phases.importance_title') ??
                'لماذا تهمنا منازل القمر',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Almarai',
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: Spacing.md),
          for (int i = 0; i < items.length; i++) ...[
            _Bullet(icon: items[i].$1, text: items[i].$2),
            if (i < items.length - 1) const SizedBox(height: Spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MoonIslamicContext._brandAccent.withValues(alpha: 0.20),
          ),
          child: Icon(icon, size: 14, color: MoonIslamicContext._brandGlow),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontFamily: 'Almarai',
                fontSize: 12.5,
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================ Crescent ===

/// Decides whether the sighting card adds value for the given phase.
/// Returns `true` only for the two phases where the user can actually
/// see (or look for) the hilāl with the naked eye.
bool shouldShowCrescentSighting(MoonPhase phase) {
  return phase == MoonPhase.newMoon || phase == MoonPhase.waxingCrescent;
}

/// Practical observation tips for the new crescent moon. Renders only
/// when [shouldShowCrescentSighting] returns `true` for the current
/// phase. Pure content — no location math; the visibility heuristic is
/// based on moon age, which is already in [MoonPhaseInfo].
class CrescentSightingCard extends StatelessWidget {
  const CrescentSightingCard({
    super.key,
    required this.info,
    required this.l10n,
  });

  final MoonPhaseInfo info;
  final AppLocalizations? l10n;

  /// Naked-eye visibility heuristic. Below ~17 h the crescent is too
  /// young to see at sunset; 17–24 h is hard but possible with optical
  /// aid; > 24 h is the easy regime. Loosely follows the Yallop /
  /// Odeh thresholds without trying to be exact.
  _CrescentVerdict _verdictFor(double ageDays) {
    final ageHours = ageDays * 24.0;
    if (ageHours < 17) return _CrescentVerdict.tooYoung;
    if (ageHours < 24) return _CrescentVerdict.difficult;
    return _CrescentVerdict.easy;
  }

  @override
  Widget build(BuildContext context) {
    final verdict = _verdictFor(info.ageDays);
    final (verdictLabel, verdictColor) = switch (verdict) {
      _CrescentVerdict.tooYoung => (
        l10n?.translate('moon_phases.sighting_verdict_too_young') ??
            'صغير جداً للرؤية',
        const Color(0xFFE0A458),
      ),
      _CrescentVerdict.difficult => (
        l10n?.translate('moon_phases.sighting_verdict_difficult') ??
            'يحتاج سماء صافية',
        const Color(0xFFE3C766),
      ),
      _CrescentVerdict.easy => (
        l10n?.translate('moon_phases.sighting_verdict_easy') ??
            'الرؤية ممكنة بالعين المجردة',
        const Color(0xFF7CD49C),
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MoonIslamicContext._brandAccent.withValues(alpha: 0.22),
              MoonIslamicContext._brandGlow.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: MoonIslamicContext._brandGlow.withValues(alpha: 0.30),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MoonIslamicContext._brandGlow.withValues(
                      alpha: 0.22,
                    ),
                  ),
                  child: const Icon(
                    Icons.nightlight_round,
                    color: MoonIslamicContext._brandGlow,
                    size: 18,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    l10n?.translate('moon_phases.sighting_title') ??
                        'رؤية الهلال',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Almarai',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _VerdictPill(label: verdictLabel, color: verdictColor),
              ],
            ),
            const SizedBox(height: Spacing.md),
            _SightingFact(
              icon: Icons.access_time_rounded,
              label:
                  l10n?.translate('moon_phases.sighting_moon_age') ??
                  'عمر القمر',
              value: _formatMoonAgeHours(info.ageDays, l10n),
            ),
            const SizedBox(height: Spacing.sm),
            _SightingFact(
              icon: Icons.wb_sunny_outlined,
              label: l10n?.translate('moon_phases.sighting_when') ?? 'متى تنظر',
              value:
                  l10n?.translate('moon_phases.sighting_when_value') ??
                  'بعد غروب الشمس مباشرة (وقت المغرب).',
            ),
            const SizedBox(height: Spacing.sm),
            _SightingFact(
              icon: Icons.explore_outlined,
              label:
                  l10n?.translate('moon_phases.sighting_where') ?? 'أين تنظر',
              value:
                  l10n?.translate('moon_phases.sighting_where_value') ??
                  'منخفض في الأفق الغربي حيث غربت الشمس.',
            ),
            const SizedBox(height: Spacing.sm),
            _SightingFact(
              icon: Icons.visibility_outlined,
              label: l10n?.translate('moon_phases.sighting_how') ?? 'كيف تنظر',
              value:
                  l10n?.translate('moon_phases.sighting_how_value') ??
                  'بالعين المجردة في سماء صافية بعيداً عن أضواء المدينة.',
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoonAgeHours(double ageDays, AppLocalizations? l10n) {
    final hours = (ageDays * 24).round();
    final hoursLabel = l10n?.translate('moon_phases.hours') ?? 'ساعة';
    final daysLabel = l10n?.translate('moon_phases.days_label') ?? 'يوم';
    if (hours < 48) return '$hours $hoursLabel';
    final days = (hours / 24).floor();
    final restHours = hours - days * 24;
    return restHours == 0
        ? '$days $daysLabel'
        : '$days $daysLabel · $restHours $hoursLabel';
  }
}

enum _CrescentVerdict { tooYoung, difficult, easy }

class _VerdictPill extends StatelessWidget {
  const _VerdictPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: color.withValues(alpha: 0.50)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontFamily: 'Almarai',
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SightingFact extends StatelessWidget {
  const _SightingFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.72)),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontFamily: 'Almarai',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Almarai',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
