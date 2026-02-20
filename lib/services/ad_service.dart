import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Test ID'leri. Canlıya çıkarken AdMob panelinden aldığınız ID'leri buraya yazın.
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2884994237286567/21345524730'; // Android Test Banner ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2884994237286567/21345524730'; // iOS Test Banner ID
    }
    throw UnsupportedError("Unsupported platform");
  }
}

// Tekrar Kullanılabilir Banner Widget'ı
class MyBannerAdWidget extends StatefulWidget {
  const MyBannerAdWidget({super.key});

  @override
  State<MyBannerAdWidget> createState() => _MyBannerAdWidgetState();
}

class _MyBannerAdWidgetState extends State<MyBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner, // Standart Banner Boyutu
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          print('Reklam yüklenemedi: ${err.message}');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // Reklam yüklenene kadar boşluk veya yükseklik kaplamayan bir widget
    return const SizedBox.shrink();
  }
}