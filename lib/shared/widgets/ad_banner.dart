import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:securepass_pro/services/privacy_service.dart';

/// Adaptive banner ad shown at the bottom of the home screen.
///
/// Uses the real AdMob banner unit for securepass-pro.
///
/// Ads are only loaded when the user has explicitly enabled analytics
/// data sharing in Privacy settings (default is off, matching the app's
/// privacy-first defaults). Disabling analytics/offline mode in Privacy
/// settings stops ad requests entirely.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  // AdMob banner unit for securepass-pro (com.securepass.securepass_pro).
  static const String adUnitId = 'ca-app-pub-7692188087567714/5514308795';

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _maybeLoadBanner();
  }

  Future<void> _maybeLoadBanner() async {
    await PrivacyService.instance.initialize();
    if (!PrivacyService.instance.isAdsAllowed()) {
      // Privacy-first: no explicit opt-in for analytics/ads, show no banner.
      return;
    }
    await _loadBanner();
  }

  Future<void> _loadBanner() async {
    try {
      await MobileAds.instance.initialize();

      final adapter = BannerAd(
        adUnitId: AdBanner.adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _banner = ad as BannerAd;
              _loaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (mounted) {
              setState(() => _loaded = false);
            }
          },
          onAdImpression: (_) {},
          onAdClicked: (_) {},
        ),
      );

      await adapter.load();
    } catch (_) {
      // Ads are optional; never let ad failures break the app.
    }
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _banner == null) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      child: Container(
        alignment: Alignment.topCenter,
        child: AdWidget(ad: _banner!),
      ),
    );
  }
}
