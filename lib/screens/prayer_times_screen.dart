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
                  child: _buildHeader(context, provider),
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

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Namaz Vakitleri',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              // Bilgi butonu
              GestureDetector(
                onTap: () => _showCalculationInfo(context, provider),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.3),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'i',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
              Flexible(
                child: Text(
                  '${provider.cityName} • ${provider.madhhab == MadhhabType.shia ? "Caferi" : provider.sunniMethod.displayName}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCalculationInfo(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calculate_outlined,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Hesaplama Bilgisi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      provider.calculationMethodInfo,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Konum Bilgisi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${provider.cityName}, ${provider.countryName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enlem: ${provider.latitude.toStringAsFixed(4)}  Boylam: ${provider.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Courier',
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vakitler astronomik hesaplama ile belirlenir ve konumunuza göre hesaplanır. '
                    'Hesaplama yöntemini Ayarlar sayfasından değiştirebilirsiniz.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
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
                'Caferi hesaplaması: Akşam namazı güneş batışından ~17 dk sonra başlar.',
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
    final alarmMode =
        provider.alarmModes[prayer.name] ?? AlarmMode.notification;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isNext
              ? AppColors.accent.withOpacity(0.1)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isNext
              ? Border.all(
                  color: AppColors.accent.withOpacity(0.4), width: 1.5)
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
                  // Sol kısım: Vakit ismi ve Arapça
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                            Flexible(
                              child: Text(
                                prayer.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isNext
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isPassed && !isNext
                                      ? AppColors.textSecondary
                                          .withOpacity(0.6)
                                      : AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              prayer.nameArabic,
                              style: TextStyle(
                                fontSize: 13,
                                color: isPassed && !isNext
                                    ? AppColors.textSecondary.withOpacity(0.4)
                                    : AppColors.textSecondary,
                              ),
                            ),
                            // Alarm modu göstergesi - ismin yanına küçük ikon
                            if (isEnabled) ...[
                              const SizedBox(width: 8),
                              Text(
                                alarmMode.icon,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Saat
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

                  // Switch
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
    final currentMode =
        provider.alarmModes[prayer.name] ?? AlarmMode.notification;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
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
                                  ? Border.all(
                                      color:
                                          AppColors.accent.withOpacity(0.4))
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                content: const Text(
                                    'Ezan sesi test ediliyor...'),
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
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
}