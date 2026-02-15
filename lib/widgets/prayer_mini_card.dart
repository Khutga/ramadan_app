import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/prayer_model.dart';
import '../utils/theme.dart';

class PrayerMiniCard extends StatelessWidget {
  final PrayerTimeModel prayer;
  final bool isNext;

  const PrayerMiniCard({
    super.key,
    required this.prayer,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(prayer.time);
    final isPassed = prayer.time.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceLight.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNext
                  ? AppColors.accent
                  : isPassed
                      ? AppColors.textSecondary.withOpacity(0.3)
                      : AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              prayer.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isNext ? FontWeight.w600 : FontWeight.normal,
                color: isPassed && !isNext
                    ? AppColors.textSecondary.withOpacity(0.5)
                    : AppColors.textPrimary,
              ),
            ),
          ),

          Text(
            prayer.nameArabic,
            style: TextStyle(
              fontSize: 12,
              color: isPassed && !isNext
                  ? AppColors.textSecondary.withOpacity(0.3)
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),

          Text(
            timeStr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
              color: isNext
                  ? AppColors.accent
                  : isPassed
                      ? AppColors.textSecondary.withOpacity(0.5)
                      : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
