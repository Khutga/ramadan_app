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
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  // Başlık Alanı
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24.0, left: 4),
                    child: Text(
                      'Ayarlar',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ),

                  _buildSectionHeader('MEZHEP & YÖNTEM'),
                  _buildMadhhabSelector(context, provider),

                  if (provider.madhhab == MadhhabType.sunni) ...[
                    const SizedBox(height: 16),
                    _buildSunniMethodSelector(context, provider),
                  ],
                  const SizedBox(height: 32),

                  _buildSectionHeader('KONUM SERVİSLERİ'),
                  _buildLocationCard(provider),
                  const SizedBox(height: 32),

                  _buildSectionHeader('ALARM & BİLDİRİM'),
                  _buildAlarmSettingsCard(context, provider),
                  const SizedBox(height: 32),

                  _buildSectionHeader('HAKKINDA'),
                  _buildInfoCard(),

                  const SizedBox(height: 80), // Alt boşluk
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Modern Bölüm Başlığı
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.6),
          letterSpacing: 1.5, // Harfleri açarak modern görünüm
        ),
      ),
    );
  }

  // Yenilenmiş Mezhep Seçici (Animated Selection Tile)
  Widget _buildMadhhabSelector(BuildContext context, AppProvider provider) {
    return Column(
      children: MadhhabType.values.map((madhhab) {
        final isSelected = provider.madhhab == madhhab;
        final activeColor =
            madhhab == MadhhabType.sunni ? AppColors.sunni : AppColors.shia;

        return _buildSelectionTile(
          isSelected: isSelected,
          activeColor: activeColor,
          icon: Icons.mosque_rounded,
          title: madhhab.displayName,
          subtitle: madhhab.description,
          onTap: () => provider.setMadhhab(madhhab),
        );
      }).toList(),
    );
  }

  Widget _buildSunniMethodSelector(BuildContext context, AppProvider provider) {
    return Column(
      children: SunniMethod.values.map((method) {
        final isSelected = provider.sunniMethod == method;

        return _buildSelectionTile(
          isSelected: isSelected,
          activeColor: AppColors.accent,
          icon: Icons.balance_rounded, // Terazi ikonu (metod için)
          title: method.displayName,
          subtitle: null, // Alt açıklama yoksa null
          onTap: () => provider.setSunniMethod(method),
          isCompact: true, // Daha az padding
        );
      }).toList(),
    );
  }

  // Tekrar kullanılabilir, animasyonlu seçim kartı
  Widget _buildSelectionTile({
    required bool isSelected,
    required Color activeColor,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.1)
              : AppColors.cardBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: Row(
                children: [
                  // İkon Alanı
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Metin Alanı
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.7)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Seçim İndikatörü (Check icon yerine Glow Dot)
                  if (isSelected)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ],
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

  Widget _buildLocationCard(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Koyu cam efekti
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.my_location_rounded, color: AppColors.accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.locationLoading
                      ? 'Konum Hesaplanıyor...'
                      : '${provider.cityName}, ${provider.countryName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Koordinatları teknik fontla göster
                Text(
                  'LAT: ${provider.latitude.toStringAsFixed(4)}  LNG: ${provider.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Courier', // Teknik görünüm için
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                if (provider.locationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      provider.locationError!,
                      style: const TextStyle(
                          color: AppColors.warning, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmSettingsCard(BuildContext context, AppProvider provider) {
    bool allEnabled = provider.alarmEnabled.values.every((e) => e);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ana Toggle Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tüm Bildirimler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Vakit alarmını aç/kapat',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: allEnabled,
                activeColor: AppColors.accent,
                onChanged: (value) {
                  for (final prayer in provider.prayerTimes) {
                    provider.toggleAlarm(prayer.name, value);
                  }
                },
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10),
          ),

          const Text(
            'VARSAYILAN MOD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          // Chip'ler yerine modern butonlar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AlarmMode.values.map((mode) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildModeButton(context, provider, mode),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Test Butonu
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                AlarmService.testAdhanSound();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Ezan sesi çalınıyor...'),
                    action: SnackBarAction(
                      label: 'Durdur',
                      textColor: AppColors.accent,
                      onPressed: AlarmService.stopAdhan,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: const Text('Sesi Test Et'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
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

  Widget _buildModeButton(
      BuildContext context, AppProvider provider, AlarmMode mode) {
    return InkWell(
      onTap: () {
        for (final prayer in provider.prayerTimes) {
          provider.setAlarmMode(prayer.name, mode);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tüm alarmlar ${mode.displayName} yapıldı')),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Text(mode.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              mode.displayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Uygulama Bilgisi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Bu uygulama, namaz vakitlerini astronomik hesaplama yöntemleriyle belirler. '
            'Konum bazlı en doğru sonuçlar için izinlerin açık olduğundan emin olun.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
