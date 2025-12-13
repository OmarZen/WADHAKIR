import 'package:flutter/material.dart';

/// Metadata about hadith collections (Bukhari, Muslim, etc.)
class HadithCollectionMetadata {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String description;
  final int totalBooks;
  final int totalHadiths;
  final Color color;
  final IconData icon;
  final List<String> availableLanguages;
  final bool isPopular;

  const HadithCollectionMetadata({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.description,
    required this.totalBooks,
    required this.totalHadiths,
    required this.color,
    required this.icon,
    required this.availableLanguages,
    this.isPopular = false,
  });

  /// Get all available collections
  static List<HadithCollectionMetadata> getAllCollections() {
    return [
      HadithCollectionMetadata(
        id: 'bukhari',
        nameArabic: 'صحيح البخاري',
        nameEnglish: 'Sahih Bukhari',
        description:
            'The most authentic hadith collection compiled by Imam Bukhari',
        totalBooks: 97,
        totalHadiths: 7563,
        color: const Color(0xFF10B981), // Emerald
        icon: Icons.menu_book_rounded,
        availableLanguages: ['arabic', 'english', 'urdu', 'bangla'],
        isPopular: true,
      ),
      HadithCollectionMetadata(
        id: 'muslim',
        nameArabic: 'صحيح مسلم',
        nameEnglish: 'Sahih Muslim',
        description:
            'The second most authentic hadith collection compiled by Imam Muslim',
        totalBooks: 54,
        totalHadiths: 7190,
        color: const Color(0xFF3B82F6), // Blue
        icon: Icons.auto_stories_rounded,
        availableLanguages: ['arabic', 'english'],
        isPopular: true,
      ),
      HadithCollectionMetadata(
        id: 'abudawud',
        nameArabic: 'سنن أبي داود',
        nameEnglish: 'Sunan Abu Dawud',
        description:
            'One of the six major hadith collections (Kutub al-Sittah)',
        totalBooks: 43,
        totalHadiths: 5274,
        color: const Color(0xFF8B5CF6), // Purple
        icon: Icons.book_rounded,
        availableLanguages: ['arabic', 'english', 'urdu'],
        isPopular: true,
      ),
      HadithCollectionMetadata(
        id: 'tirmidhi',
        nameArabic: 'جامع الترمذي',
        nameEnglish: 'Jami` at-Tirmidhi',
        description: 'Collection by Imam at-Tirmidhi, part of Kutub al-Sittah',
        totalBooks: 46,
        totalHadiths: 3956,
        color: const Color(0xFFF59E0B), // Amber
        icon: Icons.library_books_rounded,
        availableLanguages: ['arabic', 'english'],
        isPopular: true,
      ),
      HadithCollectionMetadata(
        id: 'ibnmajah',
        nameArabic: 'سنن ابن ماجه',
        nameEnglish: 'Sunan Ibn Majah',
        description: 'Collection by Imam Ibn Majah, part of Kutub al-Sittah',
        totalBooks: 37,
        totalHadiths: 4341,
        color: const Color(0xFFEC4899), // Pink
        icon: Icons.import_contacts_rounded,
        availableLanguages: ['arabic', 'english', 'urdu'],
        isPopular: false,
      ),
      HadithCollectionMetadata(
        id: 'nasai',
        nameArabic: 'سنن النسائي',
        nameEnglish: 'Sunan an-Nasa\'i',
        description: 'Collection by Imam an-Nasa\'i, part of Kutub al-Sittah',
        totalBooks: 51,
        totalHadiths: 5758,
        color: const Color(0xFF14B8A6), // Teal
        icon: Icons.chrome_reader_mode_rounded,
        availableLanguages: ['arabic', 'english'],
        isPopular: false,
      ),
      HadithCollectionMetadata(
        id: 'malik',
        nameArabic: 'موطأ مالك',
        nameEnglish: 'Muwatta Malik',
        description: 'The earliest written collection by Imam Malik',
        totalBooks: 61,
        totalHadiths: 1594,
        color: const Color(0xFF06B6D4), // Cyan
        icon: Icons.article_rounded,
        availableLanguages: ['arabic', 'english'],
        isPopular: false,
      ),
      HadithCollectionMetadata(
        id: 'riyadussalihin',
        nameArabic: 'رياض الصالحين',
        nameEnglish: 'Riyad as-Salihin',
        description: 'Gardens of the Righteous by Imam an-Nawawi',
        totalBooks: 19,
        totalHadiths: 1896,
        color: const Color(0xFFEF4444), // Red
        icon: Icons.park_rounded,
        availableLanguages: ['arabic', 'english'],
        isPopular: true,
      ),
      HadithCollectionMetadata(
        id: 'forty',
        nameArabic: 'الأربعون النووية',
        nameEnglish: '40 Hadith Nawawi',
        description: 'Forty essential hadiths compiled by Imam an-Nawawi',
        totalBooks: 1,
        totalHadiths: 42,
        color: const Color(0xFF6366F1), // Indigo
        icon: Icons.filter_4_rounded,
        availableLanguages: ['arabic', 'english'],
        isPopular: true,
      ),
      HadithCollectionMetadata(
        id: 'bulugh',
        nameArabic: 'بلوغ المرام',
        nameEnglish: 'Bulugh al-Maram',
        description: 'Attainment of the Objective by Ibn Hajar',
        totalBooks: 16,
        totalHadiths: 1358,
        color: const Color(0xFF84CC16), // Lime
        icon: Icons.bolt_rounded,
        availableLanguages: ['arabic', 'english'],
        isPopular: false,
      ),
      HadithCollectionMetadata(
        id: 'adab',
        nameArabic: 'الأدب المفرد',
        nameEnglish: 'Al-Adab Al-Mufrad',
        description: 'Excellence of Character by Imam Bukhari',
        totalBooks: 55,
        totalHadiths: 1322,
        color: const Color(0xFFA855F7), // Purple
        icon: Icons.favorite_rounded,
        availableLanguages: ['arabic', 'english'],
        isPopular: false,
      ),
      HadithCollectionMetadata(
        id: 'shamail',
        nameArabic: 'الشمائل المحمدية',
        nameEnglish: 'Shama\'il Muhammadiyah',
        description: 'The Prophetic Qualities by Imam at-Tirmidhi',
        totalBooks: 55,
        totalHadiths: 415,
        color: const Color(0xFFF97316), // Orange
        icon: Icons.star_rounded,
        availableLanguages: ['arabic', 'english'],
        isPopular: false,
      ),
      HadithCollectionMetadata(
        id: 'mishkat',
        nameArabic: 'مشكاة المصابيح',
        nameEnglish: 'Mishkat al-Masabih',
        description: 'Niche of Lamps - comprehensive hadith compilation',
        totalBooks: 29,
        totalHadiths: 5945,
        color: const Color(0xFFEAB308), // Yellow
        icon: Icons.wb_incandescent_rounded,
        availableLanguages: ['arabic', 'english'],
        isPopular: false,
      ),
      HadithCollectionMetadata(
        id: 'ahmad',
        nameArabic: 'مسند أحمد',
        nameEnglish: 'Musnad Ahmad',
        description: 'The Musnad of Imam Ahmad ibn Hanbal',
        totalBooks: 52,
        totalHadiths: 27647,
        color: const Color(0xFF0EA5E9), // Sky
        icon: Icons.account_balance_rounded,
        availableLanguages: ['arabic', 'english'],
        isPopular: false,
      ),
      HadithCollectionMetadata(
        id: 'darimi',
        nameArabic: 'سنن الدارمي',
        nameEnglish: 'Sunan ad-Darimi',
        description: 'Collection by Imam ad-Darimi',
        totalBooks: 28,
        totalHadiths: 3503,
        color: const Color(0xFF7C3AED), // Violet
        icon: Icons.menu_book_outlined,
        availableLanguages: ['arabic'],
        isPopular: false,
      ),
    ];
  }

  /// Get collection by ID
  static HadithCollectionMetadata? getById(String id) {
    try {
      return getAllCollections().firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get popular collections
  static List<HadithCollectionMetadata> getPopularCollections() {
    return getAllCollections().where((c) => c.isPopular).toList();
  }
}
