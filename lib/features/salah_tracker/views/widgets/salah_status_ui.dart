import 'package:flutter/material.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';

/// Shared color / icon / label mapping for prayer statuses and slots, so the
/// today rows, status sheet, make-up section and the prayer-times card all read
/// the same. Colors come from the app ColorScheme (M2) plus the brand green.
class SalahStatusUi {
  const SalahStatusUi._();

  // Amber "late" accent — there is no amber role in the M2 ColorScheme.
  static const Color _lateLight = Color(0xFFD98E04);
  static const Color _lateDark = Color(0xFFF0B429);

  static Color color(BuildContext context, PrayerStatus status) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    switch (status) {
      case PrayerStatus.onTime:
        return isDark ? darkPrayerAzkarColor : prayerAzkarColor;
      case PrayerStatus.late:
        return isDark ? _lateDark : _lateLight;
      case PrayerStatus.qada:
        return cs.primary;
      case PrayerStatus.missed:
        return cs.error;
      case PrayerStatus.notLogged:
        return cs.onSurface.withValues(alpha: 0.35);
    }
  }

  static IconData icon(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.onTime:
        return Icons.check_circle_rounded;
      case PrayerStatus.late:
        return Icons.schedule_rounded;
      case PrayerStatus.qada:
        return Icons.history_rounded;
      case PrayerStatus.missed:
        return Icons.cancel_rounded;
      case PrayerStatus.notLogged:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  static String statusLabel(BuildContext context, PrayerStatus status) {
    final l10n = context.l10n;
    switch (status) {
      case PrayerStatus.onTime:
        return l10n?.translate('salah_tracker.status_on_time') ?? 'في وقتها';
      case PrayerStatus.late:
        return l10n?.translate('salah_tracker.status_late') ?? 'متأخرة';
      case PrayerStatus.qada:
        return l10n?.translate('salah_tracker.status_qada') ?? 'قضاء';
      case PrayerStatus.missed:
        return l10n?.translate('salah_tracker.status_missed') ?? 'فائتة';
      case PrayerStatus.notLogged:
        return l10n?.translate('salah_tracker.status_not_logged') ??
            'لم تُسجّل';
    }
  }

  static String slotLabel(BuildContext context, PrayerSlot slot) {
    return context.l10n?.translate('salah_tracker.${slot.key}') ??
        slot.arabicName;
  }

  /// "السنة القبلية" / "السنة البعدية" — whether the rawatib falls before or
  /// after its fard.
  static String rawatibPositionLabel(BuildContext context, RawatibUnit unit) {
    final l10n = context.l10n;
    switch (unit.position) {
      case RawatibPosition.before:
        return l10n?.translate('salah_tracker.rawatib_qabliyyah') ??
            'السنة القبلية';
      case RawatibPosition.after:
        return l10n?.translate('salah_tracker.rawatib_badiyyah') ??
            'السنة البعدية';
    }
  }

  /// "ركعتان" / "٤ ركعات" — the rakʿah count of [unit].
  static String rawatibRakatLabel(BuildContext context, RawatibUnit unit) {
    final l10n = context.l10n;
    if (unit.rakat == 4) {
      return l10n?.translate('salah_tracker.rakaat_4') ?? '٤ ركعات';
    }
    return l10n?.translate('salah_tracker.rakaat_2') ?? 'ركعتان';
  }

  /// "آكدها" — badge for the single most-emphasized rawatib (راتبة الفجر).
  static String emphasizedLabel(BuildContext context) =>
      context.l10n?.translate('salah_tracker.rawatib_emphasized') ?? 'آكدها';

  static String witrLabel(BuildContext context) =>
      context.l10n?.translate('salah_tracker.witr') ?? 'الوتر';
}
