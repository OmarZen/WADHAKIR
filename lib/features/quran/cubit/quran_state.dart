import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/surah_model.dart';
import 'package:wadhakir/data/models/verse_model.dart';

abstract class QuranState extends Equatable {
  const QuranState();

  @override
  List<Object?> get props => [];
}

class QuranInitial extends QuranState {
  const QuranInitial();
}

class QuranLoading extends QuranState {
  const QuranLoading();
}

class SurahsLoaded extends QuranState {
  final List<SurahModel> surahs;

  const SurahsLoaded(this.surahs);

  @override
  List<Object?> get props => [surahs];
}

class SurahDetailsLoaded extends QuranState {
  final SurahModel surah;
  final List<VerseModel> verses;
  final String basmala;
  final bool showBasmala;

  const SurahDetailsLoaded({
    required this.surah,
    required this.verses,
    required this.basmala,
    required this.showBasmala,
  });

  @override
  List<Object?> get props => [surah, verses, basmala, showBasmala];
}

class QuranError extends QuranState {
  final String message;

  const QuranError(this.message);

  @override
  List<Object?> get props => [message];
}

class PlaceOfRevelationLoaded extends QuranState {
  final String placeOfRevelation;

  const PlaceOfRevelationLoaded(this.placeOfRevelation);

  @override
  List<Object?> get props => [placeOfRevelation];
}
