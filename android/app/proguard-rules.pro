# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Android Alarm Manager Plus
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }
-keep class dev.fluttercommunity.plus.androidalarmmanager.AlarmBroadcastReceiver { *; }
-keep class dev.fluttercommunity.plus.androidalarmmanager.AlarmService { *; }
-keep class dev.fluttercommunity.plus.androidalarmmanager.RebootBroadcastReceiver { *; }

# Gson - Bildirim payload serialize/deserialize için kritik
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keep class sun.misc.Unsafe { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# BroadcastReceiver ve Service sınıflarını koru
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.app.Service

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Genel Android
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception