import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'providers/app_provider.dart';
import 'services/alarm_service.dart';
import 'screens/main_screen.dart';
import 'utils/theme.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// =========================================================
// 1. DÜZELTME: @pragma BURAYA, EN DIŞARIYA EKLENİR!
// Uygulama tamamen kapalıyken (kill) bildirime tıklandığında
// veya arka plan işlemi gerektiğinde sistem bu fonksiyonu bulur.
// =========================================================
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Arka planda bildirime tıklandı.
  // Buradan istersen AlarmService.stopAdhan() çağırarak çalan sesi susturabilirsin.
  print('[Background Notification] Tıklandı: ${notificationResponse.payload}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HijriCalendar.setLocal('tr');
  await initializeDateFormatting('tr_TR', null);
  await MobileAds.instance.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Alarm Manager başlat
  await AndroidAlarmManager.initialize();

  // Bildirim eklentisini başlat
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) {
      // Uygulama açıkken bildirime tıklanınca yapılacak işlem
      print('[Notification] Tıklandı: ${details.payload}');
    },
    // =========================================================
    // 2. DÜZELTME: Arka plan handler'ını buraya veriyoruz!
    // =========================================================
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // Android bildirim izinlerini iste
  final androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.requestNotificationsPermission();
    await androidPlugin.requestExactAlarmsPermission();
  }

  runApp(const RamadanApp());
}

class RamadanApp extends StatelessWidget {
  const RamadanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'Ramazan Modu',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
