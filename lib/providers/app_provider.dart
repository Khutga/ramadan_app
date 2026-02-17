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

  Future<void> initialize() async {
    // 1. Önce kayıtlı tercihleri yükle
    await _loadPreferences();

    // 2. Konumu bul ve vakitleri hesapla (Bu işlem async devam eder)
    // await kullanmıyoruz ki UI hemen açılsın, loading dönsün
    _getCurrentLocation();

    // 3. Diğer verileri hazırla
    _loadDailyVerse();
    _startCountdownTimer();
    _calculateRamadanDay();

    // 4. Alarm servisini başlat
    await AlarmService.initialize();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final madhhabIndex = prefs.getInt('madhhab') ?? 0;
    _madhhab = MadhhabType.values[madhhabIndex];

    final methodIndex = prefs.getInt('sunni_method') ?? 0;
    _sunniMethod = SunniMethod.values[methodIndex];

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

  void _calculatePrayerTimes() {
    // Burada PrayerTimeService'in doğru yapılandırıldığından emin olun.
    // Diyanet formülü (CalculationMethod.turkey) Service içinde seçili olmalı.
    _prayerTimes = PrayerTimeService.calculatePrayerTimes(
      latitude: _latitude,
      longitude: _longitude,
      date: DateTime.now(),
      madhhab: _madhhab,
      sunniMethod: _sunniMethod,
    );

    _nextPrayer = PrayerTimeService.getNextPrayer(_prayerTimes);
    _timeUntilNext = PrayerTimeService.timeUntilNextPrayer(_prayerTimes);
  }

  // ... (Geri kalan fonksiyonlar aynı: _loadDailyVerse, _startCountdownTimer vs.)

  void _loadDailyVerse() {
    _dailyVerse = QuranService.getDailyVerse();
    // notifyListeners(); // initialize içinde çağırdığımız için burada gerek yok
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _timeUntilNext = PrayerTimeService.timeUntilNextPrayer(_prayerTimes);
      _nextPrayer = PrayerTimeService.getNextPrayer(_prayerTimes);

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
      return "17 Şubat 2026";
    }
  }

  void _calculateRamadanDay() {
    try {
      HijriCalendar.setLocal('tr');
      final todayHijri = HijriCalendar.now();

      if (todayHijri.hMonth == 9) {
        _ramadanDay = todayHijri.hDay;
        _totalRamadanDays = todayHijri.lengthOfMonth;
      } else {
        _ramadanDay = 0;
        _totalRamadanDays = 30;
      }
    } catch (e) {
      // Yedek plan (Manuel hesaplama)
      final now = DateTime.now();
      DateTime ramadanStart =
          (now.year == 2025) ? DateTime(2025, 3, 1) : DateTime(2026, 2, 17);
      final diff = DateTime(now.year, now.month, now.day)
          .difference(ramadanStart)
          .inDays;

      if (diff >= 0 && diff < 30) {
        _ramadanDay = diff + 1;
      } else {
        _ramadanDay = 0;
      }
      _totalRamadanDays = 30;
    }
  }

  Future<void> _scheduleAlarms() async {
    await AlarmService.scheduleAllAlarms(
      prayers: _prayerTimes,
      alarmModes: _alarmModes,
      alarmEnabled: _alarmEnabled,
    );
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

  Future<void> setAlarmMode(String prayerName, AlarmMode mode) async {
    _alarmModes[prayerName] = mode;
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  // Konumu manuel güncellemek gerekirse
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

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
