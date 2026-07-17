import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// ---------------------------------------------------------------------------
/// AD SERVICE — production-hardened
///
/// ⚠️  THESE ARE GOOGLE'S OFFICIAL *TEST* AD UNIT IDs.
/// Replace all three + the APPLICATION_ID in AndroidManifest.xml before release.
/// NEVER click your own live ads — instant permanent AdMob ban.
///
/// Hardening included:
///   • UMP consent flow (REQUIRED for personalized = high-RPM ads in US/EU)
///   • Retry with exponential backoff when an ad fails to load
///   • Frequency cap on interstitials (never two within 60s — protects UX
///     and your AdMob account health, which drives eCPM in Tier-1 countries)
///   • Every path guarded with if/else so the app NEVER crashes from ads
/// ---------------------------------------------------------------------------
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const String bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // TEST — replace
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // TEST — replace
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // TEST — replace

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  int _interstitialRetries = 0;
  int _rewardedRetries = 0;
  static const _maxRetries = 3;
  DateTime? _lastInterstitialShown;
  bool _adsInitialized = false;

  /// Call once at startup. Runs Google's UMP consent flow first — this is
  /// what unlocks personalized ads (≈2-4× higher eCPM in the USA) legally.
  Future<void> initWithConsent() async {
    if (_adsInitialized) return; // guard: never double-init

    final completer = Completer<void>();

    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            ConsentForm.loadAndShowConsentFormIfRequired((formError) {
              if (formError != null) {
                debugPrint('Consent form error: ${formError.message}');
              }
              if (!completer.isCompleted) completer.complete();
            });
          } else {
            if (!completer.isCompleted) completer.complete();
          }
        } catch (e) {
          debugPrint('Consent flow exception: $e');
          if (!completer.isCompleted) completer.complete();
        }
      },
      (FormError error) {
        debugPrint('Consent info update failed: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );

    // Whatever happens with consent, don't hang the app for more than 8s.
    await completer.future.timeout(const Duration(seconds: 8), onTimeout: () {});

    try {
      await MobileAds.instance.initialize();
      _adsInitialized = true;
    } catch (e) {
      debugPrint('MobileAds init failed: $e'); // app still works without ads
    }

    if (_adsInitialized) {
      loadInterstitial();
      loadRewarded();
    }
  }

  // ── INTERSTITIAL ──────────────────────────────────────────────────────────

  void loadInterstitial() {
    if (!_adsInitialized) return;
    if (_interstitial != null) return; // already loaded — don't waste requests

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialRetries = 0;
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          if (_interstitialRetries < _maxRetries) {
            _interstitialRetries++;
            // Exponential backoff: 2s, 4s, 8s
            Future.delayed(Duration(seconds: 2 << (_interstitialRetries - 1)),
                loadInterstitial);
          } else {
            debugPrint('Interstitial gave up: ${error.message}');
          }
        },
      ),
    );
  }

  /// Shows the interstitial IF loaded AND not shown in the last 60 seconds.
  /// Always calls [onDone] exactly once — the app never gets stuck.
  void showInterstitial({required void Function() onDone}) {
    final ad = _interstitial;
    final now = DateTime.now();

    final tooSoon = _lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!).inSeconds < 60;

    if (ad == null || tooSoon) {
      onDone();
      if (ad == null) loadInterstitial();
      return;
    }

    _lastInterstitialShown = now;
    var doneCalled = false;
    void finish() {
      if (!doneCalled) {
        doneCalled = true;
        onDone();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
        finish();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
        finish();
      },
    );

    try {
      ad.show();
    } catch (e) {
      debugPrint('Interstitial show threw: $e');
      _interstitial = null;
      finish();
    }
  }

  // ── REWARDED ──────────────────────────────────────────────────────────────

  void loadRewarded() {
    if (!_adsInitialized) return;
    if (_rewarded != null) return;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedRetries = 0;
        },
        onAdFailedToLoad: (error) {
          _rewarded = null;
          if (_rewardedRetries < _maxRetries) {
            _rewardedRetries++;
            Future.delayed(
                Duration(seconds: 2 << (_rewardedRetries - 1)), loadRewarded);
          }
        },
      ),
    );
  }

  bool get rewardedReady => _rewarded != null;

  void showRewarded({required void Function() onReward}) {
    final ad = _rewarded;
    if (ad == null) {
      loadRewarded();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewarded = null;
        loadRewarded();
      },
    );
    try {
      ad.show(onUserEarnedReward: (_, __) => onReward());
    } catch (e) {
      debugPrint('Rewarded show threw: $e');
      _rewarded = null;
      loadRewarded();
    }
  }

  // ── BANNER ────────────────────────────────────────────────────────────────

  /// Adaptive banners earn more than fixed banners in Tier-1 markets.
  Future<BannerAd?> createAdaptiveBanner({
    required int widthPx,
    required void Function() onLoaded,
  }) async {
    if (!_adsInitialized) return null;
    AdSize? size;
    try {
      size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          widthPx);
    } catch (_) {
      size = AdSize.banner;
    }
    if (size == null) size = AdSize.banner;

    final banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    try {
      await banner.load();
      return banner;
    } catch (e) {
      debugPrint('Banner load threw: $e');
      return null;
    }
  }
}
