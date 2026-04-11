import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../models/ad_service.dart';
import '../models/app_state.dart';

/// Shows a banner ad at the bottom of the screen.
/// Automatically hides when the user has purchased any premium feature.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final ad = AdService.createBanner(
      onFailed: (ad, error) {
        ad.dispose();
        if (mounted) setState(() => _loaded = false);
      },
    );
    ad.load().then((_) {
      if (mounted) setState(() { _ad = ad; _loaded = true; });
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // Hide ads once any premium feature is purchased
    if (state.iapUnlocked || state.iapConfigsUnlocked) return const SizedBox.shrink();
    if (!_loaded || _ad == null) return const SizedBox.shrink();

    return SafeArea(
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
