import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'home_screen.dart';
import 'prayer_times_screen.dart';
import 'quran_screen.dart';
import 'settings_screen.dart';
import '../services/ad_service.dart'; // <-- Yeni oluşturduğumuz dosyayı import edin

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PrayerTimesScreen(),
    QuranScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body kısmını Column yaptık
      body: Column(
        children: [
          // Sayfaların içeriği tüm alanı kaplasın
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          
          // --- REKLAM ALANI ---
          // Alt barın hemen üzerinde sabit duracak reklam
          const MyBannerAdWidget(),
        ],
      ),
      
      bottomNavigationBar: Container(
        // ... (Buradaki kodlarınız aynı kalacak)
        decoration: BoxDecoration(
          color: AppColors.primaryMid,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          // SafeArea'nın bottom: false yapılması gerekebilir reklamla çakışırsa
          // ama genelde sorun olmaz.
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Ana Sayfa'),
                _buildNavItem(1, Icons.access_time_rounded, 'Vakitler'),
                _buildNavItem(2, Icons.menu_book_rounded, 'Kur\'an'),
                _buildNavItem(3, Icons.settings_rounded, 'Ayarlar'),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
