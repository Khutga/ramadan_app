import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_app/models/prayer_model.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/quran_verse_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 100,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(context, provider),
                    ),

                    // Sıradaki vakte gerisayım
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CountdownWidget(
                          nextPrayer: provider.nextPrayer,
                          timeUntilNext: provider.timeUntilNext,
                        ),
                      ),
                    ),

                    // İftar & Sahur gerisayım - HER ZAMAN göster
                    SliverToBoxAdapter(
                      child: _buildIftarSahurCountdown(provider),
                    ),

                    // İftar / Sahur Saat Kartları
                    SliverToBoxAdapter(
                      child: _buildIftarSahurCards(provider),
                    ),

                    // Vakit Çizelgesi
                    SliverToBoxAdapter(
                      child: _buildPrayerTimesPreview(provider),
                    ),

                    // Ayet Kartı
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: QuranVerseCard(
                          verse: provider.dailyVerse,
                          onRefresh: provider.refreshVerse,
                        ),
                      ),
                    ),

                    // Ramazan İlerlemesi / Geri Sayımı
                    SliverToBoxAdapter(
                      child: _buildRamadanSection(provider),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    final now = DateTime.now();
    final locationText = [provider.cityName, provider.countryName]
        .where((text) => text != null && text.isNotEmpty)
        .join(', ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(now).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hayırlı Ramazanlar',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  provider.madhhab == MadhhabType.shia
                      ? 'Caferi'
                      : provider.sunniMethod.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    provider.locationLoading
                        ? 'Konum bulunuyor...'
                        : locationText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_month_rounded,
                    color: AppColors.accent, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    provider.ramadanStartDateStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
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
  // İFTAR & SAHUR GERİ SAYIMI - HER ZAMAN GÖSTER
  // =========================================================
  Widget _buildIftarSahurCountdown(AppProvider provider) {
    final timeUntilIftar = provider.timeUntilIftar;
    final timeUntilSahur = provider.timeUntilSahur;

    // Her ikisi de geçmişse gösterme
    if (timeUntilIftar == null && timeUntilSahur == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // İftar gerisayımı
          if (timeUntilIftar != null)
            Expanded(
              child: _buildCompactCountdown(
                title: 'İftara Kalan',
                duration: timeUntilIftar,
                icon: Icons.wb_twilight_rounded,
                gradientColors: [
                  const Color(0xFFFF512F).withOpacity(0.2),
                  const Color(0xFFDD2476).withOpacity(0.15),
                ],
                borderColor: const Color(0xFFFF512F).withOpacity(0.3),
                timeColor: const Color(0xFFFF8A65),
              ),
            ),

          if (timeUntilIftar != null && timeUntilSahur != null)
            const SizedBox(width: 12),

          // Sahur gerisayımı
          if (timeUntilSahur != null)
            Expanded(
              child: _buildCompactCountdown(
                title: 'Sahura Kalan',
                duration: timeUntilSahur,
                icon: Icons.nights_stay_rounded,
                gradientColors: [
                  const Color(0xFF141E30).withOpacity(0.4),
                  const Color(0xFF243B55).withOpacity(0.3),
                ],
                borderColor: const Color(0xFF5C6BC0).withOpacity(0.3),
                timeColor: const Color(0xFF90CAF9),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactCountdown({
    required String title,
    required Duration duration,
    required IconData icon,
    required List<Color> gradientColors,
    required Color borderColor,
    required Color timeColor,
  }) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final timeStr =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: timeColor,
                fontFeatures: const [FontFeature.tabularFigures()],
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
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe',
      'Cuma', 'Cumartesi', 'Pazar'
    ];
    return '${date.day} ${months[date.month]} ${date.year}, ${days[date.weekday - 1]}';
  }

  // =========================================================
  // İFTAR / SAHUR SAAT KARTLARI
  // =========================================================
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTimeCard(
              title: 'Sahur',
              time: sahurTime,
              icon: Icons.nights_stay_rounded,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF141E30), Color(0xFF243B55)],
              ),
              shadowColor: const Color(0xFF141E30).withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTimeCard(
              title: 'İftar',
              time: iftarTime,
              icon: Icons.wb_twilight_rounded,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
              ),
              shadowColor: const Color(0xFFFF512F).withOpacity(0.5),
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
    required Gradient gradient,
    required Color shadowColor,
  }) {
    final timeStr = time != null
        ? "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}"
        : "--:--";

    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -15,
            child: Transform.rotate(
              angle: 0.2,
              child: Icon(icon, size: 90,
                  color: Colors.white.withOpacity(0.15)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  timeStr,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black26,
                          offset: Offset(0, 2),
                        )
                      ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // VAKİT ÇİZELGESİ
  // =========================================================
  Widget _buildPrayerTimesPreview(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vakit Çizelgesi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}",
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: provider.prayerTimes.map((prayer) {
                final isNext = provider.nextPrayer?.name == prayer.name;
                return _buildModernPrayerRow(prayer, isNext);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPrayerRow(PrayerTimeModel prayer, bool isNext) {
    IconData getIcon(String name) {
      if (name.contains("İmsak")) return Icons.wb_twilight;
      if (name.contains("Güneş")) return Icons.wb_sunny_rounded;
      if (name.contains("Öğle")) return Icons.wb_sunny_outlined;
      if (name.contains("İkindi")) return Icons.wb_cloudy_outlined;
      if (name.contains("Akşam")) return Icons.nights_stay_rounded;
      if (name.contains("Yatsı")) return Icons.bedtime_rounded;
      return Icons.access_time;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
          horizontal: isNext ? 0 : 12, vertical: isNext ? 4 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isNext ? const Color(0xFF283593) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: const Color(0xFF283593).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isNext
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              getIcon(prayer.name),
              size: 20,
              color: isNext
                  ? Colors.white
                  : AppColors.textPrimary.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              prayer.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                color: isNext ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${prayer.time.hour.toString().padLeft(2, '0')}:${prayer.time.minute.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isNext ? Colors.white : AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              if (isNext)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    "SIRADAKİ",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RAMAZAN BÖLÜMÜ
  // =========================================================
  Widget _buildRamadanSection(AppProvider provider) {
    if (provider.isRamadan && provider.ramadanDay > 0) {
      return _buildRamadanProgress(provider);
    } else {
      return _buildRamadanCountdown(provider);
    }
  }

  Widget _buildRamadanCountdown(AppProvider provider) {
    final countdown = provider.timeUntilRamadan;
    if (countdown == null) return const SizedBox.shrink();

    final days = countdown.inDays;
    final hours = countdown.inHours.remainder(24);
    final minutes = countdown.inMinutes.remainder(60);

    final title = provider.isBeforeRamadan
        ? 'Ramazan\'a Kalan'
        : 'Gelecek Ramazan\'a Kalan';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2940), Color(0xFF0F1E30)],
          ),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: AppColors.accent.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              '🌙 $title',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCountdownUnit(days.toString(), 'Gün'),
                _buildCountdownSep(),
                _buildCountdownUnit(
                    hours.toString().padLeft(2, '0'), 'Saat'),
                _buildCountdownSep(),
                _buildCountdownUnit(
                    minutes.toString().padLeft(2, '0'), 'Dakika'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Başlangıç: ${provider.ramadanStartDateStr}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownUnit(String value, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.accent.withOpacity(0.15)),
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownSep() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text(
          ':',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildRamadanProgress(AppProvider provider) {
    final progress = provider.ramadanDay / provider.totalRamadanDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${provider.ramadanDay}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                        height: 1,
                      ),
                    ),
                    const Text(
                      "Gün",
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ramazan İlerlemesi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '%${(progress * 100).toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              AppColors.textPrimary.withOpacity(0.5),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: 12,
                            width: constraints.maxWidth * progress,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.accent,
                                    Color(0xFFFFA000)
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent
                                        .withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}