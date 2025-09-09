import 'package:wadhakir/data/models/surah_model.dart';
import 'package:wadhakir/data/models/verse_model.dart';

abstract class QuranRepository {
  Future<List<SurahModel>> getSurahs();

  Future<SurahModel> getSurahByNumber(int number);

  Future<List<VerseModel>> getVersesBySurah(int surahNumber);

  Future<VerseModel> getVerseByNumber(int surahNumber, int verseNumber);

  Future<String> getBasmala();

  Future<String> getSurahNameArabic(int surahNumber);

  Future<String> getPlaceOfRevelation(int surahNumber);
}
