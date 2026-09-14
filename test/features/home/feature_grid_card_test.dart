import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/app_theme/forui_theme.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/features/home/views/widgets/grids/feature_grid_card.dart';

/// The home feature directory at large text sizes.
///
/// Every tile in it overflowed by ~10px once the reader turned the text up.
/// The cause is the shape of the old layout rather than any one tile: a fixed
/// `childAspectRatio` derives the cell's height from its width, and width does
/// not change with the text scale — so the label grew, the cell did not, and
/// the difference was painted outside the card.
///
/// PRODUCT.md names elder users who rely on large text as a primary audience,
/// which makes 1.6 — the ceiling R1 chose — the case that matters most here,
/// not an edge case.

Future<void> _pumpCard(
  WidgetTester tester, {
  required double textScale,
  required double cellHeight,
  double cellWidth = 120,
  String label = 'أذكار بعد الصلاة',
}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) => FTheme(
              // The tile is built on forui's FTappable, which reads this.
              data: buildForuiTheme(Theme.of(context)),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: cellWidth,
                    height: cellHeight,
                    child: FeatureGridCard(
                      icon: Icons.favorite,
                      label: label,
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The height the grid hands down, measured the way the grid measures it.
Future<double> _extentAt(WidgetTester tester, double textScale) async {
  late double extent;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Builder(
          builder: (context) {
            extent = FeatureGridCard.minExtentFor(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return extent;
}

void main() {
  group('minExtentFor', () {
    testWidgets('grows with the text scale', (tester) async {
      final atOne = await _extentAt(tester, 1.0);
      final atCeiling = await _extentAt(tester, AppSettingsModel.maxTextScale);

      expect(
        atCeiling,
        greaterThan(atOne),
        reason: 'the label is the part that grows; the height must follow',
      );
    });

    testWidgets('asks for room the tile actually needs at 1.6', (tester) async {
      // The number the old fixed ratio fell ~10px short of on a 3-column phone
      // grid. Pinned as a floor, not an exact value, so the tile's padding can
      // be retuned without rewriting the test.
      expect(
        await _extentAt(tester, AppSettingsModel.maxTextScale),
        greaterThan(130),
      );
    });
  });

  group('the tile', () {
    testWidgets('does not overflow at the largest text size', (tester) async {
      final extent = await _extentAt(tester, AppSettingsModel.maxTextScale);
      await _pumpCard(
        tester,
        textScale: AppSettingsModel.maxTextScale,
        cellHeight: extent,
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'the directory overflowed on every tile before this',
      );
    });

    testWidgets('does not overflow at the default text size', (tester) async {
      await _pumpCard(tester, textScale: 1.0, cellHeight: 130);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loses a line of label rather than painting outside the card', (
      tester,
    ) async {
      // A caller that ignores minExtentFor — a future grid, a narrower
      // breakpoint — must still not overflow. The Flexible is the guard.
      await _pumpCard(
        tester,
        textScale: AppSettingsModel.maxTextScale,
        cellHeight: 90,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('survives a long label at the largest text size', (
      tester,
    ) async {
      final extent = await _extentAt(tester, AppSettingsModel.maxTextScale);
      await _pumpCard(
        tester,
        textScale: AppSettingsModel.maxTextScale,
        cellHeight: extent,
        label: 'الثلث الأخير من الليل وأذكار الاستيقاظ',
      );

      expect(tester.takeException(), isNull);
    });
  });
}
