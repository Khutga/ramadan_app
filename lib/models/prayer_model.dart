class PrayerTimeModel {
  final String name;
  final String nameArabic;
  final DateTime time;
  final bool isAlarmEnabled;
  final AlarmMode alarmMode;

  PrayerTimeModel({
    required this.name,
    required this.nameArabic,
    required this.time,
    this.isAlarmEnabled = false,
    this.alarmMode = AlarmMode.notification,
  });

  PrayerTimeModel copyWith({
    String? name,
    String? nameArabic,
    DateTime? time,
    bool? isAlarmEnabled,
    AlarmMode? alarmMode,
  }) {
    return PrayerTimeModel(
      name: name ?? this.name,
      nameArabic: nameArabic ?? this.nameArabic,
      time: time ?? this.time,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      alarmMode: alarmMode ?? this.alarmMode,
    );
  }
}

enum AlarmMode {
  notification,
  adhan,      
  vibration,  
  silent,     
}

extension AlarmModeExtension on AlarmMode {
  String get displayName {
    switch (this) {
      case AlarmMode.notification:
        return 'Bildirim';
      case AlarmMode.adhan:
        return 'Ezan Sesi';
      case AlarmMode.vibration:
        return 'Titreşim';
      case AlarmMode.silent:
        return 'Sessiz';
    }
  }

  String get icon {
    switch (this) {
      case AlarmMode.notification:
        return '🔔';
      case AlarmMode.adhan:
        return '🕌';
      case AlarmMode.vibration:
        return '📳';
      case AlarmMode.silent:
        return '🔕';
    }
  }
}

enum MadhhabType {
  sunni,
  shia,
}

extension MadhhabExtension on MadhhabType {
  String get displayName {
    switch (this) {
      case MadhhabType.sunni:
        return 'Sünni';
      case MadhhabType.shia:
        return 'Şii';
    }
  }

  String get description {
    switch (this) {
      case MadhhabType.sunni:
        return 'Diyanet / MWL / ISNA hesaplama';
      case MadhhabType.shia:
        return 'Caferi hesaplama yöntemi';
    }
  }
}

enum SunniMethod {
  diyanet,
  muslimWorldLeague,
  isna,
  egypt,
  umm_al_qura,
}

extension SunniMethodExtension on SunniMethod {
  String get displayName {
    switch (this) {
      case SunniMethod.diyanet:
        return 'Diyanet İşleri';
      case SunniMethod.muslimWorldLeague:
        return 'Muslim World League';
      case SunniMethod.isna:
        return 'ISNA';
      case SunniMethod.egypt:
        return 'Mısır Genel Müftülüğü';
      case SunniMethod.umm_al_qura:
        return 'Ümmül Kura';
    }
  }
}
