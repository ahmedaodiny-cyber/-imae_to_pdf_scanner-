import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class UnityAdsService {
  static const String _gameId = 'YOUR_UNITY_GAME_ID';
  static const String _interstitialPlacementId = 'Interstitial_Android';

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await UnityAds.init(
      gameId: _gameId,
      onComplete: () {
        _isInitialized = true;
        debugPrint('Unity Ads Initialized');
      },
      onFailed: (error, message) {
        debugPrint('Unity Ads Init Failed: \$error - \$message');
      },
    );
  }

  static Future<void> showInterstitialAd({
    VoidCallback? onComplete,
    VoidCallback? onFailed,
  }) async {
    if (!_isInitialized) await initialize();

    await UnityAds.load(
      placementId: _interstitialPlacementId,
      onComplete: (placementId) async {
        await UnityAds.showVideoAd(
          placementId: _interstitialPlacementId,
          onComplete: (placementId) => onComplete?.call(),
          onFailed: (placementId, error, message) => onFailed?.call(),
          onStart: (placementId) {},
          onClick: (placementId) {},
          onSkipped: (placementId) => onComplete?.call(),
        );
      },
      onFailed: (placementId, error, message) => onFailed?.call(),
    );
  }
}
