import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

import '../../data/moon_phase.dart';

/// Lookup helpers that map enum values to localised strings. Centralised so
/// the calendar and detail screens render the same labels.
class MoonPhaseLabels {
  MoonPhaseLabels._();

  static String phaseName(MoonPhase phase, AppLocalizations? l10n) {
    final key = switch (phase) {
      MoonPhase.newMoon => 'moon_phases.phase_new_moon',
      MoonPhase.waxingCrescent => 'moon_phases.phase_waxing_crescent',
      MoonPhase.firstQuarter => 'moon_phases.phase_first_quarter',
      MoonPhase.waxingGibbous => 'moon_phases.phase_waxing_gibbous',
      MoonPhase.fullMoon => 'moon_phases.phase_full_moon',
      MoonPhase.waningGibbous => 'moon_phases.phase_waning_gibbous',
      MoonPhase.lastQuarter => 'moon_phases.phase_last_quarter',
      MoonPhase.waningCrescent => 'moon_phases.phase_waning_crescent',
    };
    final fallback = switch (phase) {
      MoonPhase.newMoon => 'New Moon',
      MoonPhase.waxingCrescent => 'Waxing Crescent',
      MoonPhase.firstQuarter => 'First Quarter',
      MoonPhase.waxingGibbous => 'Waxing Gibbous',
      MoonPhase.fullMoon => 'Full Moon',
      MoonPhase.waningGibbous => 'Waning Gibbous',
      MoonPhase.lastQuarter => 'Last Quarter',
      MoonPhase.waningCrescent => 'Waning Crescent',
    };
    return l10n?.translate(key) ?? fallback;
  }

  static IconData phaseIcon(MoonPhase phase) {
    switch (phase) {
      case MoonPhase.newMoon:
        return Icons.circle_outlined;
      case MoonPhase.firstQuarter:
      case MoonPhase.lastQuarter:
        return Icons.brightness_2_outlined;
      case MoonPhase.fullMoon:
        return Icons.brightness_1;
      default:
        return Icons.nights_stay_outlined;
    }
  }
}

/// Format helpers — kilometres with thousands separator, percent rounded.
String formatKm(double km) {
  final rounded = km.round();
  final s = rounded.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
  }
  return '${buf.toString()} km';
}

String formatPercent(double f) => '${(f * 100).round()}%';

String formatDays(double d) {
  return '${d.toStringAsFixed(1)} ${d == 1.0 ? 'day' : 'days'}';
}
