import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _initialized = false;

  // ── Test IDs (replace with real IDs before release) ───────────────────────
  // Real IDs come from AdMob console: admob.google.com
  static String get bannerAdUnitId {
    if (Platform.isIOS) {
      // TODO: replace with real iOS banner unit ID from AdMob
      return 'ca-app-pub-3940256099942544/2934735716'; // test
    }
    // TODO: replace with real Android banner unit ID from AdMob
    return 'ca-app-pub-3940256099942544/6300978111'; // test
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  static BannerAd createBanner({required void Function(Ad, LoadAdError) onFailed}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: onFailed,
      ),
    );
  }
}
