import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/utils/calculation_method_mapper.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/features/pray_times/utils/prayer_times_share.dart';
import 'package:wadhakir/features/share/models/share_background.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';

/// Roadmap #21 — share-from-anywhere reaches the prayer times.
///
/// The surface the plan calls the highest-value one left, and the first share
/// payload in this app that is *data* rather than words. Two things separate it
/// from every card before it: the times are only true in one city on one day,
/// and the text share has to carry them too.

PrayerTimesModel _times(DateTime day) {
  DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);
  return PrayerTimesModel(
    fajr: at(4, 30),
    sunrise: at(6, 0),
    dhuhr: at(12, 15),
    asr: at(15, 45),
    maghrib: at(18, 40),
    isha: at(20, 5),
    date: DateTime(day.year, day.month, day.day),
    calculationParameters: CalculationMethodMapper.getParameters(
      'muslim_world_league',
    ),
    coordinates: const Coordinates(30.04, 31.23),
    middleOfTheNight: at(0, 10),
    lastThirdOfTheNight: at(2, 20),
  );
}

const _labels = PrayerTimesShareLabels(
  title: 'مواقيت الصلاة',
  fajr: 'الفجر',
  sunrise: 'الشروق',
  dhuhr: 'الظهر',
  asr: 'العصر',
  maghrib: 'المغرب',
  isha: 'العشاء',
);

SharePayload _payload({String? cityName = 'القاهرة', String? dateLine}) =>
    PrayerTimesShare.build(
      times: _times(DateTime(2026, 9, 13)),
      labels: _labels,
      cityName: cityName,
      dateLine: dateLine ?? '٢١ ربيع الأول ١٤٤٧ هـ',
    );

void main() {
  group('the rows', () {
    test('are the five fard plus sunrise, in timetable order', () {
      final rows = _payload().timetableRows;

      expect(rows.map((r) => r.label), [
        'الفجر',
        'الشروق',
        'الظهر',
        'العصر',
        'المغرب',
        'العشاء',
      ]);
    });

    test('carry no qiyam times', () {
      // The screen shows منتصف الليل and الثلث الأخير; the card deliberately
      // does not. They are a personal-practice detail, and eight rows at 9:16
      // shrink the type past what survives WhatsApp's re-compression.
      final rows = _payload().timetableRows;
      expect(rows, hasLength(6));
      expect(
        rows.any((r) => r.label.contains('الليل')),
        isFalse,
        reason: 'the qiyam times are not part of a shared timetable',
      );
    });

    test('every row has a time', () {
      for (final row in _payload().timetableRows) {
        expect(row.value, isNotEmpty, reason: '${row.label} lost its time');
      }
    });
  });

  group('the subhead', () {
    test('is city then date', () {
      final payload = _payload(cityName: 'القاهرة', dateLine: '٢١ ربيع الأول');
      expect(payload.reference, 'القاهرة · ٢١ ربيع الأول');
    });

    test('omits an unresolved city rather than printing the sentinel', () {
      // «موقع غير محدد» on a card someone broadcasts tells the recipient
      // nothing and tells the sender their app is broken.
      final payload = _payload(cityName: PrayerTimesShare.unknownLocation);

      expect(
        payload.reference,
        isNot(contains(PrayerTimesShare.unknownLocation)),
      );
      expect(payload.reference, '٢١ ربيع الأول ١٤٤٧ هـ');
    });

    test('omits a null or empty city', () {
      expect(_payload(cityName: null).reference, '٢١ ربيع الأول ١٤٤٧ هـ');
      expect(_payload(cityName: '').reference, '٢١ ربيع الأول ١٤٤٧ هـ');
    });

    test('is null, not an empty string, when there is nothing to say', () {
      final payload = PrayerTimesShare.build(
        times: _times(DateTime(2026, 9, 13)),
        labels: _labels,
      );
      // The card skips the subhead on null. An empty string would reserve its
      // line and leave a gap under the title.
      expect(payload.reference, isNull);
    });
  });

  group('the caption', () {
    test('spells out every time', () {
      // The share screen returns captionOverride VERBATIM, so this string is
      // the whole of what "share text only" and "copy" send. A caption of just
      // the title would make both text paths send a timetable with no times.
      final payload = _payload();
      final caption = payload.captionOverride!;

      for (final row in payload.timetableRows) {
        expect(
          caption,
          contains(row.value),
          reason: '${row.label} is missing from the text share',
        );
        expect(caption, contains(row.label));
      }
    });

    test('carries the city and the date', () {
      expect(_payload().captionOverride, contains('القاهرة'));
      expect(_payload().captionOverride, contains('١٤٤٧'));
    });

    test('appends the app name and the store link', () {
      // Setting an override opts out of the default caption, which is what
      // normally adds these. Forgetting them drops the growth loop silently.
      final caption = _payload().captionOverride!;
      expect(caption, contains(AppConstants.appName));
      expect(caption, contains(AppConstants.playStoreUrl));
    });
  });

  group('the payload', () {
    test('is a timetable card at the story ratio', () {
      final payload = _payload();
      expect(payload.variant, ShareCardVariant.timetable);
      expect(payload.ratio, ShareCardRatio.story);
    });

    test('sets a subject the system share can use', () {
      // The timetable variant draws no category chip, but the share screen
      // passes categoryLabel as the share SUBJECT — so it still has to be set.
      expect(_payload().categoryLabel, 'مواقيت الصلاة');
    });

    test('copyWith keeps the rows', () {
      // The share screen calls copyWith on every background and ratio change.
      // A copyWith that dropped this field would blank the table the moment
      // the user touched the picker — and only then, which is the kind of
      // defect that ships.
      final reshaped = _payload().copyWith(
        ratio: ShareCardRatio.post,
        background: ShareBackground.brand,
      );

      expect(reshaped.timetableRows, hasLength(6));
      expect(reshaped.timetableRows.first.label, 'الفجر');
      expect(reshaped.variant, ShareCardVariant.timetable);
    });

    test('withBackground(null) keeps the rows too', () {
      final cleared = _payload().withBackground(null);
      expect(cleared.timetableRows, hasLength(6));
      expect(cleared.background, isNull);
    });
  });
}
