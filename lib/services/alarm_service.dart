import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/prayer_model.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static AudioPlayer? _audioPlayer;

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_getLocalTimezone()));

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

  static String _getLocalTimezone() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    if (offset.inHours == 3) return 'Europe/Istanbul';
    if (offset.inHours == 2) return 'Europe/Berlin';
    if (offset.inHours == 1) return 'Europe/London';
    if (offset.inHours == 0) return 'UTC';
    if (offset.inHours == 4) return 'Asia/Dubai';
    if (offset.inHours == 5) return 'Asia/Karachi';
    if (offset.inMinutes == 330) return 'Asia/Kolkata';
    if (offset.inHours == 8) return 'Asia/Shanghai';
    if (offset.inHours == 9) return 'Asia/Tokyo';
    if (offset.inHours == -5) return 'America/New_York';
    if (offset.inHours == -6) return 'America/Chicago';
    if (offset.inHours == -7) return 'America/Denver';
    if (offset.inHours == -8) return 'America/Los_Angeles';
    return 'UTC';
  }

  static Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required AlarmMode mode,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

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
          timeoutAfter: 30000,
        );
        break;

      case AlarmMode.vibration:
        androidDetails = AndroidNotificationDetails(
          'ramadan_alarms',
          'Ramazan Alarmları',
          channelDescription: 'İftar, Sahur ve Namaz vakti bildirimleri',
          importance: Importance.max,
          priority: Priority.max,
          playSound: false,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
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

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_mode_$id', mode.name);

    if (mode == AlarmMode.adhan) {
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id + 10000,
        _playAdhanCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    }
  }

  static Future<void> scheduleAllAlarms({
    required List<PrayerTimeModel> prayers,
    required Map<String, AlarmMode> alarmModes,
    required Map<String, bool> alarmEnabled,
  }) async {
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
        title: '${prayer.name}',
        body: body,
        scheduledTime: prayer.time,
        mode: mode,
      );
    }
  }

  static Future<void> cancelAlarm(int id) async {
    await _notifications.cancel(id);
    await AndroidAlarmManager.cancel(id + 10000);
  }

  static Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
    for (int i = 0; i < 20; i++) {
      await AndroidAlarmManager.cancel(i + 10000);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _playAdhanCallback() async {
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setSource(AssetSource('sounds/adhan_short.mp3'));
      await player.resume();

      await Future.delayed(const Duration(seconds: 30));
      await player.stop();
      await player.dispose();
    } catch (e) {
      print('Ezan çalma hatası: $e');
    }
  }

  static Future<void> testAdhanSound() async {
    _audioPlayer?.dispose();
    _audioPlayer = AudioPlayer();

    await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer!.setSource(AssetSource('sounds/adhan_short.mp3'));
    await _audioPlayer!.resume();

    Future.delayed(const Duration(seconds: 5), () {
      stopAdhan();
    });
  }

  static Future<void> stopAdhan() async {
    await _audioPlayer?.stop();
    await _audioPlayer?.dispose();
    _audioPlayer = null;
  }

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