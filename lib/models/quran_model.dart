/// Kuran ayeti modeli
class QuranVerse {
  final int surahNumber;
  final String surahName;
  final String surahNameArabic;
  final int verseNumber;
  final String arabicText;
  final String turkishTranslation;
  final String englishTranslation;

  const QuranVerse({
    required this.surahNumber,
    required this.surahName,
    required this.surahNameArabic,
    required this.verseNumber,
    required this.arabicText,
    required this.turkishTranslation,
    required this.englishTranslation,
  });
}
