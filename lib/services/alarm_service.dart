import 'dart:isolate';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/prayer_model.dart';

/// Alarm servisi - uygulama kapalıyken bile çalışır
class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static AudioPlayer? _audioPlayer;

  /// Servisi başlat
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'ramadan_alarms',
      'Ramazan Alarmları',
      description: 'İftar, Sahur ve Namaz vakti bildirimleri',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Alarm kur
  static Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required AlarmMode mode,
  }) async {
    // Geçmiş zamanlar için alarm kurma
    if (scheduledTime.isBefore(DateTime.now())) return;

    // Alarm moduna göre bildirim ayarları
    AndroidNotificationDetails androidDetails;

    switch (mode) {
      case AlarmMode.adhan:
        androidDetails = const AndroidNotificationDetails(
          'ramadan_alarms',
          'Ramazan Alarmları',
          channelDescription: 'İftar, Sahur ve Namaz vakti bildirimleri',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('adhan_short'),
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          autoCancel: false,
          ongoing: true,
          timeoutAfter: 30000, // 30 saniye sonra kapat
        );
        break;

      case AlarmMode.vibration:
        androidDetails = const AndroidNotificationDetails(
          'ramadan_alarms',
          'Ramazan Alarmları',
          channelDescription: 'İftar, Sahur ve Namaz vakti bildirimleri',
          importance: Importance.max,
          priority: Priority.max,
          playSound: false,
          enableVibration: true,
          vibrationPattern: Int64List(0), // Varsayılan titreşim
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        );
        break;

      case AlarmMode.silent:
        androidDetails = const AndroidNotificationDetails(
          'ramadan_alarms',
          'Ramazan Alarmları',
          channelDescription: 'İftar, Sahur ve Namaz vakti bildirimleri',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
        );
        break;

      case AlarmMode.notification:
      default:
        androidDetails = const AndroidNotificationDetails(
          'ramadan_alarms',
          'Ramazan Alarmları',
          channelDescription: 'İftar, Sahur ve Namaz vakti bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        );
        break;
    }

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Zamanlanmış bildirim
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );

    // Alarm modunu kaydet (background callback için)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_mode_$id', mode.name);

    // Ezan sesi modunda ek alarm kur (AudioPlayer ile çalmak için)
    if (mode == AlarmMode.adhan) {
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id + 10000, // Farklı ID
        _playAdhanCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    }
  }

  /// Tüm namaz vakitleri için alarm kur
  static Future<void> scheduleAllAlarms({
    required List<PrayerTimeModel> prayers,
    required Map<String, AlarmMode> alarmModes,
    required Map<String, bool> alarmEnabled,
  }) async {
    // Önce tüm mevcut alarmları iptal et
    await cancelAllAlarms();

    for (int i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      final isEnabled = alarmEnabled[prayer.name] ?? false;
      final mode = alarmModes[prayer.name] ?? AlarmMode.notification;

      if (!isEnabled) continue;

      String body;
      if (prayer.name.contains('İmsak') || prayer.name.contains('Sahur')) {
        body = 'Sahur vakti yaklaştı! Sahura kalkmayı unutmayın.';
      } else if (prayer.name.contains('İftar') || prayer.name.contains('Akşam')) {
        body = 'İftar vakti geldi! Hayırlı iftarlar.';
      } else {
        body = '${prayer.name} namazı vakti girdi.';
      }

      await scheduleAlarm(
        id: i,
        title: '🕌 ${prayer.name}',
        body: body,
        scheduledTime: prayer.time,
        mode: mode,
      );
    }
  }

  /// Belirli bir alarmı iptal et
  static Future<void> cancelAlarm(int id) async {
    await _notifications.cancel(id);
    await AndroidAlarmManager.cancel(id + 10000);
  }

  /// Tüm alarmları iptal et
  static Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
    // AndroidAlarmManager için de iptal et
    for (int i = 0; i < 20; i++) {
      await AndroidAlarmManager.cancel(i + 10000);
    }
  }

  /// Background'da ezan çal (static callback)
  @pragma('vm:entry-point')
  static Future<void> _playAdhanCallback() async {
    try {
      final player = AudioPlayer();

      // Ezan sesini çal (3 saniyelik loop)
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setSource(AssetSource('sounds/adhan_short.mp3'));
      await player.resume();

      // 30 saniye sonra durdur
      await Future.delayed(const Duration(seconds: 30));
      await player.stop();
      await player.dispose();
    } catch (e) {
      // Ses çalma hatası
      print('Ezan çalma hatası: $e');
    }
  }

  /// Ezan sesini test et
  static Future<void> testAdhanSound() async {
    _audioPlayer?.dispose();
    _audioPlayer = AudioPlayer();

    await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer!.setSource(AssetSource('sounds/adhan_short.mp3'));
    await _audioPlayer!.resume();

    // 5 saniye sonra durdur (test)
    Future.delayed(const Duration(seconds: 5), () {
      stopAdhan();
    });
  }

  /// Ezan sesini durdur
  static Future<void> stopAdhan() async {
    await _audioPlayer?.stop();
    await _audioPlayer?.dispose();
    _audioPlayer = null;
  }

  /// Bildirim izinlerini kontrol et
  static Future<bool> checkPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.areNotificationsEnabled();
      return granted ?? false;
    }

    return true;
  }

  /// Bildirim izni iste
  static Future<bool> requestPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }
}
