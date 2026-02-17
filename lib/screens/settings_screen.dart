import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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

                  _buildSectionHeader('HESAPLAMA YÖNTEMİ'),
                  _buildCalculationMethodCard(context, provider),
                  const SizedBox(height: 32),

                  _buildSectionHeader('KONUM SERVİSLERİ'),
                  _buildLocationCard(provider),
                  const SizedBox(height: 32),

                  _buildSectionHeader('ALARM & BİLDİRİM'),
                  _buildAlarmSettingsCard(context, provider),
                  const SizedBox(height: 16),
                  _TestAlarmCard(),
                  const SizedBox(height: 32),

                  _buildSectionHeader('SAHUR ALARMI'),
                  _buildSahurAlarmCard(context, provider),
                  const SizedBox(height: 32),

                  // ===== YENİ: DEBUG BÖLÜMÜ =====
                  _buildSectionHeader('BİLDİRİM TEŞHİS'),
                  const _DebugCard(),
                  const SizedBox(height: 32),

                  _buildSectionHeader('HAKKINDA'),
                  _buildInfoCard(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.6),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // =========================================================
  // HESAPLAMA YÖNTEMİ KARTI
  // =========================================================
  Widget _buildCalculationMethodCard(
      BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calculate_outlined,
                    color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vakit Hesaplama Yöntemi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Namaz vakitleri hesaplamasını seçin',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildSunniMethods(provider),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white10),
          ),
          _buildMethodTile(
            isSelected: provider.madhhab == MadhhabType.shia,
            title: 'Caferi (Tahran)',
            subtitle: 'Fecr: 17.7° / İşa: 14° • Mağrib gecikmeli',
            activeColor: AppColors.shia,
            onTap: () => provider.setMadhhab(MadhhabType.shia),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSunniMethods(AppProvider provider) {
    return SunniMethod.values.map((method) {
      final isSelected = provider.madhhab == MadhhabType.sunni &&
          provider.sunniMethod == method;

      String subtitle;
      switch (method) {
        case SunniMethod.diyanet:
          subtitle = 'Türkiye resmi yöntemi';
          break;
        case SunniMethod.muslimWorldLeague:
          subtitle = 'Avrupa ve dünya geneli';
          break;
        case SunniMethod.isna:
          subtitle = 'Kuzey Amerika';
          break;
        case SunniMethod.egypt:
          subtitle = 'Mısır ve Afrika';
          break;
        case SunniMethod.umm_al_qura:
          subtitle = 'Suudi Arabistan';
          break;
      }

      return _buildMethodTile(
        isSelected: isSelected,
        title: method.displayName,
        subtitle: subtitle,
        activeColor: AppColors.sunni,
        onTap: () {
          provider.setMadhhab(MadhhabType.sunni);
          provider.setSunniMethod(method);
        },
      );
    }).toList();
  }

  Widget _buildMethodTile({
    required bool isSelected,
    required String title,
    required String subtitle,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor.withOpacity(0.4) : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white.withOpacity(0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withOpacity(0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
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

  // =========================================================
  // KONUM KARTI
  // =========================================================
  Widget _buildLocationCard(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
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
                Text(
                  'LAT: ${provider.latitude.toStringAsFixed(4)}  LNG: ${provider.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Courier',
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

  // =========================================================
  // ALARM & BİLDİRİM KARTI
  // =========================================================
  Widget _buildAlarmSettingsCard(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
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
              ),
              Switch(
                value: provider.allAlarmsEnabled,
                activeColor: AppColors.accent,
                onChanged: (value) {
                  provider.toggleAllAlarms(value);
                },
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10),
          ),
          const Text(
            'TÜM VAKİTLERE UYGULA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.8,
            children: AlarmMode.values.map((mode) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    provider.setAllAlarmModes(mode);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Tüm alarmlar ${mode.displayName} yapıldı'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(mode.icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            mode.displayName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SAHUR ALARMI KARTI
  // =========================================================
  Widget _buildSahurAlarmCard(BuildContext context, AppProvider provider) {
    final imsakTime = provider.imsakTime;
    final sahurAlarmTime = provider.sahurAlarmTime;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF243B55).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.alarm, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sahura Kalkma Alarmı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: provider.sahurAlarmEnabled,
                activeColor: AppColors.accent,
                onChanged: (value) {
                  provider.toggleSahurAlarm(value);
                },
              ),
            ],
          ),
          if (!provider.sahurAlarmEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'İmsak vaktinden önce çalacak alarm ayarlayın',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
            ),
          if (provider.sahurAlarmEnabled) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            const Text(
              'İmsak\'tan kaç dakika önce?',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOffsetBtn(Icons.remove, () {
                  if (provider.sahurAlarmOffset > 5) {
                    provider.setSahurAlarmOffset(provider.sahurAlarmOffset - 5);
                  }
                }),
                Container(
                  width: 80,
                  alignment: Alignment.center,
                  child: Text(
                    '${provider.sahurAlarmOffset} dk',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                _buildOffsetBtn(Icons.add, () {
                  if (provider.sahurAlarmOffset < 120) {
                    provider.setSahurAlarmOffset(provider.sahurAlarmOffset + 5);
                  }
                }),
              ],
            ),
            const SizedBox(height: 16),
            if (imsakTime != null && sahurAlarmTime != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('⏰', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Alarm Çalacak',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(sahurAlarmTime),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    Row(
                      children: [
                        const Text('🍽️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'İmsak (Son Yemek)',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(imsakTime),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (sahurAlarmTime != null &&
                imsakTime != null &&
                sahurAlarmTime.isAfter(imsakTime))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Alarm zamanı İmsak\'tan sonra!\nLütfen süreyi artırın.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
            const Text(
              'Alarm Modu',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AlarmMode.values.map((mode) {
                final isSelected = provider.sahurAlarmMode == mode;
                return GestureDetector(
                  onTap: () => provider.setSahurAlarmMode(mode),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent.withOpacity(0.4)
                            : Colors.white10,
                      ),
                    ),
                    child: Text(
                      '${mode.icon} ${mode.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOffsetBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Icon(icon, color: AppColors.accent, size: 20),
      ),
    );
  }

  // =========================================================
  // HAKKINDA KARTI
  // =========================================================
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
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.copyright_rounded,
                  color: AppColors.textSecondary.withOpacity(0.7), size: 16),
              const SizedBox(width: 8),
              Text(
                '2026 Codefellas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.email_outlined,
                  color: AppColors.textSecondary.withOpacity(0.7), size: 16),
              const SizedBox(width: 8),
              Text(
                'info@codefellas.com.tr',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.accent.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================
// DEBUG KARTI - BİLDİRİM TEŞHİS
// =========================================================
class _DebugCard extends StatefulWidget {
  const _DebugCard();

  @override
  State<_DebugCard> createState() => _DebugCardState();
}

class _DebugCardState extends State<_DebugCard> {
  String _debugInfo = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bug_report,
                    color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bildirim Teşhis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Bildirimlerin çalışıp çalışmadığını test edin',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Anlık bildirim test butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      final result =
                          await AlarmService.sendInstantTestNotification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result
                                ? '✅ Bildirim gönderildi! Yukarıda görüyor musunuz?'
                                : '❌ Bildirim gönderilemedi! İzin sorunu olabilir.'),
                            backgroundColor:
                                result ? AppColors.success : AppColors.danger,
                          ),
                        );
                        setState(() => _loading = false);
                      }
                    },
              icon: const Icon(Icons.notifications_active, size: 18),
              label: const Text('Anlık Bildirim Gönder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Anlık ezan test butonu
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      final result =
                          await AlarmService.sendInstantAdhanNotification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result
                                ? '🕌 Ezan bildirimi gönderildi! Ses geliyor mu?'
                                : '❌ Ezan bildirimi gönderilemedi!'),
                            backgroundColor:
                                result ? AppColors.success : AppColors.danger,
                          ),
                        );
                        setState(() => _loading = false);
                      }
                    },
              icon: const Text('🕌', style: TextStyle(fontSize: 18)),
              label: const Text('Anlık Ezan Sesi Testi'),
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

          const SizedBox(height: 12),

          // Debug bilgi butonu
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                final info = await AlarmService.getDebugInfo();
                setState(() => _debugInfo = info);
              },
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('İzin & Alarm Durumunu Göster'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ),

          if (_debugInfo.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _debugInfo,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Courier',
                  color: Colors.greenAccent,
                  height: 1.5,
                ),
              ),
            ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),

          // Samsung uyarısı
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.phone_android,
                        color: AppColors.warning, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Samsung Kullanıcıları',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Ayarlar > Uygulamalar > Ramazan Modu > Pil > Kısıtlanmamış\n'
                  '2. Ayarlar > Pil > Arka plan kullanım sınırları > Uyuyan uygulamalardan ÇIKARIN\n'
                  '3. Ayarlar > Uygulamalar > Ramazan Modu > Bildirimler > Tüm kanalları AÇIN\n'
                  '4. Ayarlar > Uygulamalar > Ramazan Modu > Alarm ve hatırlatıcılar > İZİN VERİN',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withOpacity(0.9),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// TEST ALARM KARTI (StatefulWidget)
// =========================================================
class _TestAlarmCard extends StatefulWidget {
  @override
  State<_TestAlarmCard> createState() => _TestAlarmCardState();
}

class _TestAlarmCardState extends State<_TestAlarmCard> {
  AlarmMode _selectedTestMode = AlarmMode.notification;
  bool _isScheduled = false;
  DateTime? _scheduledTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: _isScheduled
            ? Border.all(color: AppColors.success.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.science_outlined,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alarm Test Et',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '1 dakika sonra test bildirimi gönderir',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Test Modu',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AlarmMode.values.map((mode) {
              final isSelected = _selectedTestMode == mode;
              return GestureDetector(
                onTap: () => setState(() => _selectedTestMode = mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.5)
                          : Colors.white10,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mode.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        mode.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: false
                  ? null
                  : () async {
                      /* await AlarmService.scheduleNormalTestAlarm(); */
                      await AlarmService.scheduleTestAlarm(
                        mode: _selectedTestMode,
                        delaySeconds: 60,
                      );
                      setState(() {
                        _isScheduled = true;
                        _scheduledTime =
                            DateTime.now().add(const Duration(seconds: 60));
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${_selectedTestMode.icon} Test alarmı 1 dakika sonra çalacak!'),
                            duration: const Duration(seconds: 60),
                          ),
                        );
                      }

                      Future.delayed(const Duration(seconds: 65), () {
                        if (mounted) {
                          setState(() {
                            _isScheduled = false;
                            _scheduledTime = null;
                          });
                        }
                      });
                    },
              icon: Icon(
                _isScheduled ? Icons.check_circle_outline : Icons.send_rounded,
                size: 20,
              ),
              label: Text(
                _isScheduled
                    ? 'Alarm Kuruldu! (${_selectedTestMode.displayName})'
                    : '1 dk Sonra Test Alarmı Kur',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScheduled
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.accent,
                foregroundColor:
                    _isScheduled ? AppColors.success : AppColors.primaryDark,
                disabledBackgroundColor: AppColors.success.withOpacity(0.2),
                disabledForegroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          if (_isScheduled && _scheduledTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  'Alarm zamanı: ${DateFormat("HH:mm:ss").format(_scheduledTime!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success.withOpacity(0.8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
