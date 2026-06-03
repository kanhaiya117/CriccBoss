import 'package:cricboss/src/config/app_config.dart';
import 'package:cricboss/src/services/local_storage_service.dart';
import 'package:flutter/widgets.dart';

class AdsService {
  AdsService._();
  static final instance = AdsService._();

  static const testAppOpenAdUnit = 'ca-app-pub-3940256099942544/9257395921';
  static const testBannerAdUnit = 'ca-app-pub-3940256099942544/9214589741';

  bool _initialized = false;

  Future<void> init() async {
    _initialized = true;
  }

  Future<void> showAppOpenAdOnce() async {
    if (!_initialized) return;
    final lastShown = LocalStorageService.instance.lastAppOpenAdAt;
    if (lastShown != null &&
        DateTime.now().difference(lastShown) < AppConfig.adOpenCooldown) {
      return;
    }
    await LocalStorageService.instance.setLastAppOpenAdAt(DateTime.now());
  }

  Widget adaptiveBanner(BuildContext context) => const SizedBox.shrink();
}
