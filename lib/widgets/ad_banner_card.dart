import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/app_colors.dart';
import '../services/mobile_ads_service.dart';

class AdBannerCard extends StatefulWidget {
  const AdBannerCard({super.key});

  @override
  State<AdBannerCard> createState() => _AdBannerCardState();
}

class _AdBannerCardState extends State<AdBannerCard> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (MobileAdsService.instance.supportsAds) {
      _bannerAd = MobileAdsService.instance.createBannerAd(
        onLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onFailed: (_) {
          if (mounted) setState(() => _loaded = false);
        },
      );
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerAd = _bannerAd;
    if (!_loaded || bannerAd == null) return const SizedBox.shrink();

    return Container(
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      decoration: BoxDecoration(
        color: AppColors.iconCream.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.deepEmerald.withValues(alpha: .10)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepEmerald.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: bannerAd),
    );
  }
}
