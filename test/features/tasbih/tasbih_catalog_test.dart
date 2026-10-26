import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/features/tasbih/data/tasbih_catalog.dart';

/// The tasbih's adhkar are sacred text. They must be the app's own text,
/// code point for code point — `tassbih.json` orders shadda and fatha
/// differently from entry to entry, so a retyped string can look right and
/// still differ — and their ids are stored on users' phones.

Map<String, Object?> _tassbih() =>
    jsonDecode(File('assets/json_data/tassbih.json').readAsStringSync())
        as Map<String, Object?>;

List<Object?> _adhkar() =>
    jsonDecode(File('assets/json_data/adhkar.json').readAsStringSync())
        as List<Object?>;

String _tassbihText(int i) =>
    ((_tassbih()['content']! as List)[i] as Map)['text'] as String;

void main() {
  group('ids', () {
    test('are exactly these, in this order', () {
      // Append-only. A renamed id orphans every count saved under it.
      expect(TasbihCatalog.all.map((d) => d.id).toList(), [
        'subhan_allah',
        'alhamdulillah',
        'allahu_akbar',
        'la_ilaha_illallah',
        'subhan_allah_wa_bihamdihi',
        'astaghfirullah',
        'la_hawla',
        'salawat',
      ]);
    });

    test('are unique, and the first is the migration target', () {
      final ids = TasbihCatalog.all.map((d) => d.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids.first, TasbihCatalog.firstId);
      expect(TasbihCatalog.indexOf('salawat'), 7);
      expect(TasbihCatalog.indexOf('nope'), -1);
      expect(TasbihCatalog.byId('la_hawla')?.defaultTarget, 100);
    });
  });

  group('texts are the source JSON, code point for code point', () {
    // Each one against the exact entry the generator slices it from.
    final sources = <String, String Function()>{
      'subhan_allah': () => _tassbihText(0),
      'alhamdulillah': () => _tassbihText(2),
      'allahu_akbar': () => _tassbihText(15),
      'la_ilaha_illallah': () => _tassbihText(11),
      'subhan_allah_wa_bihamdihi': () => _tassbihText(1),
      'astaghfirullah': () =>
          (((_adhkar()[26]! as Map)['array'] as List)[0] as Map)['text']
              as String,
      'la_hawla': () => _tassbihText(6),
      'salawat': () => _tassbihText(16),
    };

    for (final dhikr in TasbihCatalog.all) {
      test(dhikr.id, () {
        final source = sources[dhikr.id];
        expect(source, isNotNull, reason: 'every dhikr cites its source');
        expect(
          source!().contains(dhikr.text),
          isTrue,
          reason: '${dhikr.id} must be a verbatim slice of its source',
        );
        expect(dhikr.text.trim(), dhikr.text);
        expect(dhikr.text, isNot(endsWith('.')));
        expect(dhikr.text, isNot(contains('(')));
      });
    }

    test('whole entries are used whole', () {
      // These four are the entire entry minus its full stop, so the tasbih
      // shows exactly what the «تسابيح» sheet shows.
      String whole(int i) {
        final t = _tassbihText(i);
        return t.substring(0, t.length - 1);
      }

      expect(TasbihCatalog.byId('subhan_allah')!.text, whole(0));
      expect(TasbihCatalog.byId('subhan_allah_wa_bihamdihi')!.text, whole(1));
      expect(TasbihCatalog.byId('la_hawla')!.text, whole(6));
      expect(TasbihCatalog.byId('la_ilaha_illallah')!.text, whole(11));
    });
  });

  test('default targets: 33 for the three tasbihat, 100 for the rest', () {
    expect(
      {for (final d in TasbihCatalog.all) d.id: d.defaultTarget},
      {
        'subhan_allah': 33,
        'alhamdulillah': 33,
        'allahu_akbar': 33,
        'la_ilaha_illallah': 100,
        'subhan_allah_wa_bihamdihi': 100,
        'astaghfirullah': 100,
        'la_hawla': 100,
        'salawat': 100,
      },
    );
  });

  test('tassbih.json is untouched: still 17 entries', () {
    // Its texts key the «تسابيح» sheet's counters by hashCode; editing the
    // file would orphan them. The tasbih reads it, never writes it.
    expect((_tassbih()['content']! as List), hasLength(17));
  });
}
