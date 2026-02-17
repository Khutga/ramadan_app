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

  // =========================================================
  // Her alarm modu için AYRI notification channel
  // =========================================================
  static const String _channelIdAdhan = 'ramadan_adhan_v6';
  static const String _channelIdDefault = 'ramadan_default_v6';
  static const String _channelIdVibration = 'ramadan_vibration_v6';
  static const String _channelIdSilent = 'ramadan_silent_v6';
  static const String _channelIdTest = 'ramadan_test_v6';
  static const String _channelIdSahurAdhan = 'ramadan_sahur_adhan_v6';
  static const String _channelIdSahur = 'ramadan_sahur_v6';

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_getLocalTimezone()));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        print('Notification tapped: ${details.payload}');
      },
    );

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_getLocalTimezone()));

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Eski kanalları temizle
      final oldChannels = [
        'ramadan_alarms_v4',
        'ramadan_test_alarms_v4',
        'ramadan_sahur_channel_v4',
        'ramadan_adhan_v5',
        'ramadan_default_v5',
        'ramadan_vibration_v5',
        'ramadan_silent_v5',
        'ramadan_test_v5',
        'ramadan_sahur_adhan_v5',
        'ramadan_sahur_v5',
      ];
      for (final ch in oldChannels) {
        try {
          await androidPlugin.deleteNotificationChannel(ch);
        } catch (_) {}
      }

      // ---- Ezan sesli kanal ----
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdAdhan,
          'Ezan Alarmları',
          description: 'Ezan sesi ile namaz vakti bildirimleri',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('adhan_short'),
          enableVibration: true,
        ),
      );

      // ---- Varsayılan bildirim kanalı ----
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdDefault,
          'Namaz Vakti Bildirimleri',
          description: 'Standart bildirim sesi ile namaz vakti bildirimleri',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      // ---- Titreşim kanalı ----
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdVibration,
          'Titreşim Bildirimleri',
          description: 'Yalnızca titreşim ile uyarı',
          importance: Importance.max,
          playSound: false,
          enableVibration: true,
        ),
      );

      // ---- Sessiz kanal ----
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdSilent,
          'Sessiz Bildirimler',
          description: 'Sessiz bildirim',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
      );

      // ---- Test kanalı (ezan sesli) ----
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdTest,
          'Test Alarmları',
          description: 'Alarm test bildirimleri',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('adhan_short'),
          enableVibration: true,
        ),
      );

      // ---- Sahur ezan kanalı ----
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdSahurAdhan,
          'Sahur Ezan Alarmı',
          description: 'Sahura kalkma ezan bildirimi',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('adhan_short'),
          enableVibration: true,
        ),
      );

      // ---- Sahur varsayılan kanalı ----
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdSahur,
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
    print('[AlarmService] ✅ Başlatıldı');
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

  // =========================================================
  // Alarm moduna göre doğru channel ve ses ayarı
  // =========================================================
  static AndroidNotificationDetails _buildAndroidDetails(
    AlarmMode mode, {
    bool isSahur = false,
    bool isTest = false,
  }) {
    switch (mode) {
      case AlarmMode.adhan:
        final channelId = isTest
            ? _channelIdTest
            : isSahur
                ? _channelIdSahurAdhan
                : _channelIdAdhan;
        final channelName = isTest
            ? 'Test Alarmları'
            : isSahur
                ? 'Sahur Ezan Alarmı'
                : 'Ezan Alarmları';
        return AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Ezan sesi ile bildirim',
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
          isSahur ? _channelIdSahur : _channelIdVibration,
          isSahur ? 'Sahur Kalkma Alarmı' : 'Titreşim Bildirimleri',
          channelDescription: 'Titreşim bildirimi',
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
          _channelIdSilent,
          'Sessiz Bildirimler',
          channelDescription: 'Sessiz bildirim',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
        );

      case AlarmMode.notification:
      default:
        final channelId = isTest
            ? _channelIdDefault
            : isSahur
                ? _channelIdSahur
                : _channelIdDefault;
        final channelName = isTest
            ? 'Namaz Vakti Bildirimleri'
            : isSahur
                ? 'Sahur Kalkma Alarmı'
                : 'Namaz Vakti Bildirimleri';
        return AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Bildirim',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        );
    }
  }

  static NotificationDetails _buildDetails(
    AlarmMode mode, {
    bool isSahur = false,
    bool isTest = false,
  }) {
    return NotificationDetails(
      android: _buildAndroidDetails(mode, isSahur: isSahur, isTest: isTest),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  // =========================================================
  // ANLIK TEST - Hemen bildirim gönder (debug için)
  // =========================================================
  static Future<bool> sendInstantTestNotification() async {
    try {
      await _notifications.show(
        900,
        '✅ Bildirim Testi Başarılı!',
        'Bu bildirimi görüyorsanız bildirim izinleri doğru çalışıyor.',
        _buildDetails(AlarmMode.notification, isTest: true),
      );
      print('[AlarmService] ✅ Anlık test bildirimi gönderildi');
      return true;
    } catch (e) {
      print('[AlarmService] ❌ Anlık test BAŞARISIZ: $e');
      return false;
    }
  }

  // =========================================================
  // ANLIK EZAN TESTİ
  // =========================================================
  static Future<bool> sendInstantAdhanNotification() async {
    try {
      await _notifications.show(
        901,
        '🕌 Ezan Sesi Testi',
        'Ezan sesi çalıyor olmalı...',
        _buildDetails(AlarmMode.adhan, isTest: true),
      );
      print('[AlarmService] ✅ Ezan test bildirimi gönderildi');
      return true;
    } catch (e) {
      print('[AlarmService] ❌ Ezan test BAŞARISIZ: $e');
      return false;
    }
  }

  // =========================================================
  // İZİN DURUMUNU KONTROL ET (detaylı)
  // =========================================================
  static Future<Map<String, bool>> checkAllPermissions() async {
    final result = <String, bool>{};

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final notifEnabled = await android.areNotificationsEnabled();
      result['notifications'] = notifEnabled ?? false;

      try {
        final exactAlarm = await android.canScheduleExactNotifications();
        result['exactAlarms'] = exactAlarm ?? false;
      } catch (e) {
        result['exactAlarms'] = false;
      }
    } else {
      result['notifications'] = true;
      result['exactAlarms'] = true;
    }

    result['initialized'] = _initialized;
    return result;
  }

  // =========================================================
  // DEBUG BİLGİSİ
  // =========================================================
  static Future<String> getDebugInfo() async {
    final perms = await checkAllPermissions();
    final pending = await _notifications.pendingNotificationRequests();

    final buffer = StringBuffer();
    buffer.writeln('=== ALARM DEBUG ===');
    buffer.writeln('Initialized: ${perms['initialized']}');
    buffer.writeln('Bildirim izni: ${perms['notifications']}');
    buffer.writeln('Exact alarm izni: ${perms['exactAlarms']}');
    buffer.writeln('Timezone: ${tz.local.name}');
    buffer.writeln('Bekleyen alarm: ${pending.length}');

    for (final p in pending) {
      buffer.writeln('  [${p.id}] ${p.title}');
    }

    return buffer.toString();
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
    if (scheduledTime.isBefore(DateTime.now())) {
      print('[AlarmService] ⏭️ Geçmiş: $title @ $scheduledTime');
      return;
    }

    try {
      final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        _buildDetails(mode),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('[AlarmService] ✅ Kuruldu: $title @ $scheduledTime (id:$id)');
    } catch (e) {
      print('[AlarmService] ❌ HATA: $e');
      // Fallback: inexact
      try {
        final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzTime,
          _buildDetails(mode),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: null,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('[AlarmService] ⚠️ Inexact olarak kuruldu: $title');
      } catch (e2) {
        print('[AlarmService] ❌ Fallback de BAŞARISIZ: $e2');
      }
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

    int scheduledCount = 0;

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
      scheduledCount++;
    }

    print('[AlarmService] 📊 Toplam $scheduledCount alarm kuruldu');
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

    try {
      await _notifications.zonedSchedule(
        100,
        'Sahura Kalkma Zamanı! ⏰',
        'İmsak vaktine $offsetMinutes dakika kaldı.',
        tz.TZDateTime.from(scheduledTime, tz.local),
        _buildDetails(mode, isSahur: true),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('[AlarmService] ✅ Sahur alarmı: $scheduledTime');
    } catch (e) {
      print('[AlarmService] ❌ Sahur alarm HATA: $e');
    }
  }

  // =========================================================
  // TEST ALARMI (zamanlanmış)
  // =========================================================
  static Future<void> scheduleTestAlarm({
    required AlarmMode mode,
    int delaySeconds = 60,
  }) async {
    await _notifications.cancel(999);
    await _notifications.cancel(998);

    final scheduledTime = DateTime.now().add(Duration(seconds: delaySeconds));

    // Anında onay
    try {
      await _notifications.show(
        998,
        '⏱️ Test Alarmı Kuruldu',
        '$delaySeconds saniye sonra "${mode.displayName}" bildirim gelecek.',
        _buildDetails(AlarmMode.notification),
      );
    } catch (e) {
      print('[AlarmService] Onay hatası: $e');
    }

    // Zamanlanmış test
    try {
      await _notifications.zonedSchedule(
        999,
        '🔔 Test Alarmı',
        '${mode.displayName} modunda test alarmı çalıyor!',
        tz.TZDateTime.from(scheduledTime, tz.local),
        _buildDetails(mode, isTest: true),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('[AlarmService] ✅ Test alarmı: $scheduledTime');
    } catch (e) {
      print('[AlarmService] ❌ Test alarm HATA: $e');
    }
  }

  // =========================================================
  // İPTAL
  // =========================================================
  static Future<void> cancelAlarm(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
  }

  // =========================================================
  // EZAN SESİ — Sadece uygulama içi test
  // =========================================================
  static Future<void> testAdhanSound() async {
    _stopTimer?.cancel();
    await stopAdhan();

    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.setSource(AssetSource('sounds/adhan_short.mp3'));
      await _audioPlayer!.resume();

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
        // Sessizce geç
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

  static Future<void> scheduleNormalTestAlarm() async {
    final now = DateTime.now();
    final scheduledTime = now.add(const Duration(seconds: 10));

    await _notifications.zonedSchedule(
      999, // test id
      'Test Alarmı',
      '10 saniye geçti 🚀',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'normal_alarm_channel',
          'Normal Alarmlar',
          channelDescription: 'Normal test alarm kanalı',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );

    print('🔔 Normal test alarm kuruldu: $scheduledTime');
  }
}
