import 'package:adhan/adhan.dart' as adhan;
import '../models/prayer_model.dart';

/// Namaz vakitleri hesaplama servisi
/// Sünni ve Şii farkları dahil
class PrayerTimeService {
  /// Namaz vakitlerini hesapla
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
      // Şii (Caferi) hesaplama
      // Caferi: Fecr açısı 16°, İşa açısı 14°
      // Mağrib: Güneşin batışından sonra kırmızılığın kaybolması (~4 derece daha)
      params = adhan.CalculationMethod.tehran.getParameters();
      params.madhab = adhan.Madhab.shafi; // Şii'de Asr hesabı Şafi gibidir
    } else {
      // Sünni hesaplama
      switch (sunniMethod) {
        case SunniMethod.diyanet:
          params = adhan.CalculationMethod.turkey.getParameters();
          params.madhab = adhan.Madhab.hanafi;
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

    final prayerTimes = adhan.PrayerTimes(
      coordinates,
      dateComponents,
      params,
    );

    List<PrayerTimeModel> times = [];

    // İmsak / Sahur (Fecr'den ~10 dk önce)
    final imsak = prayerTimes.fajr.subtract(const Duration(minutes: 10));
    times.add(PrayerTimeModel(
      name: 'İmsak (Sahur)',
      nameArabic: 'الإمساك',
      time: imsak,
    ));

    // Sabah (Fecr)
    times.add(PrayerTimeModel(
      name: 'Sabah',
      nameArabic: 'الفجر',
      time: prayerTimes.fajr,
    ));

    // Güneş doğuşu
    times.add(PrayerTimeModel(
      name: 'Güneş',
      nameArabic: 'الشروق',
      time: prayerTimes.sunrise,
    ));

    // Öğle
    times.add(PrayerTimeModel(
      name: 'Öğle',
      nameArabic: 'الظهر',
      time: prayerTimes.dhuhr,
    ));

    // İkindi
    times.add(PrayerTimeModel(
      name: 'İkindi',
      nameArabic: 'العصر',
      time: prayerTimes.asr,
    ));

    if (madhhab == MadhhabType.shia) {
      // Şii: Mağrib güneş batışından biraz sonra
      // (kırmızılık geçene kadar, genellikle ~17-20 dk sonra)
      final maghribShia = prayerTimes.maghrib.add(const Duration(minutes: 17));
      times.add(PrayerTimeModel(
        name: 'Akşam (Mağrib)',
        nameArabic: 'المغرب',
        time: maghribShia,
      ));

      // İftar vakti: Şii'de Mağrib ile aynı (biraz geç)
      // Sünni'de güneşin batması ile aynı
    } else {
      // Sünni: Mağrib güneşin batışı ile
      times.add(PrayerTimeModel(
        name: 'Akşam (İftar)',
        nameArabic: 'المغرب',
        time: prayerTimes.maghrib,
      ));
    }

    // Yatsı
    times.add(PrayerTimeModel(
      name: 'Yatsı',
      nameArabic: 'العشاء',
      time: prayerTimes.isha,
    ));

    return times;
  }

  /// İftar vaktini al
  static DateTime getIftarTime({
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
    } else {
      switch (sunniMethod) {
        case SunniMethod.diyanet:
          params = adhan.CalculationMethod.turkey.getParameters();
          break;
        default:
          params = adhan.CalculationMethod.muslim_world_league.getParameters();
      }
    }

    final prayerTimes = adhan.PrayerTimes(
      coordinates,
      dateComponents,
      params,
    );

    if (madhhab == MadhhabType.shia) {
      // Şii: Mağrib gecikmeli (~17 dk)
      return prayerTimes.maghrib.add(const Duration(minutes: 17));
    }

    return prayerTimes.maghrib;
  }

  /// Sahur vaktini al
  static DateTime getSahurTime({
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
    } else {
      switch (sunniMethod) {
        case SunniMethod.diyanet:
          params = adhan.CalculationMethod.turkey.getParameters();
          break;
        default:
          params = adhan.CalculationMethod.muslim_world_league.getParameters();
      }
    }

    final prayerTimes = adhan.PrayerTimes(
      coordinates,
      dateComponents,
      params,
    );

    // İmsak: Fecr'den 10 dk önce
    return prayerTimes.fajr.subtract(const Duration(minutes: 10));
  }

  /// Bir sonraki namaz vaktini bul
  static PrayerTimeModel? getNextPrayer(List<PrayerTimeModel> prayers) {
    final now = DateTime.now();
    for (final prayer in prayers) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    return null;
  }

  /// Bir sonraki namaza kalan süre
  static Duration? timeUntilNextPrayer(List<PrayerTimeModel> prayers) {
    final next = getNextPrayer(prayers);
    if (next == null) return null;
    return next.time.difference(DateTime.now());
  }
}
