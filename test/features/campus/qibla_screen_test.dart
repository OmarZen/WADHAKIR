import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/core/app_theme/forui_theme.dart';
import 'package:wadhakir/core/localization/app_localizations_delegate.dart';
import 'package:wadhakir/data/models/qibla_model.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/services/qibla_ar_camera_service.dart';
import 'package:wadhakir/features/campus/views/screens/qibla_ar_screen.dart';
import 'package:wadhakir/features/campus/views/screens/qibla_screen.dart';
import 'package:wadhakir/features/campus/views/widgets/ar/qibla_ar_steady_step.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_ar_overlay.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_calibration_card.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_celestial_tab.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_compass_tab.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_map_info_card.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_map_tab.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_shadow_tab.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_tab_selector.dart';

import 'fakes/fake_qibla_repository.dart';

/// The اتجاه القبلة screen over a fake repository: Arabic, right to left and
/// reduced motion unless a test says otherwise, with Dart fallbacks for the
/// strings unless it asks for the real language files.

/// Late morning in Cairo: the sun is up in the south-east, about 45° high.
final _morning = DateTime.utc(2026, 10, 25, 8, 30);

/// Late evening in Cairo: the sun is well below the horizon.
final _night = DateTime.utc(2026, 10, 25, 20);

class _FakeCamera {
  int calls = 0;

  Future<QiblaArCameraResult> prepare() async {
    calls++;
    return const QiblaArCameraResult(QiblaArAvailability.permissionDenied);
  }
}

Future<FakeQiblaRepository> _pump(
  WidgetTester tester, {
  FakeQiblaRepository? repository,
  QiblaCapabilities capabilities = QiblaCapabilities.android,
  DateTime? now,
  Size size = const Size(390, 844),
  double textScale = 1.0,
  bool dark = false,
  bool reduceMotion = true,
  Locale locale = const Locale('ar'),
  bool realStrings = false,
  _FakeCamera? camera,
}) async {
  final repo = repository ?? FakeQiblaRepository();
  addTearDown(repo.dispose);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  if (realStrings) rootBundle.clear();
  final clock = now ?? _morning;
  final cam = camera ?? _FakeCamera();

  await tester.pumpWidget(
    MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: [
        if (realStrings) const AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: FTheme(data: buildForuiTheme(Theme.of(context)), child: child!),
      ),
      home: QiblaScreen(
        enableTiles: false,
        prepareCamera: cam.prepare,
        createCubit: () => QiblaCubit(
          repository: repo,
          capabilities: capabilities,
          clock: () => clock,
          onAlignedHaptic: () {},
          hijriDayOf: (_) => 3,
          moonIlluminationOf: (_) => 0.12,
        ),
      ),
    ),
  );
  if (realStrings) {
    // The language file is read by real I/O, which the fake clock never lets
    // finish. Give it real time (see qibla_ar_safety_notice_test.dart).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
  }
  await tester.pumpAndSettle();
  return repo;
}

/// Holds the phone at [heading] long enough for the smoothing to settle.
Future<void> _face(
  WidgetTester tester,
  FakeQiblaRepository repo,
  double heading,
) async {
  for (var i = 0; i < 40; i++) {
    repo.heading.add(HeadingSample(heading: heading));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

QiblaCubit _cubit(WidgetTester tester) =>
    tester.element(find.byType(QiblaTabSelector)).read<QiblaCubit>();

void main() {
  group('tabs', () {
    testWidgets('opens on the compass, with the header and five tabs', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('اتجاه القبلة'), findsOneWidget);
      expect(find.byType(QiblaCompassTab), findsOneWidget);
      for (final label in [
        'البوصلة',
        'الخريطة',
        'الواقع المعزز',
        'الظل',
        'الشمس والقمر',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('only the active tab is mounted', (tester) async {
      await _pump(tester);

      await _openTab(tester, 'الخريطة');
      expect(find.byType(QiblaMapTab), findsOneWidget);
      expect(find.byType(QiblaCompassTab), findsNothing);

      await _openTab(tester, 'الظل');
      expect(find.byType(QiblaShadowTab), findsOneWidget);
      expect(find.byType(QiblaMapTab), findsNothing);

      await _openTab(tester, 'الشمس والقمر');
      expect(find.byType(QiblaCelestialTab), findsOneWidget);
      expect(find.byType(QiblaShadowTab), findsNothing);

      await _openTab(tester, 'البوصلة');
      expect(find.byType(QiblaCompassTab), findsOneWidget);
      expect(find.byType(QiblaCelestialTab), findsNothing);
    });

    testWidgets('desktop offers map, shadow and sun, and opens on the map', (
      tester,
    ) async {
      await _pump(tester, capabilities: QiblaCapabilities.desktop);
      expect(find.byType(QiblaMapTab), findsOneWidget);
      expect(find.text('البوصلة'), findsNothing);
      expect(find.text('الواقع المعزز'), findsNothing);
      expect(find.text('الظل'), findsOneWidget);
      expect(find.text('الشمس والقمر'), findsOneWidget);
    });
  });

  group('compass', () {
    testWidgets('says which way to turn, and the number reads left to right', (
      tester,
    ) async {
      final repo = await _pump(tester);
      // Cairo's qibla is 136°; facing 100° it is 36° to the right.
      await _face(tester, repo, 100);
      expect(find.textContaining('لليمين'), findsOneWidget);
      expect(find.textContaining('36°'), findsOneWidget);

      final readout = tester.widget<Text>(find.text('100°'));
      expect(readout.textDirection, TextDirection.ltr);

      await _face(tester, repo, 170.14);
      expect(find.textContaining('لليسار'), findsOneWidget);
      expect(find.textContaining('34°'), findsOneWidget);
    });

    testWidgets('facing the qibla shows the green chip', (tester) async {
      final repo = await _pump(tester);
      await _face(tester, repo, 136);
      expect(find.text('أنت الآن في اتجاه القبلة'), findsOneWidget);
      expect(find.text('136°'), findsOneWidget);
      expect(find.textContaining('اتجاه القبلة من موقعك'), findsOneWidget);
    });

    testWidgets('low accuracy shows the calibration card; «تخطي» hides it', (
      tester,
    ) async {
      final repo = await _pump(tester);
      await _face(tester, repo, 90);
      expect(find.byType(QiblaCalibrationCard), findsNothing);

      repo.accuracy.add(CompassAccuracyLevel.low);
      await tester.pumpAndSettle();
      expect(find.byType(QiblaCalibrationCard), findsOneWidget);
      expect(find.text('معايرة البوصلة'), findsOneWidget);
      expect(find.text('الدقة: منخفضة'), findsOneWidget);

      await tester.ensureVisible(find.text('تخطي المعايرة'));
      await tester.tap(find.text('تخطي المعايرة'));
      await tester.pumpAndSettle();
      expect(find.byType(QiblaCalibrationCard), findsNothing);
    });

    testWidgets('no magnetometer: explains, hides AR, offers map and sun', (
      tester,
    ) async {
      await _pump(tester, repository: FakeQiblaRepository(magnetometer: false));
      expect(find.text('البوصلة غير متاحة'), findsOneWidget);
      expect(find.text('الواقع المعزز'), findsNothing);

      await tester.tap(find.text('استخدم الخريطة'));
      await tester.pumpAndSettle();
      expect(find.byType(QiblaMapTab), findsOneWidget);
    });
  });

  group('location', () {
    testWidgets('«ليس الآن» shows the approximate qibla without a prompt', (
      tester,
    ) async {
      final repo = await _pump(
        tester,
        repository: FakeQiblaRepository(
          access: LocationAccess.denied,
          cached: cairoCached,
        ),
      );
      expect(find.text('نحتاج موقعك'), findsOneWidget);

      await tester.tap(find.text('ليس الآن'));
      await tester.pumpAndSettle();
      expect(repo.requestCalls, 0, reason: '«ليس الآن» never prompts');
      expect(find.text('نحتاج موقعك'), findsNothing);
      expect(find.text('موقع تقريبي'), findsOneWidget);
    });

    testWidgets('«ليس الآن» with nothing saved shows the locked card', (
      tester,
    ) async {
      final repo = await _pump(
        tester,
        repository: FakeQiblaRepository(access: LocationAccess.denied),
      );
      await tester.tap(find.text('ليس الآن'));
      await tester.pumpAndSettle();
      expect(find.text('الموقع غير متاح'), findsOneWidget);

      // «سماح» there is still the one way to the OS prompt.
      await tester.tap(find.text('سماح'));
      await tester.pumpAndSettle();
      expect(repo.requestCalls, 1);
      expect(find.byType(QiblaCompassTab), findsOneWidget);
      expect(find.text('الموقع غير متاح'), findsNothing);
    });

    testWidgets('permanently denied offers the settings page', (tester) async {
      final repo = await _pump(
        tester,
        repository: FakeQiblaRepository(access: LocationAccess.deniedForever),
      );
      expect(find.text('الموقع غير متاح'), findsOneWidget);
      await tester.tap(find.text('فتح الإعدادات'));
      await tester.pumpAndSettle();
      expect(repo.openAppSettingsCalls, 1);
      expect(repo.requestCalls, 0);
    });

    testWidgets('the header names the place, or gives the coordinates', (
      tester,
    ) async {
      await _pump(tester, repository: FakeQiblaRepository(name: 'القاهرة'));
      expect(find.text('القاهرة'), findsOneWidget);
    });
  });

  group('map', () {
    testWidgets('shows distance, bearing and the attribution above the card', (
      tester,
    ) async {
      await _pump(tester);
      await _openTab(tester, 'الخريطة');

      expect(find.byType(QiblaMapInfoCard), findsOneWidget);
      expect(find.text('المسافة المباشرة'), findsOneWidget);
      expect(find.textContaining('1,287'), findsOneWidget);
      final bearing = tester.widget<Text>(find.text('136°'));
      expect(bearing.textDirection, TextDirection.ltr);

      final attribution = find.text('OpenStreetMap contributors');
      expect(attribution.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(attribution).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(QiblaMapInfoCard)).top),
        reason: 'the OSM attribution must never sit under the info card',
      );
    });

    testWidgets('after four failed tiles: the offline banner, and a retry', (
      tester,
    ) async {
      await _pump(tester);
      await _openTab(tester, 'الخريطة');
      final map = tester.state<QiblaMapViewState>(find.byType(QiblaMapView));

      for (var i = 0; i < 3; i++) {
        map.debugReportTileError();
      }
      await tester.pumpAndSettle();
      expect(find.textContaining('تعذّر تحميل الخريطة'), findsNothing);

      map.debugReportTileError();
      await tester.pumpAndSettle();
      expect(find.textContaining('تعذّر تحميل الخريطة'), findsOneWidget);
      // The numbers are arithmetic, not tiles: still there.
      expect(find.text('136°'), findsOneWidget);

      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();
      expect(find.textContaining('تعذّر تحميل الخريطة'), findsNothing);
    });
  });

  group('AR', () {
    testWidgets('the embedded safety notice sits below the tab strip', (
      tester,
    ) async {
      final camera = _FakeCamera();
      await _pump(tester, camera: camera);
      await _openTab(tester, 'الواقع المعزز');

      expect(find.byType(QiblaArScreen), findsOneWidget);
      final strip = tester.getRect(find.byType(QiblaTabSelector));
      final shield = tester.getRect(
        find.byIcon(Icons.health_and_safety_rounded),
      );
      expect(shield.top, greaterThanOrEqualTo(strip.bottom));
      expect(camera.calls, 0, reason: 'no camera before the notice');
      // Embedded, the route's own back bar is not drawn over the notice.
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('«العودة للبوصلة» goes back to the compass tab', (
      tester,
    ) async {
      await _pump(tester);
      await _openTab(tester, 'الواقع المعزز');
      await tester.tap(find.text('العودة للبوصلة'));
      await tester.pumpAndSettle();
      expect(find.byType(QiblaArScreen), findsNothing);
      expect(find.byType(QiblaCompassTab), findsOneWidget);
    });

    testWidgets('a refused camera offers it again, or the compass', (
      tester,
    ) async {
      final camera = _FakeCamera();
      await _pump(tester, camera: camera);
      await _openTab(tester, 'الواقع المعزز');
      await tester.tap(find.text('فهمت، افتح الكاميرا'));
      await tester.pumpAndSettle();

      expect(camera.calls, 1);
      expect(find.text('الكاميرا غير مفعّلة'), findsOneWidget);
      expect(find.text('يحتاج وضع الكاميرا إلى إذن الكاميرا'), findsOneWidget);
      expect(find.text('السماح بالكاميرا'), findsOneWidget);

      await tester.tap(find.text('استخدم البوصلة بدلًا من ذلك'));
      await tester.pumpAndSettle();
      expect(find.byType(QiblaCompassTab), findsOneWidget);
    });
  });

  group('AR guide', () {
    /// A cubit on the AR tab with the camera "up": the phone held at 45°
    /// toward the floor for two seconds, facing [heading] (Cairo's qibla is
    /// 136°).
    Future<QiblaCubit> steadyArCubit(
      WidgetTester tester,
      FakeQiblaRepository repo,
      double heading,
    ) async {
      var now = _morning;
      final cubit = QiblaCubit(
        repository: repo,
        capabilities: QiblaCapabilities.android,
        clock: () => now,
        onAlignedHaptic: () {},
        hijriDayOf: (_) => 3,
        moonIlluminationOf: (_) => 0.12,
      );
      addTearDown(cubit.close);
      await cubit.start();
      cubit.selectTab(QiblaTab.ar);
      cubit.setArActive(true);
      for (var i = 0; i < 40; i++) {
        now = now.add(const Duration(milliseconds: 100));
        repo.heading.add(HeadingSample(heading: heading));
        // Gravity split evenly between the screen's y and z: a 45° tilt.
        repo.tilt.add(const TiltSample(0, 6.93, 6.93));
        await tester.pump();
      }
      return cubit;
    }

    Future<void> pumpHud(
      WidgetTester tester,
      QiblaCubit cubit, {
      Locale locale = const Locale('ar'),
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          locale: locale,
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) =>
              FTheme(data: buildForuiTheme(Theme.of(context)), child: child!),
          home: Scaffold(
            backgroundColor: Colors.black,
            body: BlocProvider.value(
              value: cubit,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  QiblaArRugLayer(frame: const Size(390, 520)),
                  const QiblaArHud(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the turn arrow and «القبلة →» are on the physical side', (
      tester,
    ) async {
      final repo = FakeQiblaRepository();
      addTearDown(repo.dispose);
      // Facing 100°, the qibla is 36° to the RIGHT.
      final cubit = await steadyArCubit(tester, repo, 100);
      expect(cubit.state.arPhase, QiblaArPhase.guiding);

      await pumpHud(tester, cubit);
      expect(
        find.text('السجادة دليل مرسوم وفق البوصلة، وليست مثبتة على الأرض.'),
        findsOneWidget,
      );
      expect(find.textContaining('لليمين'), findsOneWidget);
      // Right of centre in Arabic too: the user turns their body, and the
      // page's reading direction has nothing to do with it.
      final pill = tester.getCenter(find.text('القبلة'));
      expect(pill.dx, greaterThan(390 / 2));
      final arrowRow = tester.widget<Directionality>(
        find
            .ancestor(
              of: find.text('القبلة'),
              matching: find.byType(Directionality),
            )
            .first,
      );
      expect(arrowRow.textDirection, TextDirection.ltr);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets('a qibla to the left puts the pill on the left', (
      tester,
    ) async {
      final repo = FakeQiblaRepository();
      addTearDown(repo.dispose);
      final cubit = await steadyArCubit(tester, repo, 200);
      await pumpHud(tester, cubit);
      expect(find.textContaining('لليسار'), findsOneWidget);
      expect(tester.getCenter(find.text('القبلة')).dx, lessThan(390 / 2));
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('aligned: the result panel, and «إعادة الضبط» starts over', (
      tester,
    ) async {
      final repo = FakeQiblaRepository();
      addTearDown(repo.dispose);
      final cubit = await steadyArCubit(tester, repo, 136);
      expect(cubit.state.arPhase, QiblaArPhase.aligned);

      await pumpHud(tester, cubit);
      expect(find.text('السجادة الآن باتجاه القبلة'), findsOneWidget);
      expect(find.text('136°'), findsOneWidget);
      expect(find.textContaining('1,287'), findsOneWidget);
      expect(find.byType(QiblaArRugLayer), findsOneWidget);

      await tester.tap(find.text('إعادة الضبط'));
      await tester.pumpAndSettle();
      expect(cubit.state.arPhase, QiblaArPhase.steadying);
      expect(find.text('وجّه الكاميرا نحو الأرض وثبّت الهاتف'), findsOneWidget);
      expect(find.byType(QiblaArSteadyStep), findsOneWidget);
    });
  });

  group('shadow and sun/moon', () {
    testWidgets('by day the shadow tab gives the angle from the shadow', (
      tester,
    ) async {
      await _pump(tester);
      await _openTab(tester, 'الظل');
      expect(find.textContaining('ظل العود'), findsWidgets);
      expect(find.textContaining('الشمس الآن في'), findsOneWidget);
    });

    testWidgets('at night the shadow tab says so and offers the moon', (
      tester,
    ) async {
      await _pump(tester, now: _night);
      await _openTab(tester, 'الظل');
      expect(find.textContaining('تعمل نهارًا فقط'), findsOneWidget);

      await tester.ensureVisible(find.text('جرّب القمر'));
      await tester.tap(find.text('جرّب القمر'));
      await tester.pumpAndSettle();
      expect(find.byType(QiblaCelestialTab), findsOneWidget);
      expect(_cubit(tester).state.body, CelestialBody.moon);
    });

    testWidgets('by day the sun tab aims with the sun, with the eye warning', (
      tester,
    ) async {
      await _pump(tester);
      await _openTab(tester, 'الشمس والقمر');
      expect(find.textContaining('الشمس ظاهرة'), findsOneWidget);
      expect(find.text('لا تحدّق في الشمس مباشرة'), findsOneWidget);

      await tester.tap(find.text('القمر'));
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.body, CelestialBody.moon);
      expect(find.text('لا تحدّق في الشمس مباشرة'), findsNothing);
    });
  });

  group('layout', () {
    for (final lang in ['ar', 'en']) {
      testWidgets('[$lang] 320×568 at text scale 1.6: every tab fits', (
        tester,
      ) async {
        final repo = await _pump(
          tester,
          size: const Size(320, 568),
          textScale: 1.6,
          locale: Locale(lang),
          realStrings: true,
        );
        await _face(tester, repo, 100);
        repo.accuracy.add(CompassAccuracyLevel.low);
        await tester.pumpAndSettle();
        expect(find.byType(QiblaCalibrationCard), findsOneWidget);
        expect(tester.takeException(), isNull);

        final cubit = _cubit(tester);
        for (final tab in [
          QiblaTab.map,
          QiblaTab.ar,
          QiblaTab.shadow,
          QiblaTab.celestial,
          QiblaTab.compass,
        ]) {
          cubit.selectTab(tab);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$tab overflowed');
        }

        // The strip's labels are the language's own, and wrap if they must.
        expect(
          Directionality.of(tester.element(find.byType(QiblaTabSelector))),
          lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
      });
    }

    for (final lang in ['ar', 'en']) {
      testWidgets('[$lang] 320×568 at text scale 1.6: the cards fit too', (
        tester,
      ) async {
        await _pump(
          tester,
          repository: FakeQiblaRepository(
            access: LocationAccess.denied,
            cached: cairoCached,
          ),
          size: const Size(320, 568),
          textScale: 1.6,
          locale: Locale(lang),
          realStrings: true,
        );
        // The location prompt, on every tab that needs a position.
        final cubit = _cubit(tester);
        for (final tab in [
          QiblaTab.compass,
          QiblaTab.map,
          QiblaTab.ar,
          QiblaTab.shadow,
          QiblaTab.celestial,
        ]) {
          cubit.selectTab(tab);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$tab prompt');
        }

        // The approximate fix, then the map's offline banner.
        cubit.selectTab(QiblaTab.map);
        await cubit.declineLocation();
        await tester.pumpAndSettle();
        final map = tester.state<QiblaMapViewState>(find.byType(QiblaMapView));
        for (var i = 0; i < 4; i++) {
          map.debugReportTileError();
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'offline banner');

        // The AR tab's camera-off card.
        cubit.selectTab(QiblaTab.ar);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byIcon(Icons.photo_camera_rounded),
          100,
        );
        await tester.tap(find.byIcon(Icons.photo_camera_rounded));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.no_photography_rounded), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'camera off');
      });
    }

    testWidgets('dark mode renders every tab', (tester) async {
      final repo = await _pump(tester, dark: true);
      await _face(tester, repo, 136);
      final cubit = _cubit(tester);
      for (final tab in QiblaTab.values) {
        cubit.selectTab(tab);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$tab');
      }
    });

    testWidgets('with animations on, tab changes still settle', (tester) async {
      await _pump(tester, reduceMotion: false);
      await _openTab(tester, 'الخريطة');
      expect(find.byType(QiblaMapTab), findsOneWidget);
      expect(find.byType(QiblaCompassTab), findsNothing);
    });
  });
}
