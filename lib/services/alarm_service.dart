import 'dart:async';
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
  static Timer? _stopTimer;
  static AudioPlayer? _audioPlayer;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_getLocalTimezone()));

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'ramadan_alarms',
          'Ramazan Alarmları',
          description: 'İftar, Sahur ve Namaz vakti bildirimleri',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'ramadan_test_alarms',
          'Test Alarmları',
          description: 'Alarm test bildirimleri',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'ramadan_sahur_alarm',
          'Sahur Kalkma Alarmı',
          description: 'Sahura kalkma bildirimi',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      // İzinleri iste
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    _initialized = true;
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

  static AndroidNotificationDetails _buildAndroidDetails(
    AlarmMode mode, {
    String channelId = 'ramadan_alarms',
    String channelName = 'Ramazan Alarmları',
  }) {
    switch (mode) {
      case AlarmMode.adhan:
        return AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Bildirim',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('adhan_short'),
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          timeoutAfter: 30000,
        );
      case AlarmMode.vibration:
        return AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Bildirim',
          importance: Importance.max,
          priority: Priority.max,
          playSound: false,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        );
      case AlarmMode.silent:
        return AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Bildirim',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
        );
      case AlarmMode.notification:
      default:
        return AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Bildirim',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        );
    }
  }

  static NotificationDetails _buildDetails(
    AlarmMode mode, {
    String channelId = 'ramadan_alarms',
    String channelName = 'Ramazan Alarmları',
  }) {
    return NotificationDetails(
      android: _buildAndroidDetails(mode,
          channelId: channelId, channelName: channelName),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  // =========================================================
  // ZAMANLANMIŞ ALARM
  // =========================================================
  static Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required AlarmMode mode,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        _buildDetails(mode),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

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
      print('[AlarmService] Kuruldu: $title @ $scheduledTime (id:$id)');
    } catch (e) {
      print('[AlarmService] HATA scheduleAlarm: $e');
    }
  }

  // =========================================================
  // TÜM VAKİT ALARMLARI
  // =========================================================
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
      } else if (prayer.name.contains('İftar') ||
          prayer.name.contains('Akşam')) {
        body = 'İftar vakti geldi! Hayırlı iftarlar.';
      } else {
        body = '${prayer.name} namazı vakti girdi.';
      }

      await scheduleAlarm(
        id: i,
        title: prayer.name,
        body: body,
        scheduledTime: prayer.time,
        mode: mode,
      );
    }
  }

  // =========================================================
  // SAHUR ÖNCESİ ALARM
  // =========================================================
  static Future<void> scheduleSahurPreAlarm({
    required DateTime scheduledTime,
    required AlarmMode mode,
    required int offsetMinutes,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _notifications.cancel(100);
    await AndroidAlarmManager.cancel(100 + 10000);

    try {
      await _notifications.zonedSchedule(
        100,
        'Sahura Kalkma Zamanı! ⏰',
        'İmsak vaktine $offsetMinutes dakika kaldı.',
        tz.TZDateTime.from(scheduledTime, tz.local),
        _buildDetails(mode,
            channelId: 'ramadan_sahur_alarm',
            channelName: 'Sahur Kalkma Alarmı'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      if (mode == AlarmMode.adhan) {
        await AndroidAlarmManager.oneShotAt(
          scheduledTime,
          100 + 10000,
          _playAdhanCallback,
          exact: true,
          wakeup: true,
          allowWhileIdle: true,
          rescheduleOnReboot: true,
        );
      }
    } catch (e) {
      print('[AlarmService] HATA sahurPreAlarm: $e');
    }
  }

  // =========================================================
  // TEST ALARMI  -  Future.delayed + show()
  // zonedSchedule yerine bu yöntem %100 güvenilir
  // =========================================================
  static Future<void> scheduleTestAlarm({
    required AlarmMode mode,
    int delaySeconds = 60,
  }) async {
    await _notifications.cancel(999);
    await _notifications.cancel(998);

    // 1) Anında onay bildirimi gönder (kullanıcı görsün)
    try {
      await _notifications.show(
        998,
        '⏱️ Test Alarmı Kuruldu',
        '$delaySeconds saniye sonra "${mode.displayName}" bildirim gelecek.',
        _buildDetails(
          AlarmMode.silent,
          channelId: 'ramadan_test_alarms',
          channelName: 'Test Alarmları',
        ),
      );
    } catch (e) {
      print('[AlarmService] Onay bildirimi hatası: $e');
    }

    // 2) Gecikme sonrası asıl test bildirimi
    Future.delayed(Duration(seconds: delaySeconds), () async {
      try {
        // Önce onay bildirimini kaldır
        await _notifications.cancel(998);

        await _notifications.show(
          999,
          '🔔 Test Alarmı',
          '${mode.displayName} modunda test alarmı çalıyor!',
          _buildDetails(
            mode,
            channelId: 'ramadan_test_alarms',
            channelName: 'Test Alarmları',
          ),
        );

        if (mode == AlarmMode.adhan) {
          _playAdhanCallback();
        }

        print('[AlarmService] Test alarmı tetiklendi! (${mode.displayName})');
      } catch (e) {
        print('[AlarmService] Test alarm tetikleme hatası: $e');
      }
    });
  }

  // =========================================================
  // İPTAL
  // =========================================================
  static Future<void> cancelAlarm(int id) async {
    await _notifications.cancel(id);
    await AndroidAlarmManager.cancel(id + 10000);
  }

  static Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
    for (int i = 0; i < 20; i++) {
      await AndroidAlarmManager.cancel(i + 10000);
    }
    await AndroidAlarmManager.cancel(100 + 10000);
  }

  // =========================================================
  // EZAN SESİ
  // =========================================================
  @pragma('vm:entry-point')
  static Future<void> _playAdhanCallback() async {
    final player = AudioPlayer();
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setSource(AssetSource('sounds/adhan_short.mp3'));
      await player.resume();

      // Wait 14 seconds (since audio is 13s)
      await Future.delayed(const Duration(seconds: 14));

      await player.stop();
      await player.dispose();
    } catch (e) {
      print('[AlarmService] Background Ezan Error: $e');
    }
  }

  static Future<void> testAdhanSound() async {
    // 1. Cancel any previous stop timer so it doesn't kill the new sound
    _stopTimer?.cancel();

    // 2. Stop any existing player safely
    await stopAdhan();

    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.setSource(AssetSource('sounds/adhan_short.mp3'));
      await _audioPlayer!.resume();

      // 3. Schedule stop after 14 seconds (Audio is 13s)
      _stopTimer = Timer(const Duration(seconds: 14), () {
        stopAdhan();
      });
    } catch (e) {
      print('[AlarmService] Test Play Error: $e');
      stopAdhan();
    }
  }

  static Future<void> stopAdhan() async {
    _stopTimer?.cancel();

    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.stop();
        await _audioPlayer!.dispose();
      } catch (e) {
        // Silently ignore "Player has not yet been created" errors
      } finally {
        _audioPlayer = null;
      }
    }
  }

  // =========================================================
  // İZİNLER
  // =========================================================
  static Future<bool> checkPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.areNotificationsEnabled();
      return granted ?? false;
    }
    return true;
  }

  static Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final notifGranted = await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
      return notifGranted ?? false;
    }
    return true;
  }

  static Future<List<PendingNotificationRequest>> getPendingAlarms() async {
    return await _notifications.pendingNotificationRequests();
  }
}
