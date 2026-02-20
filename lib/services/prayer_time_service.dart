import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:adhan/adhan.dart' as adhan;
import '../models/prayer_model.dart';

class PrayerTimeService {
  // ✅ Günlük cache — aynı gün için API'ye tekrar istek atmaz
  static final Map<String, List<PrayerTimeModel>> _cache = {};

  /// Cache key: "2026-02-19_40.18_29.06_13_1"
  static String _cacheKey(
      DateTime date, double lat, double lng, int method, int school) {
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return "${dateStr}_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}_${method}_$school";
  }

  /// Hesaplama metodu → API method numarası
  static int _getMethodNumber(MadhhabType madhhab, SunniMethod sunniMethod) {
    if (madhhab == MadhhabType.shia) return 7; // Tehran
    switch (sunniMethod) {
      case SunniMethod.diyanet:
        return 13; // Diyanet İşleri Başkanlığı
      case SunniMethod.muslimWorldLeague:
        return 3; // MWL
      case SunniMethod.isna:
        return 2; // ISNA
      case SunniMethod.egypt:
        return 5; // Egyptian
      case SunniMethod.umm_al_qura:
        return 4; // Umm al-Qura
    }
  }

  /// Hanefi/Şafi → API school parametresi
  /// ⚠️ Diyanet, İkindi'yi standart (Şafi) yöntemle hesaplar
  /// Hanafi (school=1) İkindi'yi ~40-45dk geç verir
  static int _getSchool(MadhhabType madhhab, SunniMethod sunniMethod) {
    if (madhhab == MadhhabType.shia) return 0;
    switch (sunniMethod) {
      case SunniMethod.diyanet:
        return 0; // ✅ FIX: Diyanet standart Asr kullanır (school=0)
      case SunniMethod.egypt:
        return 0; // Shafi
      default:
        return 1; // Hanafi
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ANA METOD: API'den çek, başarısız olursa offline hesapla
  // ═══════════════════════════════════════════════════════════════

  static Future<List<PrayerTimeModel>> fetchPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required MadhhabType madhhab,
    SunniMethod sunniMethod = SunniMethod.diyanet,
  }) async {
    final method = _getMethodNumber(madhhab, sunniMethod);
    final school = _getSchool(madhhab, sunniMethod);
    final key = _cacheKey(date, latitude, longitude, method, school);

    // Cache'de varsa direkt dön
    if (_cache.containsKey(key)) {
      debugPrint('📦 Namaz vakitleri cache\'den okundu');
      return _cache[key]!;
    }

    try {
      final dateStr =
          "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/$dateStr'
        '?latitude=$latitude'
        '&longitude=$longitude'
        '&method=$method'
        '&school=$school',
      );

      debugPrint('🌐 Aladhan API isteği: $url');

      final response = await http.get(url).timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('API timeout'),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final timings = json['data']['timings'] as Map<String, dynamic>;

        debugPrint('═══ API NAMAZ VAKİTLERİ ═══');
        debugPrint('Konum: $latitude, $longitude');
        debugPrint('Tarih: $dateStr | Metod: $method');
        timings.forEach((k, v) => debugPrint('  $k: $v'));
        debugPrint('════════════════════════════');

        final times = _parseApiResponse(timings, date, madhhab);

        // Cache'e kaydet
        _cache[key] = times;

        return times;
      } else {
        debugPrint(
            '⚠️ API hata: ${response.statusCode}, offline hesaplamaya geçiliyor');
        return calculatePrayerTimes(
          latitude: latitude,
          longitude: longitude,
          date: date,
          madhhab: madhhab,
          sunniMethod: sunniMethod,
        );
      }
    } catch (e) {
      debugPrint('⚠️ API erişilemedi: $e, offline hesaplamaya geçiliyor');
      return calculatePrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: date,
        madhhab: madhhab,
        sunniMethod: sunniMethod,
      );
    }
  }

  /// API JSON → PrayerTimeModel listesi
  static List<PrayerTimeModel> _parseApiResponse(
    Map<String, dynamic> timings,
    DateTime date,
    MadhhabType madhhab,
  ) {
    List<PrayerTimeModel> times = [];

    // "HH:mm (EET)" → DateTime (API local saat döndürüyor, timezone sorunsuz)
    DateTime parseTime(String timeStr) {
      final clean = timeStr.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();
      final parts = clean.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    // İmsak
    if (timings.containsKey('Imsak')) {
      times.add(PrayerTimeModel(
        name: 'İmsak (Sahur)',
        nameArabic: 'الإمساك',
        time: parseTime(timings['Imsak']),
      ));
    }

    // Sabah (Fajr)
    times.add(PrayerTimeModel(
      name: 'Sabah',
      nameArabic: 'الفجر',
      time: parseTime(timings['Fajr']),
    ));

    // Güneş (Sunrise)
    times.add(PrayerTimeModel(
      name: 'Güneş',
      nameArabic: 'الشروق',
      time: parseTime(timings['Sunrise']),
    ));

    // Öğle (Dhuhr)
    times.add(PrayerTimeModel(
      name: 'Öğle',
      nameArabic: 'الظهر',
      time: parseTime(timings['Dhuhr']),
    ));

    // İkindi (Asr)
    times.add(PrayerTimeModel(
      name: 'İkindi',
      nameArabic: 'العصر',
      time: parseTime(timings['Asr']),
    ));

    // Akşam (Maghrib)
    if (madhhab == MadhhabType.shia) {
      times.add(PrayerTimeModel(
        name: 'Akşam (Mağrib)',
        nameArabic: 'المغرب',
        time: parseTime(timings['Maghrib']),
      ));
    } else {
      times.add(PrayerTimeModel(
        name: 'Akşam (İftar)',
        nameArabic: 'المغرب',
        time: parseTime(timings['Maghrib']),
      ));
    }

    // Yatsı (Isha)
    times.add(PrayerTimeModel(
      name: 'Yatsı',
      nameArabic: 'العشاء',
      time: parseTime(timings['Isha']),
    ));

    return times;
  }

  // ═══════════════════════════════════════════════════════════════
  // OFFLINE FALLBACK: İnternet yoksa adhan paketi ile hesapla
  // ═══════════════════════════════════════════════════════════════

  static List<PrayerTimeModel> calculatePrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required MadhhabType madhhab,
    SunniMethod sunniMethod = SunniMethod.diyanet,
  }) {
    final coordinates = adhan.Coordinates(latitude, longitude);
    final dateComponents = adhan.DateComponents.from(date);

    adhan.CalculationParameters params;

    if (madhhab == MadhhabType.shia) {
      params = adhan.CalculationMethod.tehran.getParameters();
      params.madhab = adhan.Madhab.shafi;
    } else {
      switch (sunniMethod) {
        case SunniMethod.diyanet:
          params = adhan.CalculationMethod.turkey.getParameters();
          params.madhab =
              adhan.Madhab.shafi; // ✅ FIX: Diyanet standart Asr kullanır
          break;
        case SunniMethod.muslimWorldLeague:
          params = adhan.CalculationMethod.muslim_world_league.getParameters();
          params.madhab = adhan.Madhab.hanafi;
          break;
        case SunniMethod.isna:
          params = adhan.CalculationMethod.north_america.getParameters();
          params.madhab = adhan.Madhab.hanafi;
          break;
        case SunniMethod.egypt:
          params = adhan.CalculationMethod.egyptian.getParameters();
          params.madhab = adhan.Madhab.shafi;
          break;
        case SunniMethod.umm_al_qura:
          params = adhan.CalculationMethod.umm_al_qura.getParameters();
          params.madhab = adhan.Madhab.hanafi;
          break;
      }
    }

    final prayerTimes = adhan.PrayerTimes(coordinates, dateComponents, params);

    List<PrayerTimeModel> times = [];

    final imsak =
        prayerTimes.fajr.toLocal().subtract(const Duration(minutes: 10));
    times.add(PrayerTimeModel(
      name: 'İmsak (Sahur)',
      nameArabic: 'الإمساك',
      time: imsak,
    ));

    times.add(PrayerTimeModel(
      name: 'Sabah',
      nameArabic: 'الفجر',
      time: prayerTimes.fajr.toLocal(),
    ));

    times.add(PrayerTimeModel(
      name: 'Güneş',
      nameArabic: 'الشروق',
      time: prayerTimes.sunrise.toLocal(),
    ));

    times.add(PrayerTimeModel(
      name: 'Öğle',
      nameArabic: 'الظهر',
      time: prayerTimes.dhuhr.toLocal(),
    ));

    times.add(PrayerTimeModel(
      name: 'İkindi',
      nameArabic: 'العصر',
      time: prayerTimes.asr.toLocal(),
    ));

    if (madhhab == MadhhabType.shia) {
      final maghribShia =
          prayerTimes.maghrib.toLocal().add(const Duration(minutes: 17));
      times.add(PrayerTimeModel(
        name: 'Akşam (Mağrib)',
        nameArabic: 'المغرب',
        time: maghribShia,
      ));
    } else {
      times.add(PrayerTimeModel(
        name: 'Akşam (İftar)',
        nameArabic: 'المغرب',
        time: prayerTimes.maghrib.toLocal(),
      ));
    }

    times.add(PrayerTimeModel(
      name: 'Yatsı',
      nameArabic: 'العشاء',
      time: prayerTimes.isha.toLocal(),
    ));

    return times;
  }

  // ═══════════════════════════════════════════════════════════════
  // YARDIMCI METODLAR
  // ═══════════════════════════════════════════════════════════════

  static PrayerTimeModel? getNextPrayer(List<PrayerTimeModel> prayers) {
    final now = DateTime.now();
    for (final prayer in prayers) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    return null;
  }

  static Duration? timeUntilNextPrayer(List<PrayerTimeModel> prayers) {
    final next = getNextPrayer(prayers);
    if (next == null) return null;
    return next.time.difference(DateTime.now());
  }

  /// Cache'i temizle (konum veya metod değiştiğinde)
  static void clearCache() {
    _cache.clear();
    debugPrint('🗑️ Namaz vakitleri cache temizlendi');
  }
}
