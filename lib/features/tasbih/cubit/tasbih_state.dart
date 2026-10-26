import 'package:equatable/equatable.dart';

import '../data/tasbih_catalog.dart';
import '../data/tasbih_models.dart';

class TasbihState extends Equatable {
  const TasbihState({
    required this.loading,
    required this.snapshot,
    required this.lifetimeTotal,
    required this.prefs,
    required this.completionTick,
    required this.lastCompletedRound,
    required this.lastCompletedId,
  });

  factory TasbihState.initial(String day) => TasbihState(
    loading: true,
    snapshot: TasbihSnapshot.fresh(day),
    lifetimeTotal: 0,
    prefs: const TasbihPrefs(),
    completionTick: 0,
    lastCompletedRound: 0,
    lastCompletedId: null,
  );

  /// Until the stored counts are read. Taps are ignored meanwhile — counting
  /// on top of the fresh placeholder would overwrite the real numbers.
  final bool loading;

  final TasbihSnapshot snapshot;

  /// Every tasbiha ever counted here; `electronic_tasbih_total`.
  final int lifetimeTotal;

  final TasbihPrefs prefs;

  /// Goes up by one each time a round completes, so a view can react to the
  /// event (hold the ring full, announce it) without comparing counts.
  final int completionTick;

  /// The round number that [completionTick] last announced, and whose dhikr
  /// it was — with auto-advance on, that is no longer the selected one.
  final int lastCompletedRound;
  final String? lastCompletedId;

  List<DhikrProgress> get items => snapshot.items;
  int get selectedIndex => snapshot.selectedIndex;
  DhikrProgress get selected => snapshot.selected;
  TasbihDhikr get dhikr => TasbihCatalog.all[snapshot.selectedIndex];
  int get todayTotal => snapshot.todayTotal;
  TasbihMode get mode => prefs.mode;

  /// Whether the screen should be held on. Focus mode always wants it: it
  /// exists for long counts with the phone set down.
  bool get wantsScreenOn =>
      prefs.keepScreenOn || prefs.mode == TasbihMode.focus;

  /// Nothing to reset: the reset button is disabled.
  bool get selectedIsClear => selected.count == 0 && selected.roundsToday == 0;

  TasbihState copyWith({
    bool? loading,
    TasbihSnapshot? snapshot,
    int? lifetimeTotal,
    TasbihPrefs? prefs,
    int? completionTick,
    int? lastCompletedRound,
    String? lastCompletedId,
  }) => TasbihState(
    loading: loading ?? this.loading,
    snapshot: snapshot ?? this.snapshot,
    lifetimeTotal: lifetimeTotal ?? this.lifetimeTotal,
    prefs: prefs ?? this.prefs,
    completionTick: completionTick ?? this.completionTick,
    lastCompletedRound: lastCompletedRound ?? this.lastCompletedRound,
    lastCompletedId: lastCompletedId ?? this.lastCompletedId,
  );

  @override
  List<Object?> get props => [
    loading,
    snapshot,
    lifetimeTotal,
    prefs,
    completionTick,
    lastCompletedRound,
    lastCompletedId,
  ];
}
