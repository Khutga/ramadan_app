import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_app/models/prayer_model.dart';

import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/quran_verse_card.dart';
import '../widgets/prayer_mini_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CountdownWidget(
                      nextPrayer: provider.nextPrayer,
                      timeUntilNext: provider.timeUntilNext,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildIftarSahurCards(provider),
                ),

                SliverToBoxAdapter(
                  child: _buildPrayerTimesPreview(provider),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: QuranVerseCard(
                      verse: provider.dailyVerse,
                      onRefresh: provider.refreshVerse,
                    ),
                  ),
                ),

                if (provider.ramadanDay > 0)
                  SliverToBoxAdapter(
                    child: _buildRamadanProgress(provider),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    final now = DateTime.now();
    final dateFormat = DateFormat('d MMMM yyyy, EEEE', 'tr_TR');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🌙 Ramazan Mübarek',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
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
                    provider.locationLoading
                        ? 'Konum alınıyor...'
                        : '${provider.cityName}, ${provider.countryName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(now),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: provider.madhhab == MadhhabType.sunni
                  ? AppColors.sunni.withOpacity(0.2)
                  : AppColors.shia.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: provider.madhhab == MadhhabType.sunni
                    ? AppColors.sunni.withOpacity(0.5)
                    : AppColors.shia.withOpacity(0.5),
              ),
            ),
            child: Text(
              provider.madhhab.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: provider.madhhab == MadhhabType.sunni
                    ? AppColors.sunni
                    : AppColors.shia,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final days = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
    ];
    return '${date.day} ${months[date.month]} ${date.year}, ${days[date.weekday - 1]}';
  }

  Widget _buildIftarSahurCards(AppProvider provider) {
    DateTime? iftarTime;
    DateTime? sahurTime;

    for (final prayer in provider.prayerTimes) {
      if (prayer.name.contains('İftar') || prayer.name.contains('Mağrib')) {
        iftarTime = prayer.time;
      }
      if (prayer.name.contains('İmsak') || prayer.name.contains('Sahur')) {
        sahurTime = prayer.time;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildTimeCard(
              title: 'Sahur',
              time: sahurTime,
              icon: Icons.nightlight_round,
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTimeCard(
              title: 'İftar',
              time: iftarTime,
              icon: Icons.wb_twilight_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFBF360C), Color(0xFFE65100)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard({
    required String title,
    required DateTime? time,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    final timeStr = time != null ? DateFormat('HH:mm').format(time) : '--:--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesPreview(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bugünün Vakitleri',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: provider.prayerTimes.map((prayer) {
                return PrayerMiniCard(
                  prayer: prayer,
                  isNext: provider.nextPrayer?.name == prayer.name,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRamadanProgress(AppProvider provider) {
    final progress = provider.ramadanDay / provider.totalRamadanDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ramazan İlerlemesi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${provider.ramadanDay}/${provider.totalRamadanDays} gün',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.surfaceLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
