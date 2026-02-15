import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../models/prayer_model.dart';
import '../utils/theme.dart';
import '../services/alarm_service.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(provider),
                ),

                if (provider.madhhab == MadhhabType.shia)
                  SliverToBoxAdapter(
                    child: _buildShiaInfoBanner(),
                  ),

                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final prayer = provider.prayerTimes[index];
                      final isNext =
                          provider.nextPrayer?.name == prayer.name;
                      return _buildPrayerCard(
                        context,
                        prayer,
                        isNext,
                        provider,
                      );
                    },
                    childCount: provider.prayerTimes.length,
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildTimeDifferenceCard(context, provider),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Namaz Vakitleri',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${provider.cityName} • ${provider.madhhab.displayName}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (provider.madhhab == MadhhabType.sunni) ...[
                const Text(
                  ' • ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  provider.sunniMethod.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiaInfoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.shia.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.shia.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.shia, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Şii (Caferi) hesaplaması: Akşam namazı güneş batışından ~17 dk sonra başlar. Öğle ve İkindi ile Akşam ve Yatsı birleştirilebilir.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard(
    BuildContext context,
    PrayerTimeModel prayer,
    bool isNext,
    AppProvider provider,
  ) {
    final timeStr = DateFormat('HH:mm').format(prayer.time);
    final isPassed = prayer.time.isBefore(DateTime.now());
    final isEnabled = provider.alarmEnabled[prayer.name] ?? false;
    final alarmMode = provider.alarmModes[prayer.name] ?? AlarmMode.notification;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isNext
              ? AppColors.accent.withOpacity(0.1)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isNext
              ? Border.all(color: AppColors.accent.withOpacity(0.4), width: 1.5)
              : null,
          boxShadow: isNext
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showAlarmDialog(context, prayer, provider),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isNext)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(
                              prayer.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    isNext ? FontWeight.bold : FontWeight.w500,
                                color: isPassed && !isNext
                                    ? AppColors.textSecondary.withOpacity(0.6)
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prayer.nameArabic,
                          style: TextStyle(
                            fontSize: 13,
                            color: isPassed && !isNext
                                ? AppColors.textSecondary.withOpacity(0.4)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isEnabled)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            alarmMode.icon,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            alarmMode.displayName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: isNext
                          ? AppColors.accent
                          : isPassed
                              ? AppColors.textSecondary.withOpacity(0.5)
                              : AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(width: 8),

                  SizedBox(
                    height: 28,
                    child: Switch(
                      value: isEnabled,
                      onChanged: (value) {
                        provider.toggleAlarm(prayer.name, value);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAlarmDialog(
    BuildContext context,
    PrayerTimeModel prayer,
    AppProvider provider,
  ) {
    final currentMode = provider.alarmModes[prayer.name] ?? AlarmMode.notification;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                '${prayer.name} Alarm Ayarları',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(prayer.time),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Alarm Modu',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              ...AlarmMode.values.map((mode) {
                final isSelected = mode == currentMode;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        provider.setAlarmMode(prayer.name, mode);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent.withOpacity(0.1)
                              : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppColors.accent.withOpacity(0.4))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              mode.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mode.displayName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.accent
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _getModeDescription(mode),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.accent,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              if (currentMode == AlarmMode.adhan)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AlarmService.testAdhanSound();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Ezan sesi test ediliyor...'),
                            action: SnackBarAction(
                              label: 'Durdur',
                              onPressed: AlarmService.stopAdhan,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Ezan Sesini Test Et'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: BorderSide(
                          color: AppColors.accent.withOpacity(0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _getModeDescription(AlarmMode mode) {
    switch (mode) {
      case AlarmMode.notification:
        return 'Standart bildirim sesi ile uyarı';
      case AlarmMode.adhan:
        return 'Ezan sesi (3 saniyelik loop) ile uyarı';
      case AlarmMode.vibration:
        return 'Yalnızca titreşim ile uyarı';
      case AlarmMode.silent:
        return 'Sessiz bildirim (ses ve titreşim yok)';
    }
  }

  Widget _buildTimeDifferenceCard(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.compare_arrows, color: AppColors.accent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Sünni / Şii Farkları',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDiffRow(
              'İftar Vakti',
              'Güneş batışı ile',
              'Güneş batışından ~17 dk sonra\n(kızıllık kaybolunca)',
            ),
            const Divider(color: AppColors.surfaceLight, height: 16),
            _buildDiffRow(
              'Akşam Namazı',
              'Güneş batışı',
              'Güneş batışından ~17 dk sonra',
            ),
            const Divider(color: AppColors.surfaceLight, height: 16),
            _buildDiffRow(
              'Namaz Birleştirme',
              'Her vakit ayrı kılınır',
              'Öğle+İkindi ve\nAkşam+Yatsı birleştirilebilir',
            ),
            const Divider(color: AppColors.surfaceLight, height: 16),
            _buildDiffRow(
              'Hesaplama',
              'Fecr: 18° / İşa: 17°\n(Diyanet)',
              'Fecr: 16° / İşa: 14°\n(Tahran / Caferi)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffRow(String title, String sunni, String shia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.sunni.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sünni',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sunni,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sunni,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.shia.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Şii',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.shia,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shia,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
