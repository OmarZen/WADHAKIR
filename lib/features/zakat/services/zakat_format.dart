import 'package:wadhakir/features/wird/services/wird_format.dart';

/// Number parsing/formatting helpers for the Zakat Calculator.
///
/// The app does not initialize `intl` locale data, so we format numbers
/// manually (with a thousands separator) and reuse [WirdFormat.toArabicDigits]
/// for Arabic-Indic display digits.
class ZakatFormat {
  const ZakatFormat._();

  /// Parse a user-typed amount into a double, tolerant of Arabic-Indic digits,
  /// both decimal separators (`.` and `,` / `٫`) and stray grouping/spaces.
  /// Returns 0 for empty/invalid input.
  static double parseAmount(String raw) {
    if (raw.trim().isEmpty) return 0;

    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      // Map Arabic-Indic (٠..٩, U+0660..0669) and Eastern (۰..۹, U+06F0..06F9)
      // digits back to ASCII 0-9.
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + (rune - 0x0660));
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + (rune - 0x06F0));
      } else if (rune >= 0x30 && rune <= 0x39) {
        buffer.writeCharCode(rune);
      } else if (rune == 0x2E || rune == 0x2C || rune == 0x066B) {
        // '.', ',' or Arabic decimal separator '٫' → canonical '.'
        buffer.write('.');
      }
      // Everything else (spaces, grouping, currency glyphs) is dropped.
    }

    var s = buffer.toString();
    // Collapse multiple separators: keep only the last as the decimal point.
    final lastDot = s.lastIndexOf('.');
    if (lastDot != -1) {
      final intPart = s.substring(0, lastDot).replaceAll('.', '');
      final fracPart = s.substring(lastDot + 1);
      s = '$intPart.$fracPart';
    }
    return double.tryParse(s) ?? 0;
  }

  /// Format a monetary amount with thousands grouping and up to [decimals]
  /// fraction digits (trailing zeros trimmed). Converts to Arabic-Indic digits
  /// when [arabic] is true.
  static String formatAmount(
    double value, {
    required bool arabic,
    int decimals = 2,
  }) {
    final safe = value.isFinite ? value : 0.0;
    var s = safe.toStringAsFixed(decimals);

    // Trim trailing zeros (and a dangling dot) for a cleaner read.
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }

    final parts = s.split('.');
    parts[0] = _group(parts[0]);
    final grouped = parts.join('.');

    return arabic ? WirdFormat.toArabicDigits(grouped) : grouped;
  }

  /// Insert a comma every three digits (left of any decimal point).
  static String _group(String intDigits) {
    final negative = intDigits.startsWith('-');
    final digits = negative ? intDigits.substring(1) : intDigits;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return negative ? '-$buffer' : buffer.toString();
  }
}
