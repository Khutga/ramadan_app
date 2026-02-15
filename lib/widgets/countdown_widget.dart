import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/prayer_model.dart';
import '../utils/theme.dart';

class CountdownWidget extends StatelessWidget {
  final PrayerTimeModel? nextPrayer;
  final Duration? timeUntilNext;

  const CountdownWidget({
    super.key,
    this.nextPrayer,
    this.timeUntilNext,
  });

  @override
  Widget build(BuildContext context) {
    if (nextPrayer == null || timeUntilNext == null) {
      return _buildNoNextPrayer();
    }

    final hours = timeUntilNext!.inHours;
    final minutes = timeUntilNext!.inMinutes.remainder(60);
    final seconds = timeUntilNext!.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A2940),
            Color(0xFF0F1E30),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Başlık
          Text(
            '${nextPrayer!.name} Vaktine Kalan',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(nextPrayer!.time),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 16),

          // Geri sayım
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeUnit(hours.toString().padLeft(2, '0'), 'Saat'),
              _buildSeparator(),
              _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'Dakika'),
              _buildSeparator(),
              _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'Saniye'),
            ],
          ),

          // İftar / Sahur özel mesaj
          if (nextPrayer!.name.contains('İftar') ||
              nextPrayer!.name.contains('Mağrib'))
            _buildSpecialMessage('İftar vakti yaklaşıyor!', '🌙'),
          if (nextPrayer!.name.contains('İmsak') ||
              nextPrayer!.name.contains('Sahur'))
            _buildSpecialMessage('Sahura kalkmayı unutmayın!', '⭐'),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.15),
            ),
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Text(
          ':',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialMessage(String message, String emoji) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$emoji $message',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNoNextPrayer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text(
          'Bugünkü tüm vakitler geçti',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
