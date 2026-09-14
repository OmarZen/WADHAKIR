import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/backup/services/backup_keys.dart';
import 'package:wadhakir/features/backup/services/backup_service.dart';

/// Renders a [BackupSummary] as the short list of things a person would
/// recognise: how many days of prayer, whether there is a khatma plan, how
/// many dhikr counters, and which groups of settings travelled.
///
/// Used in three places — the export preview, and both columns of the restore
/// confirmation — so the file and the device are always described in the same
/// words. If they were described differently the user would have to work out
/// whether a wording difference meant a data difference.
class BackupSummaryList extends StatelessWidget {
  final BackupSummary summary;

  /// Dims the rows. Used for the "on this device now" column of the restore
  /// confirmation, which is about to be replaced.
  final bool muted;

  /// Changes the empty message from "there is nothing to save yet" — right on
  /// the export screen — to "there is nothing on this device", which is what
  /// the restore confirmation is actually reporting. The export wording there
  /// would be answering a question nobody asked.
  final bool emptyIsDevice;

  const BackupSummaryList({
    required this.summary,
    this.muted = false,
    this.emptyIsDevice = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rows = _rows(l10n);

    if (rows.isEmpty) {
      final key = emptyIsDevice
          ? 'backup.nothing_on_device'
          : 'backup.nothing_yet';
      final fallback = emptyIsDevice
          ? 'لا توجد بيانات على هذا الجهاز.'
          : 'لا توجد بيانات لحفظها بعد.';
      return Text(
        l10n?.translate(key) ?? fallback,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // Nudged down so the dot sits on the first line's baseline
                  // rather than its cap height, which reads as misaligned once
                  // a row wraps to two lines.
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.circle,
                    size: 5,
                    color: theme.colorScheme.primary.withValues(
                      alpha: muted ? 0.35 : 0.7,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: muted
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// The rows, in the order a person cares about them: the irreplaceable
  /// worship records first, settings last.
  List<String> _rows(AppLocalizations? l10n) {
    String t(String key, String fallback) =>
        l10n?.translate('backup.$key') ?? fallback;

    /// "412 يوم صلاة", but "يوم صلاة واحد" / "1 day of prayer" at one.
    ///
    /// `AppLocalizations.translate` has no interpolation and no plural
    /// support, so the count is composed here. A bare `'$n $noun'` produced
    /// "1 days of prayer" in English, which reads as a bug in a screen whose
    /// entire job is to be trusted about what it is holding. The `_one` keys
    /// carry the complete phrase, number included, so each language can put
    /// the number wherever its grammar wants it.
    ///
    /// Arabic's dual and 3–10 forms are deliberately not modelled: "٤١٢ يوم
    /// صلاة" is the idiomatic register for a UI count and is what Arabic apps
    /// actually ship, while a full CLDR plural table here would be six keys
    /// per noun for a difference nobody reads as wrong.
    String counted(
      int n,
      String key,
      String fallbackMany,
      String fallbackOne,
    ) => n == 1 ? t('${key}_one', fallbackOne) : '$n ${t(key, fallbackMany)}';

    final rows = <String>[];

    // Every worship key is either named by one of the three lines below or
    // rolled into the "N items" remainder. `named` tracks how many keys the
    // named lines account for, so the remainder is always the truth — a
    // present-but-empty salah log stays visible as an item rather than being
    // subtracted away, which would make the list claim there is nothing to
    // save while the save button sits right underneath it.
    var named = 0;

    final days = summary.salahDays;
    if (days != null && days > 0) {
      rows.add(counted(days, 'salah_days', 'يوم صلاة', 'يوم صلاة واحد'));
      named++;
    }
    if (summary.hasActiveWirdPlan) {
      rows.add(t('wird_plan', 'خطة ورد'));
      named++;
    }
    if (summary.dhikrCounters > 0) {
      rows.add(
        counted(
          summary.dhikrCounters,
          'counters',
          'عدّاد ذِكر',
          'عدّاد ذِكر واحد',
        ),
      );
      named += summary.dhikrCounters;
    }

    // What is left: the zakat figures, the tasbih totals, an inactive wird
    // plan. Counted rather than named so the list stays short.
    final otherWorship =
        (summary.keysBySection[BackupSection.worship] ?? 0) - named;
    if (otherWorship > 0) {
      rows.add(counted(otherWorship, 'items', 'عنصر', 'عنصر واحد'));
    }

    if (summary.has(BackupSection.settings)) {
      rows.add(t('section_settings', 'الإعدادات وكل التذكيرات'));
    }
    if (summary.has(BackupSection.prayerTimes)) {
      rows.add(
        t('section_prayer_times', 'طريقة حساب المواقيت، والمذهب، والتعديلات'),
      );
    }
    if (summary.has(BackupSection.location)) {
      rows.add(t('section_location', 'الموقع المحفوظ'));
    }

    return rows;
  }
}
