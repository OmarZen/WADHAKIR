import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/data/models/qibla_model.dart';
import 'package:wadhakir/data/repositories/qibla_repository_impl.dart';

/// Only the parts that need no plugin: reading the prayer-times feature's
/// saved location, and the 30 km rule for borrowing its city name. The host
/// running these tests is a desktop, so reverse geocoding is never reached.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cairo = QiblaFix(
    latitude: 30.0444,
    longitude: 31.2357,
    source: QiblaFixSource.gps,
  );

  group('cachedNameNear', () {
    test('borrows the saved name within 30 km', () {
      // Giza is about 10 km from central Cairo.
      expect(
        QiblaRepositoryImpl.cachedNameNear(
          fix: const QiblaFix(
            latitude: 30.0131,
            longitude: 31.2089,
            source: QiblaFixSource.gps,
          ),
          cachedLatitude: 30.0444,
          cachedLongitude: 31.2357,
          cachedName: 'القاهرة',
        ),
        'القاهرة',
      );
    });

    test('does not label Alexandria "Cairo"', () {
      expect(
        QiblaRepositoryImpl.cachedNameNear(
          fix: const QiblaFix(
            latitude: 31.2001,
            longitude: 29.9187,
            source: QiblaFixSource.gps,
          ),
          cachedLatitude: 30.0444,
          cachedLongitude: 31.2357,
          cachedName: 'القاهرة',
        ),
        isNull,
      );
    });

    test('ignores a blank name or missing coordinates', () {
      expect(
        QiblaRepositoryImpl.cachedNameNear(
          fix: cairo,
          cachedLatitude: 30.0444,
          cachedLongitude: 31.2357,
          cachedName: '  ',
        ),
        isNull,
      );
      expect(
        QiblaRepositoryImpl.cachedNameNear(
          fix: cairo,
          cachedLatitude: null,
          cachedLongitude: 31.2357,
          cachedName: 'القاهرة',
        ),
        isNull,
      );
    });
  });

  group('prayer-times keys, read only', () {
    test('cachedPrayerFix reads the saved coordinates', () async {
      SharedPreferences.setMockInitialValues({
        'prayer_times_last_latitude': 30.0444,
        'prayer_times_last_longitude': 31.2357,
      });
      final fix = await QiblaRepositoryImpl().cachedPrayerFix();
      expect(fix, isNotNull);
      expect(fix!.source, QiblaFixSource.cached);
      expect(fix.latitude, 30.0444);
      expect(fix.longitude, 31.2357);
    });

    test(
      'cachedPrayerFix is null when nothing (or nonsense) is saved',
      () async {
        SharedPreferences.setMockInitialValues({});
        expect(await QiblaRepositoryImpl().cachedPrayerFix(), isNull);

        SharedPreferences.setMockInitialValues({
          'prayer_times_last_latitude': 123.0,
          'prayer_times_last_longitude': 31.2357,
        });
        expect(await QiblaRepositoryImpl().cachedPrayerFix(), isNull);
      },
    );

    test('placeName uses the saved name nearby and never writes', () async {
      SharedPreferences.setMockInitialValues({
        'prayer_times_last_latitude': 30.0444,
        'prayer_times_last_longitude': 31.2357,
        'prayer_times_last_location_name': 'القاهرة',
      });
      final repo = QiblaRepositoryImpl();
      expect(await repo.placeName(cairo), 'القاهرة');

      // Far away on a desktop host: no geocoder, so no name.
      expect(
        await repo.placeName(
          const QiblaFix(
            latitude: 51.5074,
            longitude: -0.1278,
            source: QiblaFixSource.gps,
          ),
        ),
        isNull,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('prayer_times_last_location_name'), 'القاهرة');
      expect(prefs.getKeys(), {
        'prayer_times_last_latitude',
        'prayer_times_last_longitude',
        'prayer_times_last_location_name',
      });
    });

    test('the constructor does nothing', () {
      // No plugin is mocked; any platform call here would throw.
      expect(QiblaRepositoryImpl.new, returnsNormally);
    });
  });
}
