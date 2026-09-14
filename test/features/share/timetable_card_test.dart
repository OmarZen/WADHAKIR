import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';
import 'package:wadhakir/features/share/views/widgets/share_card.dart';

/// Roadmap #21 — the timetable card.
///
/// The variant exists for one reason: the other two centre a single text block,
/// so a timetable sent through them comes out ragged with no two times sharing
/// a column. The alignment IS the feature, so it is what these tests measure.

const _rows = [
  ShareTimetableRow(label: 'الفجر', value: '4:30 AM'),
  ShareTimetableRow(label: 'الشروق', value: '6:00 AM'),
  ShareTimetableRow(label: 'الظهر', value: '12:15 PM'),
  ShareTimetableRow(label: 'العصر', value: '3:45 PM'),
  ShareTimetableRow(label: 'المغرب', value: '6:40 PM'),
  ShareTimetableRow(label: 'العشاء', value: '8:05 PM'),
];

SharePayload _payload({
  List<ShareTimetableRow> rows = _rows,
  ShareCardRatio ratio = ShareCardRatio.story,
  String? reference = 'القاهرة · ٢١ ربيع الأول ١٤٤٧ هـ',
}) => SharePayload(
  headline: 'مواقيت الصلاة',
  categoryLabel: 'مواقيت الصلاة',
  reference: reference,
  variant: ShareCardVariant.timetable,
  timetableRows: rows,
  ratio: ratio,
);

/// Renders the card at a fixed width and returns the key wrapping it.
///
/// The surface is widened deliberately. The default 800×600 test view is
/// SHORTER than a 9:16 card at any sensible width, so every measurement comes
/// back clamped to the viewport's ratio — letterboxing, measured as if it were
/// the answer.
Future<GlobalKey> render(
  WidgetTester tester,
  SharePayload payload, {
  double width = 360,
}) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: width,
            child: RepaintBoundary(
              key: key,
              child: ShareCard(payload: payload),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return key;
}

void main() {
  testWidgets('the exported card ignores the reader\'s text size', (
    tester,
  ) async {
    // ShareCard calls itself pixel-deterministic, but every Text inside it
    // resolves MediaQuery.textScalerOf during its own build, and main.dart
    // installs a 0.9-1.6 scaler over the whole app. At 1.6 the timetable
    // subhead stopped fitting its two lines and ELLIPSIZED THE DATE OFF THE
    // CARD while the caption still carried it.
    //
    // The exported image is a fixed artefact for somebody else's screen. The
    // share screen pins it with MediaQuery.withNoTextScaling; this asserts the
    // card is unmoved by a scaler above it.
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<Size> sizeAt(double scale) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: SizedBox(
                width: 360,
                child: RepaintBoundary(
                  key: key,
                  child: MediaQuery.withNoTextScaling(
                    child: ShareCard(payload: _payload()),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return tester.getSize(find.text(_rows.first.value));
    }

    final plain = await sizeAt(1.0);
    final enlarged = await sizeAt(1.6);

    expect(
      enlarged.height,
      closeTo(plain.height, 0.5),
      reason: 'the card followed the reader\'s text scale',
    );
    expect(enlarged.width, closeTo(plain.width, 0.5));
  });

  testWidgets('the card is 9:16 like every other share card', (tester) async {
    final key = await render(tester, _payload());
    final size = tester.getSize(find.byKey(key));
    expect(size.width / size.height, closeTo(9 / 16, 0.01));
  });

  testWidgets('it honours the post ratio', (tester) async {
    final key = await render(tester, _payload(ratio: ShareCardRatio.post));
    final size = tester.getSize(find.byKey(key));
    expect(size.width / size.height, closeTo(4 / 5, 0.01));
  });

  testWidgets('every row reaches the card', (tester) async {
    await render(tester, _payload());
    for (final row in _rows) {
      expect(find.text(row.label), findsOneWidget);
      expect(find.text(row.value), findsOneWidget);
    }
  });

  testWidgets('the times share a column', (tester) async {
    // The claim the variant is built on. A list of Rows would size each line
    // independently and these edges would drift row to row.
    await render(tester, _payload());

    final lefts = _rows
        .map((r) => tester.getTopLeft(find.text(r.value)).dx)
        .toList();
    final rights = _rows
        .map((r) => tester.getTopRight(find.text(r.value)).dx)
        .toList();

    for (final left in lefts) {
      expect(left, closeTo(lefts.first, 0.5), reason: 'times drifted: $lefts');
    }
    for (final right in rights) {
      expect(right, closeTo(rights.first, 0.5));
    }
  });

  testWidgets('the labels share a column too', (tester) async {
    await render(tester, _payload());

    final rights = _rows
        .map((r) => tester.getTopRight(find.text(r.label)).dx)
        .toList();

    // RTL: the labels are the right-hand column, so it is their RIGHT edge
    // that has to line up.
    for (final right in rights) {
      expect(
        right,
        closeTo(rights.first, 0.5),
        reason: 'labels drifted: $rights',
      );
    }
  });

  testWidgets('the title and subhead are drawn', (tester) async {
    await render(tester, _payload());
    expect(find.text('مواقيت الصلاة'), findsOneWidget);
    expect(find.text('القاهرة · ٢١ ربيع الأول ١٤٤٧ هـ'), findsOneWidget);
  });

  testWidgets('a null subhead draws no subhead line', (tester) async {
    await render(tester, _payload(reference: null));
    expect(find.text('القاهرة · ٢١ ربيع الأول ١٤٤٧ هـ'), findsNothing);
    // The title survives on its own.
    expect(find.text('مواقيت الصلاة'), findsOneWidget);
  });

  testWidgets('no rows falls back to the ordinary card, not an empty table', (
    tester,
  ) async {
    // A timetable variant with nothing to tabulate would otherwise draw a
    // branded card with a blank middle.
    final key = await render(tester, _payload(rows: const []));

    expect(find.text('مواقيت الصلاة'), findsOneWidget);
    expect(find.byType(Table), findsNothing);
    final size = tester.getSize(find.byKey(key));
    expect(size.width / size.height, closeTo(9 / 16, 0.01));
  });

  testWidgets('a long label shrinks the table instead of overflowing', (
    tester,
  ) async {
    await render(
      tester,
      _payload(
        rows: const [
          ShareTimetableRow(
            label: 'الثلث الأخير من الليل والوقت الذي يليه مباشرة',
            value: '2:20 AM',
          ),
          ..._rows,
        ],
      ),
      width: 300,
    );

    // `tester.takeException()` is null only if nothing overflowed.
    expect(tester.takeException(), isNull);
  });
}
