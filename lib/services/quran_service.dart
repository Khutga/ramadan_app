import '../models/quran_model.dart';

class QuranService {
  static const List<QuranVerse> _verses = [
    QuranVerse(
      surahNumber: 2,
      surahName: 'Bakara',
      surahNameArabic: 'البقرة',
      verseNumber: 185,
      arabicText:
          'شَهْرُ رَمَضَانَ الَّذِي أُنزِلَ فِيهِ الْقُرْآنُ هُدًى لِّلنَّاسِ وَبَيِّنَاتٍ مِّنَ الْهُدَىٰ وَالْفُرْقَانِ',
      turkishTranslation:
          'Ramazan ayı, insanlara yol gösterici, doğrunun ve doğruyu eğriden ayırmanın açık delilleri olarak Kur\'an\'ın indirildiği aydır.',
      englishTranslation:
          'The month of Ramadan in which was revealed the Quran, a guidance for mankind and clear proofs of guidance and criterion.',
    ),
    QuranVerse(
      surahNumber: 2,
      surahName: 'Bakara',
      surahNameArabic: 'البقرة',
      verseNumber: 183,
      arabicText:
          'يَا أَيُّهَا الَّذِينَ آمَنُوا كُتِبَ عَلَيْكُمُ الصِّيَامُ كَمَا كُتِبَ عَلَى الَّذِينَ مِن قَبْلِكُمْ لَعَلَّكُمْ تَتَّقُونَ',
      turkishTranslation:
          'Ey iman edenler! Oruç, sizden öncekilere farz kılındığı gibi size de farz kılındı. Umulur ki korunursunuz.',
      englishTranslation:
          'O you who believe! Fasting is prescribed for you as it was prescribed for those before you, that you may attain piety.',
    ),
    QuranVerse(
      surahNumber: 97,
      surahName: 'Kadir',
      surahNameArabic: 'القدر',
      verseNumber: 1,
      arabicText: 'إِنَّا أَنزَلْنَاهُ فِي لَيْلَةِ الْقَدْرِ',
      turkishTranslation:
          'Şüphesiz, biz onu Kadir gecesinde indirdik.',
      englishTranslation:
          'Indeed, We sent the Quran down during the Night of Decree.',
    ),
    QuranVerse(
      surahNumber: 97,
      surahName: 'Kadir',
      surahNameArabic: 'القدر',
      verseNumber: 3,
      arabicText: 'لَيْلَةُ الْقَدْرِ خَيْرٌ مِّنْ أَلْفِ شَهْرٍ',
      turkishTranslation:
          'Kadir gecesi bin aydan daha hayırlıdır.',
      englishTranslation:
          'The Night of Decree is better than a thousand months.',
    ),
    QuranVerse(
      surahNumber: 2,
      surahName: 'Bakara',
      surahNameArabic: 'البقرة',
      verseNumber: 186,
      arabicText:
          'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ',
      turkishTranslation:
          'Kullarım sana beni sorduğunda, bilsinler ki ben çok yakınım. Bana dua ettiğinde dua edenin duasına karşılık veririm.',
      englishTranslation:
          'And when My servants ask you about Me, indeed I am near. I respond to the invocation of the supplicant when he calls upon Me.',
    ),
    QuranVerse(
      surahNumber: 1,
      surahName: 'Fatiha',
      surahNameArabic: 'الفاتحة',
      verseNumber: 1,
      arabicText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      turkishTranslation:
          'Rahman ve Rahîm olan Allah\'ın adıyla.',
      englishTranslation:
          'In the name of Allah, the Most Gracious, the Most Merciful.',
    ),
    QuranVerse(
      surahNumber: 112,
      surahName: 'İhlas',
      surahNameArabic: 'الإخلاص',
      verseNumber: 1,
      arabicText: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
      turkishTranslation: 'De ki: O, Allah\'tır, bir tektir.',
      englishTranslation: 'Say: He is Allah, the One.',
    ),
    QuranVerse(
      surahNumber: 3,
      surahName: 'Âl-i İmrân',
      surahNameArabic: 'آل عمران',
      verseNumber: 185,
      arabicText:
          'كُلُّ نَفْسٍ ذَائِقَةُ الْمَوْتِ ۗ وَإِنَّمَا تُوَفَّوْنَ أُجُورَكُمْ يَوْمَ الْقِيَامَةِ',
      turkishTranslation:
          'Her canlı ölümü tadacaktır. Kıyamet günü yaptıklarınızın karşılığı size tastamam verilecektir.',
      englishTranslation:
          'Every soul will taste death, and you will only be given your full compensation on the Day of Resurrection.',
    ),
    QuranVerse(
      surahNumber: 94,
      surahName: 'İnşirah',
      surahNameArabic: 'الشرح',
      verseNumber: 5,
      arabicText: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
      turkishTranslation:
          'Şüphesiz güçlükle birlikte bir kolaylık vardır.',
      englishTranslation:
          'For indeed, with hardship will be ease.',
    ),
    QuranVerse(
      surahNumber: 94,
      surahName: 'İnşirah',
      surahNameArabic: 'الشرح',
      verseNumber: 6,
      arabicText: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
      turkishTranslation:
          'Gerçekten, güçlükle birlikte bir kolaylık daha vardır.',
      englishTranslation:
          'Indeed, with hardship will be ease.',
    ),
    QuranVerse(
      surahNumber: 55,
      surahName: 'Rahmân',
      surahNameArabic: 'الرحمن',
      verseNumber: 13,
      arabicText: 'فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ',
      turkishTranslation:
          'Öyleyse Rabbinizin hangi nimetlerini yalanlayabilirsiniz?',
      englishTranslation:
          'So which of the favors of your Lord would you deny?',
    ),
    QuranVerse(
      surahNumber: 13,
      surahName: 'Ra\'d',
      surahNameArabic: 'الرعد',
      verseNumber: 28,
      arabicText:
          'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      turkishTranslation:
          'Bilesiniz ki, kalpler ancak Allah\'ı anmakla huzur bulur.',
      englishTranslation:
          'Verily, in the remembrance of Allah do hearts find rest.',
    ),
    QuranVerse(
      surahNumber: 2,
      surahName: 'Bakara',
      surahNameArabic: 'البقرة',
      verseNumber: 255,
      arabicText:
          'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
      turkishTranslation:
          'Allah, O\'ndan başka ilah yoktur; O, hayydir, kayyûmdur. Onu ne uyuklama tutabilir, ne de uyku.',
      englishTranslation:
          'Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep.',
    ),
    QuranVerse(
      surahNumber: 33,
      surahName: 'Ahzâb',
      surahNameArabic: 'الأحزاب',
      verseNumber: 56,
      arabicText:
          'إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ',
      turkishTranslation:
          'Şüphesiz Allah ve melekleri Peygamber\'e salat ederler.',
      englishTranslation:
          'Indeed, Allah and His angels send blessings upon the Prophet.',
    ),
    QuranVerse(
      surahNumber: 49,
      surahName: 'Hucurât',
      surahNameArabic: 'الحجرات',
      verseNumber: 13,
      arabicText:
          'إِنَّ أَكْرَمَكُمْ عِندَ اللَّهِ أَتْقَاكُمْ',
      turkishTranslation:
          'Şüphesiz, Allah katında en değerliniz, en çok takva sahibi olanınızdır.',
      englishTranslation:
          'Indeed, the most noble of you in the sight of Allah is the most righteous of you.',
    ),
    QuranVerse(
      surahNumber: 39,
      surahName: 'Zümer',
      surahNameArabic: 'الزمر',
      verseNumber: 53,
      arabicText:
          'قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ',
      turkishTranslation:
          'De ki: Ey kendilerine kötülük edip aşırı giden kullarım! Allah\'ın rahmetinden umudunuzu kesmeyin.',
      englishTranslation:
          'Say: O My servants who have transgressed against themselves, do not despair of the mercy of Allah.',
    ),
    QuranVerse(
      surahNumber: 67,
      surahName: 'Mülk',
      surahNameArabic: 'الملك',
      verseNumber: 1,
      arabicText:
          'تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
      turkishTranslation:
          'Mülk elinde bulunan Allah, yüceler yücesidir ve O\'nun her şeye gücü yeter.',
      englishTranslation:
          'Blessed is He in whose hand is dominion, and He is over all things competent.',
    ),
    QuranVerse(
      surahNumber: 23,
      surahName: 'Mü\'minûn',
      surahNameArabic: 'المؤمنون',
      verseNumber: 1,
      arabicText: 'قَدْ أَفْلَحَ الْمُؤْمِنُونَ',
      turkishTranslation: 'Müminler gerçekten kurtuluşa ermiştir.',
      englishTranslation:
          'Certainly will the believers have succeeded.',
    ),
    QuranVerse(
      surahNumber: 3,
      surahName: 'Âl-i İmrân',
      surahNameArabic: 'آل عمران',
      verseNumber: 139,
      arabicText:
          'وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ إِن كُنتُم مُّؤْمِنِينَ',
      turkishTranslation:
          'Gevşemeyin, üzülmeyin! Eğer iman ediyorsanız üstün olan sizlersiniz.',
      englishTranslation:
          'So do not weaken and do not grieve, and you will be superior if you are true believers.',
    ),
    QuranVerse(
      surahNumber: 65,
      surahName: 'Talâk',
      surahNameArabic: 'الطلاق',
      verseNumber: 3,
      arabicText:
          'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
      turkishTranslation:
          'Kim Allah\'a tevekkül ederse, O ona yeter.',
      englishTranslation:
          'And whoever relies upon Allah - then He is sufficient for him.',
    ),
    QuranVerse(
      surahNumber: 2,
      surahName: 'Bakara',
      surahNameArabic: 'البقرة',
      verseNumber: 152,
      arabicText:
          'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
      turkishTranslation:
          'Öyleyse siz beni anın ki ben de sizi anayım. Bana şükredin, nankörlük etmeyin.',
      englishTranslation:
          'So remember Me; I will remember you. And be grateful to Me and do not deny Me.',
    ),
    QuranVerse(
      surahNumber: 4,
      surahName: 'Nisâ',
      surahNameArabic: 'النساء',
      verseNumber: 32,
      arabicText:
          'وَاسْأَلُوا اللَّهَ مِن فَضْلِهِ',
      turkishTranslation: 'Allah\'tan O\'nun lütfunu isteyin.',
      englishTranslation: 'And ask Allah of His bounty.',
    ),
    QuranVerse(
      surahNumber: 29,
      surahName: 'Ankebût',
      surahNameArabic: 'العنكبوت',
      verseNumber: 69,
      arabicText:
          'وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا',
      turkishTranslation:
          'Bizim uğrumuzda çaba harcayanlara biz elbette yollarımızı gösteririz.',
      englishTranslation:
          'And those who strive for Us, We will surely guide them to Our ways.',
    ),
    QuranVerse(
      surahNumber: 73,
      surahName: 'Müzzemmil',
      surahNameArabic: 'المزمل',
      verseNumber: 20,
      arabicText: 'وَأَقِيمُوا الصَّلَاةَ وَآتُوا الزَّكَاةَ وَأَقْرِضُوا اللَّهَ قَرْضًا حَسَنًا',
      turkishTranslation:
          'Namazı kılın, zekâtı verin ve Allah\'a güzel bir borç verin.',
      englishTranslation:
          'And establish prayer and give zakah and loan Allah a goodly loan.',
    ),
    QuranVerse(
      surahNumber: 57,
      surahName: 'Hadîd',
      surahNameArabic: 'الحديد',
      verseNumber: 4,
      arabicText: 'وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ',
      turkishTranslation: 'Nerede olsanız O sizinle beraberdir.',
      englishTranslation:
          'And He is with you wherever you are.',
    ),
    QuranVerse(
      surahNumber: 16,
      surahName: 'Nahl',
      surahNameArabic: 'النحل',
      verseNumber: 128,
      arabicText:
          'إِنَّ اللَّهَ مَعَ الَّذِينَ اتَّقَوا وَّالَّذِينَ هُم مُّحْسِنُونَ',
      turkishTranslation:
          'Şüphesiz Allah, takva sahipleri ve iyilik yapanlarla beraberdir.',
      englishTranslation:
          'Indeed, Allah is with those who fear Him and those who are doers of good.',
    ),
    QuranVerse(
      surahNumber: 40,
      surahName: 'Mü\'min',
      surahNameArabic: 'غافر',
      verseNumber: 60,
      arabicText:
          'وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ',
      turkishTranslation:
          'Rabbiniz şöyle buyurdu: Bana dua edin, kabul edeyim.',
      englishTranslation:
          'And your Lord says: Call upon Me; I will respond to you.',
    ),
    QuranVerse(
      surahNumber: 20,
      surahName: 'Tâ-Hâ',
      surahNameArabic: 'طه',
      verseNumber: 114,
      arabicText: 'وَقُل رَّبِّ زِدْنِي عِلْمًا',
      turkishTranslation: 'Ve de ki: Rabbim, ilmimi artır.',
      englishTranslation: 'And say: My Lord, increase me in knowledge.',
    ),
    QuranVerse(
      surahNumber: 2,
      surahName: 'Bakara',
      surahNameArabic: 'البقرة',
      verseNumber: 286,
      arabicText:
          'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
      turkishTranslation:
          'Allah, hiçbir kimseyi gücünün yetmediği bir şeyle yükümlü kılmaz.',
      englishTranslation:
          'Allah does not burden a soul beyond that it can bear.',
    ),
    QuranVerse(
      surahNumber: 12,
      surahName: 'Yûsuf',
      surahNameArabic: 'يوسف',
      verseNumber: 87,
      arabicText:
          'وَلَا تَيْأَسُوا مِن رَّوْحِ اللَّهِ ۖ إِنَّهُ لَا يَيْأَسُ مِن رَّوْحِ اللَّهِ إِلَّا الْقَوْمُ الْكَافِرُونَ',
      turkishTranslation:
          'Allah\'ın rahmetinden ümit kesmeyin. Çünkü kâfirler topluluğundan başkası Allah\'ın rahmetinden ümit kesmez.',
      englishTranslation:
          'And despair not of relief from Allah. Indeed, no one despairs of relief from Allah except the disbelieving people.',
    ),
  ];

  static QuranVerse getDailyVerse() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _verses.length;
    return _verses[index];
  }

  static QuranVerse getVerseForRamadanDay(int day) {
    final index = (day - 1) % _verses.length;
    return _verses[index];
  }

  static QuranVerse getRandomVerse() {
    final index = DateTime.now().millisecondsSinceEpoch % _verses.length;
    return _verses[index];
  }

  static List<QuranVerse> getAllVerses() => _verses;
}
