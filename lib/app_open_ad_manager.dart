import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'ad_helper.dart';

class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isAdLoaded = false;

  void loadAd() {
    AppOpenAd.load(
      adUnitId: AdHelper.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpenAd loaded successfully: ${ad.responseInfo}');
          _appOpenAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load full response: $error');
          debugPrint('AppOpenAd Load Error Message: ${error.message}');
          debugPrint('AppOpenAd Load Error Code: ${error.code}');
          debugPrint('AppOpenAd Load Error Domain: ${error.domain}');
          debugPrint('AppOpenAd Load Error ResponseInfo: ${error.responseInfo}');
        },
      ),
    );
  }

  void showAdIfAvailable(VoidCallback onAdClosed) {
    if (!_isAdLoaded || _appOpenAd == null) {
      debugPrint('AppOpenAd not available yet for show');
      onAdClosed();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AppOpenAd dismissed');
        ad.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AppOpenAd failed to show: $error');
        ad.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;
        onAdClosed();
      },
    );

    _appOpenAd!.show();
  }
}
