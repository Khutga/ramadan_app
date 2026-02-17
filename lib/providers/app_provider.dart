import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_model.dart';
import '../models/quran_model.dart';
import '../services/prayer_time_service.dart';
import '../services/quran_service.dart';
import '../services/alarm_service.dart';

class AppProvider extends ChangeNotifier {
  // Varsayılan Konum (İstanbul)
  double _latitude = 41.0082;
  double _longitude = 28.9784;
  String _cityName = 'İstanbul';
  String _countryName = 'Türkiye';

  bool _locationLoading = true;
  String? _locationError;

  MadhhabType _madhhab = MadhhabType.sunni;
  SunniMethod _sunniMethod = SunniMethod.diyanet;

  List<PrayerTimeModel> _prayerTimes = [];
  PrayerTimeModel? _nextPrayer;
  Duration? _timeUntilNext;
  Timer? _countdownTimer;

  QuranVerse? _dailyVerse;

  final Map<String, bool> _alarmEnabled = {};
  final Map<String, AlarmMode> _alarmModes = {};

  int _ramadanDay = 0;
  int _totalRamadanDays = 30;

  // Sahur alarm offset (dakika olarak İmsak'tan önce)
  int _sahurAlarmOffset = 30; // Varsayılan: İmsak'tan 30 dk önce
  bool _sahurAlarmEnabled = false;
  AlarmMode _sahurAlarmMode = AlarmMode.adhan;

  // Ramazan durumu
  bool _isRamadan = false;
  bool _isBeforeRamadan = true;
  Duration? _timeUntilRamadan;
  Duration? _timeUntilNextRamadan;

  // Getters
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get cityName => _cityName;
  String get countryName => _countryName;
  bool get locationLoading => _locationLoading;
  String? get locationError => _locationError;
  MadhhabType get madhhab => _madhhab;
  SunniMethod get sunniMethod => _sunniMethod;
  List<PrayerTimeModel> get prayerTimes => _prayerTimes;
  PrayerTimeModel? get nextPrayer => _nextPrayer;
  Duration? get timeUntilNext => _timeUntilNext;
  QuranVerse? get dailyVerse => _dailyVerse;
  Map<String, bool> get alarmEnabled => _alarmEnabled;
  Map<String, AlarmMode> get alarmModes => _alarmModes;
  int get ramadanDay => _ramadanDay;
  int get totalRamadanDays => _totalRamadanDays;
  int get sahurAlarmOffset => _sahurAlarmOffset;
  bool get sahurAlarmEnabled => _sahurAlarmEnabled;
  AlarmMode get sahurAlarmMode => _sahurAlarmMode;
  bool get isRamadan => _isRamadan;
  bool get isBeforeRamadan => _isBeforeRamadan;
  Duration? get timeUntilRamadan => _timeUntilRamadan;
  Duration? get timeUntilNextRamadan => _timeUntilNextRamadan;

  // İftar ve Sahur'a kalan süre
  Duration? get timeUntilIftar {
    for (final prayer in _prayerTimes) {
      if ((prayer.name.contains('İftar') || prayer.name.contains('Mağrib')) &&
          prayer.time.isAfter(DateTime.now())) {
        return prayer.time.difference(DateTime.now());
      }
    }
    return null;
  }

  Duration? get timeUntilSahur {
    for (final prayer in _prayerTimes) {
      if ((prayer.name.contains('İmsak') || prayer.name.contains('Sahur')) &&
          prayer.time.isAfter(DateTime.now())) {
        return prayer.time.difference(DateTime.now());
      }
    }
    return null;
  }

  DateTime? get imsakTime {
    for (final prayer in _prayerTimes) {
      if (prayer.name.contains('İmsak') || prayer.name.contains('Sahur')) {
        return prayer.time;
      }
    }
    return null;
  }

  DateTime? get iftarTime {
    for (final prayer in _prayerTimes) {
      if (prayer.name.contains('İftar') || prayer.name.contains('Mağrib')) {
        return prayer.time;
      }
    }
    return null;
  }

  // Sahur alarm zamanı
  DateTime? get sahurAlarmTime {
    final imsak = imsakTime;
    if (imsak == null) return null;
    return imsak.subtract(Duration(minutes: _sahurAlarmOffset));
  }

  // Tüm alarmlar açık mı? (Sadece mevcut vakit isimlerine göre kontrol)
  bool get allAlarmsEnabled {
    if (_prayerTimes.isEmpty) return false;
    return _prayerTimes.every((p) => _alarmEnabled[p.name] == true);
  }

  Future<void> initialize() async {
    await _loadPreferences();
    _getCurrentLocation();
    _loadDailyVerse();
    _startCountdownTimer();
    _calculateRamadanDay();
    _calculateRamadanCountdown();
    await AlarmService.initialize();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final madhhabIndex = prefs.getInt('madhhab') ?? 0;
    _madhhab = MadhhabType.values[madhhabIndex];

    final methodIndex = prefs.getInt('sunni_method') ?? 0;
    _sunniMethod = SunniMethod.values[methodIndex];

    // Sahur alarm tercihleri
    _sahurAlarmOffset = prefs.getInt('sahur_alarm_offset') ?? 30;
    _sahurAlarmEnabled = prefs.getBool('sahur_alarm_enabled') ?? false;
    final sahurModeIndex =
        prefs.getInt('sahur_alarm_mode') ?? 1; // Default adhan
    _sahurAlarmMode = AlarmMode.values[sahurModeIndex];

    final alarmKeys = [
      'İmsak (Sahur)',
      'Sabah',
      'Güneş',
      'Öğle',
      'İkindi',
      'Akşam (İftar)',
      'Akşam (Mağrib)',
      'Yatsı'
    ];

    for (final key in alarmKeys) {
      _alarmEnabled[key] = prefs.getBool('alarm_enabled_$key') ?? false;
      final modeIndex = prefs.getInt('alarm_mode_$key') ?? 0;
      _alarmModes[key] = AlarmMode.values[modeIndex];
    }

    // Varsayılan alarmlar
    if (prefs.getBool('alarm_enabled_İmsak (Sahur)') == null) {
      _alarmEnabled['İmsak (Sahur)'] = true;
    }
    if (prefs.getBool('alarm_enabled_Akşam (İftar)') == null) {
      _alarmEnabled['Akşam (İftar)'] = true;
    }

    _alarmModes['İmsak (Sahur)'] ??= AlarmMode.adhan;
    _alarmModes['Akşam (İftar)'] ??= AlarmMode.adhan;
    _alarmModes['Akşam (Mağrib)'] ??= AlarmMode.adhan;
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('madhhab', _madhhab.index);
    await prefs.setInt('sunni_method', _sunniMethod.index);

    // Sahur alarm tercihleri
    await prefs.setInt('sahur_alarm_offset', _sahurAlarmOffset);
    await prefs.setBool('sahur_alarm_enabled', _sahurAlarmEnabled);
    await prefs.setInt('sahur_alarm_mode', _sahurAlarmMode.index);

    for (final entry in _alarmEnabled.entries) {
      await prefs.setBool('alarm_enabled_${entry.key}', entry.value);
    }
    for (final entry in _alarmModes.entries) {
      await prefs.setInt('alarm_mode_${entry.key}', entry.value.index);
    }
  }

  Future<void> _getCurrentLocation() async {
    _locationLoading = true;
    // Loading durumunu UI'a bildir
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'Konum servisi kapalı';
        _locationLoading = false;
        // Konum kapalıysa varsayılan (İstanbul) ile hesapla
        _calculatePrayerTimes();
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationError = 'Konum izni reddedildi';
          _locationLoading = false;
          _calculatePrayerTimes(); // İzin yoksa varsayılan ile devam
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationError = 'Konum izni kalıcı olarak reddedildi';
        _locationLoading = false;
        _calculatePrayerTimes(); // İzin yoksa varsayılan ile devam
        notifyListeners();
        return;
      }

      // Konumu al
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Koordinatları güncelle
      _latitude = position.latitude;
      _longitude = position.longitude;

      // Adres Çözümleme (Bursa / Nilüfer gibi)
      try {
        final placemarks = await placemarkFromCoordinates(
          _latitude,
          _longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          String? il = place.administrativeArea; // Örn: Bursa
          String? ilce = place.subAdministrativeArea; // Örn: Nilüfer

          // Şehir ismini belirleme mantığı
          if (ilce != null && ilce.isNotEmpty && il != null && il.isNotEmpty) {
            if (ilce == il) {
              _cityName = il;
            } else {
              _cityName = '$ilce / $il';
            }
          } else if (il != null && il.isNotEmpty) {
            _cityName = il;
          } else {
            _cityName = place.locality ?? 'Konum Alındı';
          }

          _countryName = place.country ?? 'Türkiye';
        }
      } catch (e) {
        // Geocoding hatası olsa bile koordinatlar elimizde, devam et.
        print("Adres hatası: $e");
        if (_cityName == 'İstanbul') _cityName = 'Konum Alındı';
      }

      _locationError = null;

      // KRİTİK NOKTA: Koordinatlar güncellendi, şimdi vakitleri hesapla!
      _calculatePrayerTimes();

      // Alarmları yeni vakitlere göre güncelle
      _scheduleAlarms();
    } catch (e) {
      _locationError = 'Konum alınamadı. Varsayılan konum kullanılıyor.';
      _calculatePrayerTimes(); // Hata durumunda da hesapla (varsayılan ile)
    }

    _locationLoading = false;
    notifyListeners();
  }

  // Varsayılan Konum Yardımcısı
  void _useDefaultLocation() {
    _latitude = 41.0082; // İstanbul
    _longitude = 28.9784;
    _cityName = 'İstanbul';
    _countryName = 'Türkiye';
    _locationError = 'Konum alınamadı, İstanbul gösteriliyor.';
  }

  // Adres Çözümleme Yardımcısı
  Future<void> _getAddressFromCoords() async {
    try {
      final placemarks = await placemarkFromCoordinates(_latitude, _longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (place.administrativeArea != null) {
          _cityName = place.administrativeArea!; // İl
          if (place.subAdministrativeArea != null &&
              place.subAdministrativeArea != place.administrativeArea) {
            _cityName =
                "${place.subAdministrativeArea} / ${place.administrativeArea}";
          }
        } else {
          _cityName = 'Konum Alındı';
        }
        _countryName = place.country ?? 'Türkiye';
      }
    } catch (_) {
      // Geocoding hatası önemsiz, koordinat var nasılsa
    }
  }

  // Kod tekrarını önlemek için küçük bir yardımcı
  void _stopLoadingAndNotify() {
    _locationLoading = false;
    _calculatePrayerTimes();
    notifyListeners();
  }

  void _calculatePrayerTimes() {
    _prayerTimes = PrayerTimeService.calculatePrayerTimes(
      latitude: _latitude,
      longitude: _longitude,
      date: DateTime.now().toLocal(),
      madhhab: _madhhab,
      sunniMethod: _sunniMethod,
    );

    _nextPrayer = PrayerTimeService.getNextPrayer(_prayerTimes);
    _timeUntilNext = PrayerTimeService.timeUntilNextPrayer(_prayerTimes);
  }

  void _loadDailyVerse() {
    _dailyVerse = QuranService.getDailyVerse();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _timeUntilNext = PrayerTimeService.timeUntilNextPrayer(_prayerTimes);
      _nextPrayer = PrayerTimeService.getNextPrayer(_prayerTimes);
      _calculateRamadanCountdown();

      if (_nextPrayer == null) {
        _calculatePrayerTimes();
      }
      notifyListeners();
    });
  }

  String get ramadanStartDateStr {
    try {
      HijriCalendar.setLocal('tr');
      final todayHijri = HijriCalendar.now();
      var targetYear = todayHijri.hYear;

      if (todayHijri.hMonth > 9) {
        targetYear++;
      }

      final ramadanFirstDay = HijriCalendar();
      ramadanFirstDay.hYear = targetYear;
      ramadanFirstDay.hMonth = 9;
      ramadanFirstDay.hDay = 1;

      final gregorianDate = ramadanFirstDay.hijriToGregorian(targetYear, 9, 1);
      final formatter = DateFormat("d MMMM yyyy", "tr_TR");
      return formatter.format(gregorianDate);
    } catch (e) {
      return "19 Şubat 2026";
    }
  }

  DateTime get _ramadanStartDate {
    try {
      HijriCalendar.setLocal('tr');
      final todayHijri = HijriCalendar.now();
      var targetYear = todayHijri.hYear;

      // Ramazan'dayız veya geçmişse, gelecek yıla bak
      if (todayHijri.hMonth > 9 ||
          (todayHijri.hMonth == 9 && _ramadanDay >= _totalRamadanDays)) {
        targetYear++;
      }

      final ramadanFirstDay = HijriCalendar();
      ramadanFirstDay.hYear = targetYear;
      ramadanFirstDay.hMonth = 9;
      ramadanFirstDay.hDay = 1;

      return ramadanFirstDay.hijriToGregorian(targetYear, 9, 1);
    } catch (e) {
      // MANUEL TARİH DÜZELTMESİ:
      final now = DateTime.now();

      // 2026 için İlk Oruç: 19 Şubat
      // Eğer şu an 19 Şubat 2026'dan önceyse (veya o günse), bu tarihi döndür
      if (now.isBefore(DateTime(2026, 2, 20))) {
        // 19'u dahil etmek için 20'sinden önce dedik
        return DateTime(2026, 2, 19);
      }

      // Geçmişse 2027 tarihini döndür (Yaklaşık 8 Şubat 2027)
      return DateTime(2027, 2, 8);
    }
  }

  DateTime get _nextRamadanStartDate {
    try {
      HijriCalendar.setLocal('tr');
      final todayHijri = HijriCalendar.now();
      var targetYear = todayHijri.hYear + 1;

      final ramadanFirstDay = HijriCalendar();
      ramadanFirstDay.hYear = targetYear;
      ramadanFirstDay.hMonth = 9;
      ramadanFirstDay.hDay = 1;

      return ramadanFirstDay.hijriToGregorian(targetYear, 9, 1);
    } catch (e) {
      return DateTime(2027, 2, 7);
    }
  }

  void _calculateRamadanDay() {
    try {
      HijriCalendar.setLocal('tr');
      final todayHijri = HijriCalendar.now();
      print('HijriCalendar.now(): ${HijriCalendar.now()}');
      print(
          'hYear: ${todayHijri.hYear}, hMonth: ${todayHijri.hMonth}, hDay: ${todayHijri.hDay}');
      if (todayHijri.hMonth == 9) {
        _ramadanDay = todayHijri.hDay;
        _totalRamadanDays = todayHijri.lengthOfMonth;
        _isRamadan = true;
        _isBeforeRamadan = false;
      } else if (todayHijri.hMonth < 9) {
        _ramadanDay = 0;
        _totalRamadanDays = 30;
        _isRamadan = false;
        _isBeforeRamadan = true;
      } else {
        _ramadanDay = 0;
        _totalRamadanDays = 30;
        _isRamadan = false;
        _isBeforeRamadan = false; // Ramazan geçmiş, gelecek yıla sayacak
      }
    } catch (e) {
      final now = DateTime.now();
      DateTime ramadanStart =
          (now.year == 2025) ? DateTime(2025, 3, 1) : DateTime(2026, 2, 18);
      final diff = DateTime(now.year, now.month, now.day)
          .difference(ramadanStart)
          .inDays;

      if (diff >= 0 && diff < 30) {
        _ramadanDay = diff + 1;
        _isRamadan = true;
        _isBeforeRamadan = false;
      } else if (diff < 0) {
        _ramadanDay = 0;
        _isRamadan = false;
        _isBeforeRamadan = true;
      } else {
        _ramadanDay = 0;
        _isRamadan = false;
        _isBeforeRamadan = false;
      }
      _totalRamadanDays = 30;
    }
  }

  void _calculateRamadanCountdown() {
    final now = DateTime.now();
    // Saat/Dakika farkını yok saymak için sadece Yıl-Ay-Gün alıyoruz (Gece 00:00 yapar)
    final todayStart = DateTime(now.year, now.month, now.day);

    if (_isRamadan) {
      _timeUntilRamadan = null;
      // Ramazan bitişine kalan
      final endDate = _ramadanStartDate.add(Duration(days: _totalRamadanDays));
      _timeUntilNextRamadan = endDate.difference(now);
    } else {
      // Ramazan başlangıcına kalan
      final startDate = _ramadanStartDate;

      // Başlangıç tarihinin de sadece gün kısmını alalım
      final startDateOnlyDate =
          DateTime(startDate.year, startDate.month, startDate.day);

      // KONTROL: Eğer 'Bugün', başlangıç tarihinden ÖNCEYSE veya EŞİTSE
      // (Böylece 18 Şubat 23:59'da bile olsanız seneye atlamaz)
      if (todayStart.isBefore(startDateOnlyDate) ||
          todayStart.isAtSameMomentAs(startDateOnlyDate)) {
        _timeUntilRamadan = startDate.difference(now);
      } else {
        // Gerçekten tarih geçmişse (Örn: 20 Şubat olduysa) gelecek yıla bak
        final nextStart = _nextRamadanStartDate;
        _timeUntilRamadan = nextStart.difference(now);
      }
      _timeUntilNextRamadan = null;
    }
  }

  Future<void> _scheduleAlarms() async {
    await AlarmService.scheduleAllAlarms(
      prayers: _prayerTimes,
      alarmModes: _alarmModes,
      alarmEnabled: _alarmEnabled,
    );

    // Sahur öncesi alarm
    if (_sahurAlarmEnabled && sahurAlarmTime != null) {
      await AlarmService.scheduleSahurPreAlarm(
        scheduledTime: sahurAlarmTime!,
        mode: _sahurAlarmMode,
        offsetMinutes: _sahurAlarmOffset,
      );
    }
  }

  // Setter Fonksiyonları
  Future<void> setMadhhab(MadhhabType madhhab) async {
    _madhhab = madhhab;
    _calculatePrayerTimes();
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  Future<void> setSunniMethod(SunniMethod method) async {
    _sunniMethod = method;
    _calculatePrayerTimes();
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  Future<void> toggleAlarm(String prayerName, bool enabled) async {
    _alarmEnabled[prayerName] = enabled;
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  Future<void> toggleAllAlarms(bool enabled) async {
    for (final prayer in _prayerTimes) {
      _alarmEnabled[prayer.name] = enabled;
    }
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  Future<void> setAlarmMode(String prayerName, AlarmMode mode) async {
    _alarmModes[prayerName] = mode;
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  Future<void> setAllAlarmModes(AlarmMode mode) async {
    for (final prayer in _prayerTimes) {
      _alarmModes[prayer.name] = mode;
    }
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  // Sahur alarm ayarları
  Future<void> setSahurAlarmOffset(int minutes) async {
    _sahurAlarmOffset = minutes;
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  Future<void> toggleSahurAlarm(bool enabled) async {
    _sahurAlarmEnabled = enabled;
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  Future<void> setSahurAlarmMode(AlarmMode mode) async {
    _sahurAlarmMode = mode;
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  Future<void> updateLocation(double lat, double lng, String city) async {
    _latitude = lat;
    _longitude = lng;
    _cityName = city;
    _calculatePrayerTimes();
    await _scheduleAlarms();
    notifyListeners();
  }

  void refreshVerse() {
    _dailyVerse = QuranService.getRandomVerse();
    notifyListeners();
  }

  // Hesaplama yöntemi bilgisi
  String get calculationMethodInfo {
    if (_madhhab == MadhhabType.shia) {
      return 'Caferi (Tahran) Yöntemi\n\n'
          '• Fecr Açısı: 17.7°\n'
          '• İşa Açısı: 14°\n'
          '• Akşam namazı: Güneş batışından ~17 dk sonra\n'
          '  (Şafak kızıllığı kaybolunca)\n'
          '• İmsak: Fecr vaktinden 10 dk önce\n\n'
          'Bu astronomik hesaplama yöntemi konumunuza göre\n'
          'en doğru vakitleri hesaplar.';
    }

    switch (_sunniMethod) {
      case SunniMethod.diyanet:
        return 'Diyanet İşleri Başkanlığı Yöntemi\n\n'
            '• Fecr Açısı: 18°\n'
            '• İşa Açısı: 17°\n'
            '• Hanefi mezhebine göre İkindi hesaplaması\n'
            '• İmsak: Fecr vaktinden 10 dk önce\n'
            '• İftar: Güneş batışı ile\n\n'
            'Türkiye\'de en yaygın kullanılan yöntemdir.';
      case SunniMethod.muslimWorldLeague:
        return 'Müslüman Dünya Birliği (MWL) Yöntemi\n\n'
            '• Fecr Açısı: 18°\n'
            '• İşa Açısı: 17°\n'
            '• Avrupa ve dünya genelinde yaygın\n'
            '• İmsak: Fecr vaktinden 10 dk önce';
      case SunniMethod.isna:
        return 'ISNA (Kuzey Amerika) Yöntemi\n\n'
            '• Fecr Açısı: 15°\n'
            '• İşa Açısı: 15°\n'
            '• Kuzey Amerika\'da yaygın\n'
            '• İmsak: Fecr vaktinden 10 dk önce';
      case SunniMethod.egypt:
        return 'Mısır Genel Müftülüğü Yöntemi\n\n'
            '• Fecr Açısı: 19.5°\n'
            '• İşa Açısı: 17.5°\n'
            '• Şafi mezhebine göre İkindi\n'
            '• Afrika ve Orta Doğu\'da yaygın';
      case SunniMethod.umm_al_qura:
        return 'Ümmül Kura Yöntemi\n\n'
            '• Fecr Açısı: 18.5°\n'
            '• İşa: Güneş batışından 90 dk sonra\n'
            '  (Ramazan\'da 120 dk)\n'
            '• Suudi Arabistan resmi yöntemi';
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
