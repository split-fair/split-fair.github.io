import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _initialized = false;
  static RewardedAd? _rewardedAd;
  static bool _isLoadingRewarded = false;

  static String get bannerAdUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-1238536439375279/3739766193';
    }
    return 'ca-app-pub-1238536439375279/1085894726';
  }

  static String get rewardedAdUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-1238536439375279/5764115141';
    }
    return 'ca-app-pub-1238536439375279/2611351508';
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    loadRewardedAd();
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

  /// Pre-load a rewarded ad so it's ready when the user taps "Watch ad".
  static void loadRewardedAd() {
    if (_isLoadingRewarded || _rewardedAd != null) return;
    _isLoadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoadingRewarded = false;
        },
      ),
    );
  }

  /// Whether a rewarded ad is ready to show.
  static bool get isRewardedAdReady => _rewardedAd != null;

  /// Show the rewarded ad. Calls [onRewarded] when the user earns the reward.
  /// Calls [onFailed] if the ad can't be shown.
  static void showRewardedAd({
    required void Function() onRewarded,
    required void Function() onFailed,
  }) {
    final ad = _rewardedAd;
    if (ad == null) {
      onFailed();
      loadRewardedAd();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Pre-load next one
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onFailed();
        loadRewardedAd();
      },
    );

    _rewardedAd = null; // Clear reference before showing
    ad.show(onUserEarnedReward: (_, __) => onRewarded());
  }
}
