import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MobileAdsService {
  MobileAdsService._();

  static final MobileAdsService instance = MobileAdsService._();

  static const String _androidBannerUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );
  static const String _androidRewardedUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );

  bool _initialized = false;
  RewardedAd? _rewardedAd;
  bool _rewardedLoading = false;

  bool get supportsAds => !kIsWeb && Platform.isAndroid;

  Future<void> initialize() async {
    if (_initialized || !supportsAds) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    unawaited(preloadRewardedAd());
  }

  BannerAd createBannerAd({
    required void Function(Ad ad)? onLoaded,
    required void Function(LoadAdError error)? onFailed,
  }) {
    final banner = BannerAd(
      adUnitId: _androidBannerUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed?.call(error);
        },
      ),
    );
    banner.load();
    return banner;
  }

  Future<void> preloadRewardedAd() async {
    if (!supportsAds || _rewardedAd != null || _rewardedLoading) return;
    _rewardedLoading = true;
    await RewardedAd.load(
      adUnitId: _androidRewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoading = false;
        },
        onAdFailedToLoad: (_) {
          _rewardedLoading = false;
        },
      ),
    );
  }

  Future<bool> showRewardedAiUnlockAd() async {
    await initialize();
    await preloadRewardedAd();
    final ad = _rewardedAd;
    if (ad == null) return false;

    final completer = Completer<bool>();
    var rewarded = false;
    _rewardedAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(rewarded);
        unawaited(preloadRewardedAd());
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
        unawaited(preloadRewardedAd());
      },
    );

    await ad.show(onUserEarnedReward: (ad, reward) => rewarded = true);

    return completer.future;
  }
}
