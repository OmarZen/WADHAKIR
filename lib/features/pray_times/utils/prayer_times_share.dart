import 'package:flutter/foundation.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';

/// The six prayer-name labels a shared timetable needs, already localised.
///
/// Passed in rather than read from `AppLocalizations` here so the builder stays
/// a pure function — no `BuildContext`, no ambient locale — and can be tested
/// without pumping a widget.
@immutable
class PrayerTimesShareLabels {
  /// Card title and system-share subject — «مواقيت الصلاة».
  final String title;

  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  const PrayerTimesShareLabels({
    required this.title,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });
}

/// Builds the [SharePayload] behind the prayer-times share button.
///
/// ## Why the city is not optional decoration
///
/// A timetable is only true somewhere. The same six times are wrong by an hour
/// two countries away, so the card carries its city and its date or it is
/// misinformation with a brand on it — which is why [build] puts them in the
/// subhead rather than the footnote, and why an *unresolved* city is omitted
/// rather than printed: «موقع غير محدد» on a shared card tells the recipient
/// nothing and tells the sender their app is broken.
class PrayerTimesShare {
  const PrayerTimesShare._();

  /// What `PrayerTimesRepository.getCurrentLocationName()` returns when it has
  /// no coordinates at all. Never printed on a card.
  static const String unknownLocation = 'موقع غير محدد';

  /// The six rows, in the order a printed mosque timetable carries them.
  ///
  /// Sunrise is here because it closes Fajr's window, which is the question
  /// people actually ask of a morning timetable. The two qiyam times the screen
  /// shows are deliberately absent: they are a personal-practice detail, and
  /// eight rows at 9:16 shrink the type past what survives WhatsApp's
  /// re-compression.
  static List<ShareTimetableRow> rows(
    PrayerTimesModel times,
    PrayerTimesShareLabels labels,
  ) => [
    ShareTimetableRow(label: labels.fajr, value: times.formatTime(times.fajr)),
    ShareTimetableRow(
      label: labels.sunrise,
      value: times.formatTime(times.sunrise),
    ),
    ShareTimetableRow(
      label: labels.dhuhr,
      value: times.formatTime(times.dhuhr),
    ),
    ShareTimetableRow(label: labels.asr, value: times.formatTime(times.asr)),
    ShareTimetableRow(
      label: labels.maghrib,
      value: times.formatTime(times.maghrib),
    ),
    ShareTimetableRow(label: labels.isha, value: times.formatTime(times.isha)),
  ];

  /// The «city · date» line under the title. Either half may be missing; if
  /// both are, the subhead is empty and the card renders without it.
  static String subhead({String? cityName, String? dateLine}) =>
      [cityName, dateLine].where(_isUsable).join(' · ');

  /// Builds the payload for [times] as they stand on [dateLine].
  ///
  /// [cityName] may be null, empty, or the [unknownLocation] sentinel — all
  /// three are treated the same way and leave the city off the card.
  static SharePayload build({
    required PrayerTimesModel times,
    required PrayerTimesShareLabels labels,
    String? cityName,
    String? dateLine,
  }) {
    final tableRows = rows(times, labels);
    final line = subhead(cityName: cityName, dateLine: dateLine);

    return SharePayload(
      headline: labels.title,
      // Not drawn by the timetable variant — this is the system-share subject.
      categoryLabel: labels.title,
      reference: line.isEmpty ? null : line,
      variant: ShareCardVariant.timetable,
      timetableRows: tableRows,
      captionOverride: _caption(labels.title, line, tableRows),
    );
  }

  /// The text that travels with the PNG, and the whole of what "share text
  /// only" and "copy" send.
  ///
  /// It has to spell the times out: the share screen returns
  /// [SharePayload.captionOverride] verbatim when one is set, so a caption of
  /// just the title would make both text paths send a card with no times in it.
  /// Setting an override also means appending the app name and store link here
  /// — the default caption adds them, an override does not.
  static String _caption(
    String title,
    String subheadLine,
    List<ShareTimetableRow> rows,
  ) {
    final lines = <String>[title];
    if (subheadLine.isNotEmpty) lines.add(subheadLine);
    lines.add('');
    for (final row in rows) {
      lines.add('${row.label}: ${row.value}');
    }
    lines
      ..add('')
      ..add(AppConstants.appName)
      ..add(AppConstants.playStoreUrl);
    return lines.join('\n');
  }

  static bool _isUsable(String? value) =>
      value != null && value.isNotEmpty && value != unknownLocation;
}
