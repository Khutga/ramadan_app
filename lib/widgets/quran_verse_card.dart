import 'package:flutter/material.dart';

import '../models/quran_model.dart';
import '../utils/theme.dart';

class QuranVerseCard extends StatelessWidget {
  final QuranVerse? verse;
  final VoidCallback? onRefresh;

  const QuranVerseCard({
    super.key,
    this.verse,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (verse == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Günün Ayeti',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
                Text(
                  '${verse!.surahName} ${verse!.verseNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (onRefresh != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onRefresh,
                    child: const Icon(
                      Icons.refresh,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // İçerik
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Arapça
                Text(
                  verse!.arabicText,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.8,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),

                // Türkçe
                Text(
                  verse!.turkishTranslation,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
