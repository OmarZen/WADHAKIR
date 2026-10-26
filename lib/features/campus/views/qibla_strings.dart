import 'package:flutter/widgets.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

/// Strings and number formatting for the qibla screens.
///
/// ## Why not `translate(key) ?? fallback`
/// `AppLocalizations.translate()` returns the KEY itself when a string is
/// missing, never null, so the app's usual `?? 'fallback'` only covers "no
/// localization at all" and a missing key shows `qibla.map.km` on screen.
/// [tr] treats both cases as missing and returns the Arabic [fallback]
/// instead. `qibla_l10n_test.dart` holds every fallback equal to `ar.json`.
///
/// ## Numbers in Arabic sentences
/// Arabic is right to left and a lone "°" takes the direction of the text
/// around it, so "استدر 46° لليمين" renders as "°46". [fill] wraps every
/// `{x}°` unit in a left-to-right isolate (U+2066 … U+2069), which is the one
/// way numbers with units are written inside sentences on these screens.
/// Standalone readouts (the big number, the map card) are `Text` widgets with
/// `textDirection: TextDirection.ltr` instead. Digits are Western, as in the
/// rest of the app.
abstract final class QiblaStrings {
  static const String _lri = '\u2066';
  static const String _pdi = '\u2069';

  /// The string for [key], or [fallback] when it is missing.
  static String tr(BuildContext context, String key, String fallback) {
    final l10n = context.l10n;
    if (l10n == null) return fallback;
    final value = l10n.translate(key);
    return value == key || value.isEmpty ? fallback : value;
  }

  /// Fills `{name}` placeholders in [template]. A placeholder followed by "°"
  /// is isolated left to right together with its degree sign.
  static String fill(String template, Map<String, Object> values) {
    var out = template;
    values.forEach((name, value) {
      out = out
          .replaceAll('{$name}°', '$_lri$value°$_pdi')
          .replaceAll('{$name}', '$value');
    });
    return out;
  }

  /// [text] isolated left to right, for a number or unit placed inside a
  /// right-to-left sentence by hand.
  static String ltr(String text) => '$_lri$text$_pdi';
}

/// Number formatting shared by every qibla tab.
abstract final class QiblaFormat {
  /// Whole degrees, `0..359` (a rounded 359.6 is shown as 0, not 360).
  static int wholeDegrees(double degrees) => degrees.round() % 360;

  /// "136°". Put it in a `Text` with `textDirection: TextDirection.ltr`.
  static String degrees(double degrees) => '${wholeDegrees(degrees)}°';

  /// "1,287" for kilometres: grouped from 10 km up, one decimal below, so a
  /// user a few kilometres from the Haram still sees a useful number.
  static String km(double km) {
    if (km < 10) return km.toStringAsFixed(1);
    return _grouped(km.round());
  }

  static String _grouped(int value) {
    final digits = value.abs().toString();
    final out = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  /// Four decimals: about 10 m, which is finer than any phone fix.
  static String coordinate(double value) => value.abs().toStringAsFixed(4);

  /// "30.0444° شمالًا، 31.2357° شرقًا".
  static String coordinates(
    BuildContext context,
    double latitude,
    double longitude,
  ) {
    final ns = latitude >= 0
        ? QiblaStrings.tr(context, 'qibla.location.north', 'شمالًا')
        : QiblaStrings.tr(context, 'qibla.location.south', 'جنوبًا');
    final ew = longitude >= 0
        ? QiblaStrings.tr(context, 'qibla.location.east', 'شرقًا')
        : QiblaStrings.tr(context, 'qibla.location.west', 'غربًا');
    return QiblaStrings.fill(
      QiblaStrings.tr(
        context,
        'qibla.location.coords',
        '{lat}° {ns}، {lng}° {ew}',
      ),
      {
        'lat': coordinate(latitude),
        'ns': ns,
        'lng': coordinate(longitude),
        'ew': ew,
      },
    );
  }

  /// The eight-wind name of [azimuth] ("الجنوب الغربي"), for "the sun is now
  /// in the south-west".
  static String compassPoint(BuildContext context, double azimuth) {
    final index = (((azimuth % 360) + 360) % 360 + 22.5) ~/ 45 % 8;
    switch (index) {
      case 0:
        return QiblaStrings.tr(context, 'qibla.dir.n', 'الشمال');
      case 1:
        return QiblaStrings.tr(context, 'qibla.dir.ne', 'الشمال الشرقي');
      case 2:
        return QiblaStrings.tr(context, 'qibla.dir.e', 'الشرق');
      case 3:
        return QiblaStrings.tr(context, 'qibla.dir.se', 'الجنوب الشرقي');
      case 4:
        return QiblaStrings.tr(context, 'qibla.dir.s', 'الجنوب');
      case 5:
        return QiblaStrings.tr(context, 'qibla.dir.sw', 'الجنوب الغربي');
      case 6:
        return QiblaStrings.tr(context, 'qibla.dir.w', 'الغرب');
      default:
        return QiblaStrings.tr(context, 'qibla.dir.nw', 'الشمال الغربي');
    }
  }

  /// «القبلة على بُعد 46° يمين {ref}» / «… يسار …», or «القبلة في اتجاه
  /// {ref} نفسه» within a degree.
  static String relative(BuildContext context, double relative, String ref) {
    final n = relative.abs().round();
    if (n == 0) {
      return QiblaStrings.fill(
        QiblaStrings.tr(
          context,
          'qibla.celestial.relative_same',
          'القبلة في اتجاه {ref} نفسه',
        ),
        {'ref': ref},
      );
    }
    final template = relative > 0
        ? QiblaStrings.tr(
            context,
            'qibla.celestial.relative_right',
            'القبلة على بُعد {n}° يمين {ref}',
          )
        : QiblaStrings.tr(
            context,
            'qibla.celestial.relative_left',
            'القبلة على بُعد {n}° يسار {ref}',
          );
    return QiblaStrings.fill(template, {'n': n, 'ref': ref});
  }
}
