import 'package:cricboss/src/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdaptiveBanner extends ConsumerStatefulWidget {
  const AdaptiveBanner({super.key});

  @override
  ConsumerState<AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends ConsumerState<AdaptiveBanner> {
  BannerAd? _ad;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    if (_ad != null) return;
    final ad = await ref.read(adsServiceProvider).createAdaptiveBanner(context);
    if (mounted) setState(() => _ad = ad);
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
