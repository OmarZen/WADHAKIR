import 'package:equatable/equatable.dart';

class SurahModel extends Equatable {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String nameTransliteration;
  final String placeOfRevelation;
  final int versesCount;

  const SurahModel({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.nameTransliteration,
    required this.placeOfRevelation,
    required this.versesCount,
  });

  @override
  List<Object?> get props => [
        number,
        nameArabic,
        nameEnglish,
        nameTransliteration,
        placeOfRevelation,
        versesCount
      ];

  // Factory method to create a SurahModel from a Map
  factory SurahModel.fromMap(Map<String, dynamic> map) {
    return SurahModel(
      number: map['number'],
      nameArabic: map['name'],
      nameEnglish: map['englishName'],
      nameTransliteration: map['englishNameTranslation'],
      placeOfRevelation: map['placeOfRevelation'],
      versesCount: map['numberOfAyahs'],
    );
  }
}
