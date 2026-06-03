import 'package:cricboss/src/config/app_config.dart';
import 'package:cricboss/src/services/local_storage_service.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();
  static final instance = AdsService._();

  static const testAppOpenAdUnit = 'ca-app-pub-3940256099942544/9257395921';
  static const testBannerAdUnit = 'ca-app-pub-3940256099942544/9214589741';

  AppOpenAd? _appOpenAd;

  Future<void> init() => MobileAds.instance.initialize();

  Future<void> showAppOpenAdOnce() async {
    if (_appOpenAd != null) {
      return;
    }
    final lastShown = LocalStorageService.instance.lastAppOpenAdAt;
    if (lastShown != null &&
        DateTime.now().difference(lastShown) < AppConfig.adOpenCooldown) {
      return;
    }
    await AppOpenAd.load(
      adUnitId: testAppOpenAdUnit,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) async {
          _appOpenAd = ad
            ..fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _appOpenAd = null;
              },
              onAdFailedToShowFullScreenContent: (ad, _) {
                ad.dispose();
                _appOpenAd = null;
              },
            )
            ..show();
          await LocalStorageService.instance.setLastAppOpenAdAt(DateTime.now());
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  Future<BannerAd> createAdaptiveBanner(BuildContext context) async {
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.sizeOf(context).width.truncate(),
    );
    final ad = BannerAd(
      size: size ?? AdSize.banner,
      adUnitId: testBannerAdUnit,
      listener: const BannerAdListener(),
      request: const AdRequest(),
    );
    await ad.load();
    return ad;
  }
}
