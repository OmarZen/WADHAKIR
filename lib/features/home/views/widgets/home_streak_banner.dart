import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_cubit.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_state.dart';
import 'package:wadhakir/features/salah_tracker/services/salah_stats_service.dart';
import 'package:wadhakir/features/salah_tracker/views/screens/salah_tracker_screen.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';

/// What the banner is saying today. The banner has one job — tell the user
/// where they stand with their prayers in a glance — and these are the only
/// four honest answers.
enum _Mood {
  /// Tracking is paused (أيام العذر). Nothing is owed, so nothing is measured.
  paused,

  /// Nothing has ever been logged.
  begin,

  /// There is history, but the last few days are empty — or the 30-day figure
  /// has fallen to nothing. Either way a number would only be a reproach.
  returning,

  /// Normal: show the 30-day steadfastness figure.
  steady,
}

/// Compact, tappable home banner showing **مداومة** — the share of prayers
/// kept over the last 30 days — alongside today's completion ring. Taps
/// through to the full tracker.
///
/// ## Why this is not a streak
///
/// It used to be. A streak is all-or-nothing: miss one Fajr and a gold flame
/// over a large number becomes a grey "0" over "start your streak today". That
/// is the scorekeeper `PRODUCT.md` forbids — it punishes a single lapse
/// exactly as hard as abandoning prayer altogether, and the harder someone has
/// worked the more the reset costs them, which is precisely backwards.
///
/// A 30-day ratio degrades instead of collapsing: one missed day out of thirty
/// moves 100% to 97%, which is the truth. And when even that figure would read
/// as zero the banner stops showing a number at all and says
/// *ما فات يُدرَك* instead — see [_Mood.returning]. The banner has no state in
/// which it reports a nought.
///
/// The celebration on completing a day is deliberately untouched: the change
/// here is to the arithmetic and the vocabulary, not to the moment of finishing.
class HomeStreakBanner extends StatelessWidget {
  const HomeStreakBanner({super.key});

  /// The gold reserved for the steadfastness arc.
  static const Color _accent = Color(0xFFE0B341);

  /// Days without a single logged prayer before the banner switches from
  /// measuring to welcoming.
  ///
  /// Two is a slip — a forgotten evening, a day of travel — and interrupting
  /// someone over it would be nagging. Three consecutive empty days is a real
  /// break in the habit, and the one thing that helps at that point is an open
  /// door rather than an accounting.
  static const int _lapseDays = 3;

  /// The window [SalahStatsService.istiqamah] measures over.
  static const int _window = 30;

  static const SalahStatsService _stats = SalahStatsService();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalahTrackerCubit, SalahTrackerState>(
      builder: (context, state) {
        if (state is! SalahTrackerLoaded) return const SizedBox.shrink();

        final l10n = context.l10n;
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        final ratio = _stats.istiqamah(state.log, state.today, window: _window);
        // Rounded once, here, so the mood test and the rendered figure can
        // never disagree — a banner that says "0%" because the mood check
        // looked at 0.004 and the label rounded it is the exact failure this
        // widget exists to prevent.
        final percent = (ratio * 100).round();
        final sinceLastLog = _stats.daysSinceLastLog(state.log, state.today);
        final mood = _moodFor(
          log: state.log,
          today: state.today,
          percent: percent,
          sinceLastLog: sinceLastLog,
        );

        final title = _title(l10n, mood, percent, isArabic);
        final subtitle = _subtitle(l10n, mood);

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            0,
          ),
          child: Semantics(
            button: true,
            label:
                '${l10n?.translate('salah_tracker.home_title') ?? 'سجل الصلاة'}'
                ' — $title${subtitle == null ? '' : '، $subtitle'}',
            child: FTappable(
              onPress: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalahTrackerScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.md,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      cs.primary,
                      Color.alphaBlend(const Color(0x33000000), cs.primary),
                    ],
                  ),
                  borderRadius: Radii.all(Radii.lg),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _badge(
                      context: context,
                      mood: mood,
                      ratio: ratio,
                      percent: percent,
                      isArabic: isArabic,
                      reduceMotion: reduceMotion,
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: mood == _Mood.steady
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onPrimary.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Today's ring is meaningless while tracking is paused —
                    // no prayers are owed, so "0/5" would be inventing a debt
                    // the pause exists to prevent.
                    if (mood != _Mood.paused) ...[
                      const SizedBox(width: Spacing.sm),
                      _todayRing(
                        context: context,
                        prayed: state.todayPrayedCount,
                        isArabic: isArabic,
                        reduceMotion: reduceMotion,
                      ),
                    ],
                    SizedBox(width: Spacing.xs),
                    Icon(
                      isRtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: cs.onPrimary.withValues(alpha: 0.7),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Picks the honest reading for today.
  ///
  /// Order matters. The pause outranks everything — a paused log is not a
  /// lapsed one, and telling a woman in hayd that she has been away for a week
  /// is the bug أيام العذر was built to fix. After that, an empty log invites,
  /// a lapse welcomes back, and a figure that would render as nought is
  /// treated as a lapse rather than printed.
  static _Mood _moodFor({
    required SalahLogModel log,
    required DateTime today,
    required int percent,
    required int? sinceLastLog,
  }) {
    if (log.isExcusedDay(today)) return _Mood.paused;
    if (sinceLastLog == null) return _Mood.begin;
    if (sinceLastLog >= _lapseDays) return _Mood.returning;
    // Reachable without a lapse: a log full of days marked missed, or a window
    // where every non-excused day was left empty while today was touched.
    if (percent <= 0) return _Mood.returning;
    return _Mood.steady;
  }

  String _title(
    AppLocalizations? l10n,
    _Mood mood,
    int percent,
    bool isArabic,
  ) {
    String t(String key, String fallback) =>
        l10n?.translate('salah_tracker.$key') ?? fallback;
    return switch (mood) {
      _Mood.paused => t('excused_today', 'يوم عذر'),
      _Mood.begin => t('istiqamah_begin', 'ابدأ اليوم — ولو بصلاة واحدة'),
      _Mood.returning => t(
        'welcome_back',
        'ما فات يُدرَك — ابدأ الآن ولو بصلاة',
      ),
      _Mood.steady =>
        '${t('istiqamah', 'المداومة')} ${_percentLabel(percent, isArabic)}',
    };
  }

  String? _subtitle(AppLocalizations? l10n, _Mood mood) {
    String t(String key, String fallback) =>
        l10n?.translate('salah_tracker.$key') ?? fallback;
    return switch (mood) {
      _Mood.steady => t('istiqamah_hint', 'آخر ٣٠ يومًا'),
      // The welcome and the invitation are complete sentences; a second line
      // under either would turn a kind word into a lecture.
      _Mood.paused || _Mood.begin || _Mood.returning => null,
    };
  }

  /// The left-hand badge: an arc of the 30-day figure when there is one, and a
  /// calm icon when there is not.
  Widget _badge({
    required BuildContext context,
    required _Mood mood,
    required double ratio,
    required int percent,
    required bool isArabic,
    required bool reduceMotion,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const size = 46.0;

    if (mood != _Mood.steady) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _accent.withValues(alpha: 0.18),
        ),
        child: Icon(
          // A sunrise rather than an arrow or a chart: the message is that a
          // new day is available, not that a metric needs recovering.
          mood == _Mood.paused
              ? Icons.pause_rounded
              : Icons.wb_twilight_rounded,
          color: _accent,
          size: 24,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: cs.onPrimary.withValues(alpha: 0.22),
                valueColor: const AlwaysStoppedAnimation<Color>(_accent),
              ),
            ),
          ),
          Text(
            _digits(percent, isArabic),
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayRing({
    required BuildContext context,
    required int prayed,
    required bool isArabic,
    required bool reduceMotion,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const total = 5;
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: prayed / total),
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: cs.onPrimary.withValues(alpha: 0.22),
                    valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                  ),
                ),
              ),
              Text(
                '${_digits(prayed, isArabic)}/${_digits(total, isArabic)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n?.translate('salah_tracker.today') ?? 'اليوم',
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onPrimary.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  /// Arabic-Indic digits in Arabic, Western digits in English.
  ///
  /// The banner used to render Arabic-Indic unconditionally, which put ٣/٥
  /// in the middle of an otherwise English screen. The surrounding copy is
  /// already locale-correct — `istiqamah_hint` reads "آخر ٣٠ يومًا" in Arabic
  /// and "Last 30 days" in English — so the numerals should follow it.
  static String _digits(int value, bool isArabic) =>
      isArabic ? WirdFormat.toArabicDigits(value) : '$value';

  static String _percentLabel(int percent, bool isArabic) =>
      isArabic ? '${WirdFormat.toArabicDigits(percent)}٪' : '$percent%';
}
