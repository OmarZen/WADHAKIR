import 'package:quran/quran.dart' as quran;
import 'package:wadhakir/data/models/surah_model.dart';
import 'package:wadhakir/data/models/verse_model.dart';
import 'package:wadhakir/domain/repositories/quran_repository.dart';

class QuranRepositoryImpl implements QuranRepository {
  // Helper method to convert place of revelation from package format to app format
  String _convertPlaceOfRevelation(String place) {
    switch (place) {
      case 'Makkah':
        return 'Meccan';
      case 'Madinah':
        return 'Medinan';
      default:
        return place; // Return original if it's neither
    }
  }

  @override
  Future<List<SurahModel>> getSurahs() async {
    try {
      List<SurahModel> surahs = [];
      for (int i = 1; i <= 114; i++) {
        String place = quran.getPlaceOfRevelation(i);
        surahs.add(
          SurahModel(
            number: i,
            nameArabic: quran.getSurahNameArabic(i),
            nameEnglish: quran.getSurahName(i),
            nameTransliteration: quran.getSurahNameEnglish(i),
            placeOfRevelation: _convertPlaceOfRevelation(place),
            versesCount: quran.getVerseCount(i),
          ),
        );
      }
      return surahs;
    } catch (e) {
      throw Exception('Failed to load surahs: $e');
    }
  }

  @override
  Future<SurahModel> getSurahByNumber(int number) async {
    try {
      String place = quran.getPlaceOfRevelation(number);
      return SurahModel(
        number: number,
        nameArabic: quran.getSurahNameArabic(number),
        nameEnglish: quran.getSurahName(number),
        nameTransliteration: quran.getSurahNameEnglish(number),
        placeOfRevelation: _convertPlaceOfRevelation(place),
        versesCount: quran.getVerseCount(number),
      );
    } catch (e) {
      throw Exception('Failed to load surah: $e');
    }
  }

  @override
  Future<List<VerseModel>> getVersesBySurah(int surahNumber) async {
    try {
      List<VerseModel> verses = [];
      int verseCount = quran.getVerseCount(surahNumber);

      for (int i = 1; i <= verseCount; i++) {
        verses.add(
          VerseModel(
            number: i,
            surahNumber: surahNumber,
            text: quran.getVerse(surahNumber, i, verseEndSymbol: true),
            translation: quran.getVerseTranslation(surahNumber, i),
            sajdah: quran.isSajdahVerse(surahNumber, i),
          ),
        );
      }
      return verses;
    } catch (e) {
      throw Exception('Failed to load verses: $e');
    }
  }

  @override
  Future<VerseModel> getVerseByNumber(int surahNumber, int verseNumber) async {
    try {
      return VerseModel(
        number: verseNumber,
        surahNumber: surahNumber,
        text: quran.getVerse(surahNumber, verseNumber, verseEndSymbol: true),
        translation: quran.getVerseTranslation(surahNumber, verseNumber),
        sajdah: quran.isSajdahVerse(surahNumber, verseNumber),
      );
    } catch (e) {
      throw Exception('Failed to load verse: $e');
    }
  }

  @override
  Future<String> getBasmala() async {
    return quran.basmala;
  }

  @override
  Future<String> getSurahNameArabic(int surahNumber) async {
    return quran.getSurahNameArabic(surahNumber);
  }

  @override
  Future<String> getPlaceOfRevelation(int surahNumber) async {
    String place = quran.getPlaceOfRevelation(surahNumber);
    return _convertPlaceOfRevelation(place);
  }
}
