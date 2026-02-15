import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../models/prayer_model.dart';
import '../services/alarm_service.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Ayarlar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Mezhep'),
                const SizedBox(height: 8),
                _buildMadhhabSelector(context, provider),
                const SizedBox(height: 20),

                if (provider.madhhab == MadhhabType.sunni) ...[
                  _buildSectionTitle('Hesaplama Yöntemi'),
                  const SizedBox(height: 8),
                  _buildSunniMethodSelector(context, provider),
                  const SizedBox(height: 20),
                ],

                _buildSectionTitle('Konum'),
                const SizedBox(height: 8),
                _buildLocationCard(provider),
                const SizedBox(height: 20),

                _buildSectionTitle('Alarm Ayarları'),
                const SizedBox(height: 8),
                _buildAlarmSettingsCard(context, provider),
                const SizedBox(height: 20),

                _buildSectionTitle('Bilgi'),
                const SizedBox(height: 8),
                _buildInfoCard(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMadhhabSelector(BuildContext context, AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: MadhhabType.values.map((madhhab) {
          final isSelected = provider.madhhab == madhhab;
          final color = madhhab == MadhhabType.sunni
              ? AppColors.sunni
              : AppColors.shia;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => provider.setMadhhab(madhhab),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.mosque_rounded,
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            madhhab.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? color : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            madhhab.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<MadhhabType>(
                      value: madhhab,
                      groupValue: provider.madhhab,
                      onChanged: (value) {
                        if (value != null) provider.setMadhhab(value);
                      },
                      activeColor: color,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSunniMethodSelector(BuildContext context, AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: SunniMethod.values.map((method) {
          final isSelected = provider.sunniMethod == method;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => provider.setSunniMethod(method),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        method.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.accent,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLocationCard(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.locationLoading
                          ? 'Konum alınıyor...'
                          : '${provider.cityName}, ${provider.countryName}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${provider.latitude.toStringAsFixed(4)}°, ${provider.longitude.toStringAsFixed(4)}°',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (provider.locationError != null) ...[
            const SizedBox(height: 8),
            Text(
              provider.locationError!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlarmSettingsCard(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Her namaz vakti için alarm modunu ayarlamak için Vakitler sekmesindeki namaza dokunun.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tüm Alarmları Aç',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Switch(
                value: provider.alarmEnabled.values.every((e) => e),
                onChanged: (value) {
                  for (final prayer in provider.prayerTimes) {
                    provider.toggleAlarm(prayer.name, value);
                  }
                },
              ),
            ],
          ),
          const Divider(color: AppColors.surfaceLight),

          const Text(
            'Varsayılan Alarm Modu',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AlarmMode.values.map((mode) {
              return ActionChip(
                label: Text('${mode.icon} ${mode.displayName}'),
                onPressed: () {
                  for (final prayer in provider.prayerTimes) {
                    provider.setAlarmMode(prayer.name, mode);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tüm alarmlar "${mode.displayName}" moduna ayarlandı',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                backgroundColor: AppColors.surfaceLight,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                AlarmService.testAdhanSound();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Ezan sesi test ediliyor (5 sn)...'),
                    action: SnackBarAction(
                      label: 'Durdur',
                      onPressed: AlarmService.stopAdhan,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.volume_up, size: 18),
              label: const Text('Ezan Sesini Test Et'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(
                  color: AppColors.accent.withOpacity(0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ramazan Uygulaması',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bu uygulama namaz vakitlerini astronomik hesaplama yöntemleriyle '
            'hesaplar. Sünni ve Şii (Caferi) hesaplama yöntemleri arasındaki '
            'temel farklar, güneş batışı sonrası akşam namazı zamanlaması ve '
            'fecr/işa açılarıdır.\n\n'
            'Alarm özelliği uygulama kapalıyken de çalışır. Ezan sesi modu '
            'seçildiğinde, ezan sesinin ilk 3 saniyesi loop olarak çalar.\n\n'
            'Namaz vakitleri konum bazlı hesaplanır. En doğru sonuçlar için '
            'konum izni verilmesi önerilir.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Versiyon 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
