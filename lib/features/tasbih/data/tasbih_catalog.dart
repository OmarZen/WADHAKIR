import 'tasbih_texts.dart';

/// One dhikr the tasbih can count.
class TasbihDhikr {
  const TasbihDhikr({
    required this.id,
    required this.text,
    required this.defaultTarget,
  });

  /// Persisted inside `electronic_tasbih_state_v2` as the key of this dhikr's
  /// counts, and as the selected dhikr. Renaming one orphans every count a
  /// user has saved against it, so ids are append-only — see
  /// `tasbih_catalog_test.dart`, which pins them.
  final String id;

  /// Verbatim from the app's adhkar JSON; see `tasbih_texts.dart`.
  final String text;

  /// 33 for the three post-prayer tasbihat, 100 for the rest — the counts the
  /// sunnah attaches to them.
  final int defaultTarget;
}

/// The adhkar the carousel cycles through, in carousel order.
///
/// Deliberately not read from `tassbih.json` at runtime. That file feeds the
/// «تسابيح» sheet, whose counters are keyed by `String.hashCode` of the text;
/// the tasbih keeps its own counters under stable ids instead, so the two can
/// never collide and the sheet's keys are left exactly as they are.
abstract final class TasbihCatalog {
  static const List<TasbihDhikr> all = [
    TasbihDhikr(
      id: 'subhan_allah',
      text: TasbihTexts.subhanAllah,
      defaultTarget: 33,
    ),
    TasbihDhikr(
      id: 'alhamdulillah',
      text: TasbihTexts.alhamdulillah,
      defaultTarget: 33,
    ),
    TasbihDhikr(
      id: 'allahu_akbar',
      text: TasbihTexts.allahuAkbar,
      defaultTarget: 33,
    ),
    TasbihDhikr(
      id: 'la_ilaha_illallah',
      text: TasbihTexts.laIlahaIllallah,
      defaultTarget: 100,
    ),
    TasbihDhikr(
      id: 'subhan_allah_wa_bihamdihi',
      text: TasbihTexts.subhanAllahWaBihamdihi,
      defaultTarget: 100,
    ),
    TasbihDhikr(
      id: 'astaghfirullah',
      text: TasbihTexts.astaghfirullah,
      defaultTarget: 100,
    ),
    TasbihDhikr(id: 'la_hawla', text: TasbihTexts.laHawla, defaultTarget: 100),
    TasbihDhikr(id: 'salawat', text: TasbihTexts.salawat, defaultTarget: 100),
  ];

  /// The dhikr a fresh install opens on, and the one the pre-3.4.4 single
  /// counter migrates into — the old screen showed no text, and «سبحان الله»
  /// is what people counted on it.
  static const String firstId = 'subhan_allah';

  static int indexOf(String id) => all.indexWhere((d) => d.id == id);

  static TasbihDhikr? byId(String id) {
    final i = indexOf(id);
    return i < 0 ? null : all[i];
  }
}
