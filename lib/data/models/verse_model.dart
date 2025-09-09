import 'package:equatable/equatable.dart';

class VerseModel extends Equatable {
  final int number;
  final int surahNumber;
  final String text;
  final String translation;
  final bool sajdah;

  const VerseModel({
    required this.number,
    required this.surahNumber,
    required this.text,
    required this.translation,
    this.sajdah = false,
  });

  @override
  List<Object?> get props => [number, surahNumber, text, translation, sajdah];

  // Factory method to create a VerseModel from a Map
  factory VerseModel.fromMap(Map<String, dynamic> map) {
    return VerseModel(
      number: map['number'],
      surahNumber: map['surah']['number'],
      text: map['text'],
      translation: map['translation'] ?? '',
      sajdah: map['sajda'] ?? false,
    );
  }
}
