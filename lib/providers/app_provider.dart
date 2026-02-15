import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_model.dart';
import '../models/quran_model.dart';
import '../services/prayer_time_service.dart';
import '../services/quran_service.dart';
import '../services/alarm_service.dart';

class AppProvider extends ChangeNotifier {
  // Konum
  double _latitude = 41.0082; // İstanbul varsayılan
  double _longitude = 28.9784;
  String _cityName = 'İstanbul';
  String _countryName = 'Türkiye';
  bool _locationLoading = true;
  String? _locationError;

  // Mezhep
  MadhhabType _madhhab = MadhhabType.sunni;
  SunniMethod _sunniMethod = SunniMethod.diyanet;

  // Namaz vakitleri
  List<PrayerTimeModel> _prayerTimes = [];
  PrayerTimeModel? _nextPrayer;
  Duration? _timeUntilNext;
  Timer? _countdownTimer;

  // Günün ayeti
  QuranVerse? _dailyVerse;

  // Alarm ayarları
  Map<String, bool> _alarmEnabled = {};
  Map<String, AlarmMode> _alarmModes = {};

  // Ramazan bilgisi
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

  /// İlk başlatma
  Future<void> initialize() async {
    await _loadPreferences();
    await _getCurrentLocation();
    _calculatePrayerTimes();
    _loadDailyVerse();
    _startCountdownTimer();
    _calculateRamadanDay();
    await AlarmService.initialize();
    _scheduleAlarms();
  }

  /// Tercihleri yükle
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Mezhep
    final madhhabIndex = prefs.getInt('madhhab') ?? 0;
    _madhhab = MadhhabType.values[madhhabIndex];

    // Sünni yöntem
    final methodIndex = prefs.getInt('sunni_method') ?? 0;
    _sunniMethod = SunniMethod.values[methodIndex];

    // Alarm ayarları
    final alarmKeys = [
      'İmsak (Sahur)', 'Sabah', 'Güneş', 'Öğle',
      'İkindi', 'Akşam (İftar)', 'Akşam (Mağrib)', 'Yatsı'
    ];
    for (final key in alarmKeys) {
      _alarmEnabled[key] = prefs.getBool('alarm_enabled_$key') ?? false;
      final modeIndex = prefs.getInt('alarm_mode_$key') ?? 0;
      _alarmModes[key] = AlarmMode.values[modeIndex];
    }

    // İftar ve Sahur varsayılan olarak açık
    _alarmEnabled['İmsak (Sahur)'] =
        prefs.getBool('alarm_enabled_İmsak (Sahur)') ?? true;
    _alarmEnabled['Akşam (İftar)'] =
        prefs.getBool('alarm_enabled_Akşam (İftar)') ?? true;
    _alarmEnabled['Akşam (Mağrib)'] =
        prefs.getBool('alarm_enabled_Akşam (Mağrib)') ?? true;
    _alarmModes['İmsak (Sahur)'] ??= AlarmMode.adhan;
    _alarmModes['Akşam (İftar)'] ??= AlarmMode.adhan;
    _alarmModes['Akşam (Mağrib)'] ??= AlarmMode.adhan;
  }

  /// Tercihleri kaydet
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

  /// Konum al
  Future<void> _getCurrentLocation() async {
    _locationLoading = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'Konum servisi kapalı';
        _locationLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationError = 'Konum izni reddedildi';
          _locationLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationError = 'Konum izni kalıcı olarak reddedildi';
        _locationLoading = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Şehir adını al
      try {
        final placemarks = await placemarkFromCoordinates(
          _latitude,
          _longitude,
        );
        if (placemarks.isNotEmpty) {
          _cityName = placemarks.first.locality ?? 'Bilinmiyor';
          _countryName = placemarks.first.country ?? '';
        }
      } catch (e) {
        _cityName = 'Konum alındı';
      }

      _locationError = null;
    } catch (e) {
      _locationError = 'Konum alınamadı: Varsayılan İstanbul kullanılıyor';
    }

    _locationLoading = false;
    notifyListeners();
  }

  /// Namaz vakitlerini hesapla
  void _calculatePrayerTimes() {
    _prayerTimes = PrayerTimeService.calculatePrayerTimes(
      latitude: _latitude,
      longitude: _longitude,
      date: DateTime.now(),
      madhhab: _madhhab,
      sunniMethod: _sunniMethod,
    );

    _nextPrayer = PrayerTimeService.getNextPrayer(_prayerTimes);
    _timeUntilNext = PrayerTimeService.timeUntilNextPrayer(_prayerTimes);

    notifyListeners();
  }

  /// Günün ayetini yükle
  void _loadDailyVerse() {
    _dailyVerse = QuranService.getDailyVerse();
    notifyListeners();
  }

  /// Geri sayım zamanlayıcısı
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _timeUntilNext = PrayerTimeService.timeUntilNextPrayer(_prayerTimes);
      _nextPrayer = PrayerTimeService.getNextPrayer(_prayerTimes);

      // Gün değişimi kontrolü
      if (_nextPrayer == null) {
        _calculatePrayerTimes();
      }

      notifyListeners();
    });
  }

  /// Ramazan gününü hesapla (yaklaşık)
  void _calculateRamadanDay() {
    // 2026 Ramazan tahmini: 17 Şubat - 19 Mart (Hicri 1447)
    // 2025 Ramazan: 28 Şubat - 30 Mart
    // Bu fonksiyon Hicri takvime göre güncellenmelidir
    final now = DateTime.now();
    final ramadanStart2026 = DateTime(2026, 2, 17);
    final ramadanStart2025 = DateTime(2025, 2, 28);

    DateTime ramadanStart;
    if (now.year == 2026) {
      ramadanStart = ramadanStart2026;
    } else if (now.year == 2025) {
      ramadanStart = ramadanStart2025;
    } else {
      // Genel hesaplama (yaklaşık)
      ramadanStart = ramadanStart2026;
    }

    final difference = now.difference(ramadanStart).inDays;
    if (difference >= 0 && difference < 30) {
      _ramadanDay = difference + 1;
    } else if (difference < 0) {
      _ramadanDay = 0; // Ramazan henüz başlamadı
    } else {
      _ramadanDay = 0; // Ramazan bitti
    }

    _totalRamadanDays = 30;
    notifyListeners();
  }

  /// Alarmları planla
  Future<void> _scheduleAlarms() async {
    await AlarmService.scheduleAllAlarms(
      prayers: _prayerTimes,
      alarmModes: _alarmModes,
      alarmEnabled: _alarmEnabled,
    );
  }

  /// Mezhep değiştir
  Future<void> setMadhhab(MadhhabType madhhab) async {
    _madhhab = madhhab;
    _calculatePrayerTimes();
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  /// Sünni hesaplama yöntemi değiştir
  Future<void> setSunniMethod(SunniMethod method) async {
    _sunniMethod = method;
    _calculatePrayerTimes();
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  /// Alarm aç/kapa
  Future<void> toggleAlarm(String prayerName, bool enabled) async {
    _alarmEnabled[prayerName] = enabled;
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  /// Alarm modu değiştir
  Future<void> setAlarmMode(String prayerName, AlarmMode mode) async {
    _alarmModes[prayerName] = mode;
    await _savePreferences();
    await _scheduleAlarms();
    notifyListeners();
  }

  /// Konumu güncelle (manuel)
  Future<void> updateLocation(double lat, double lng, String city) async {
    _latitude = lat;
    _longitude = lng;
    _cityName = city;
    _calculatePrayerTimes();
    await _scheduleAlarms();
    notifyListeners();
  }

  /// Yeni ayet yükle
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
