import 'package:flutter/foundation.dart';
import 'package:plantastic/models/home_banner_config.dart';
import 'package:plantastic/services/home_banner_service.dart';

/// Cached shop home hero configuration from Supabase [shop_home_banner].
class HomeBannerNotifier extends ChangeNotifier {
  ShopHomeBannerConfig _config = ShopHomeBannerConfig.fallback;

  ShopHomeBannerConfig get config => _config;

  Future<void> load() async {
    try {
      final loaded = await HomeBannerService.fetchCurrent();
      _config = loaded;
      notifyListeners();
    } catch (e, stack) {
      debugPrint('HomeBannerNotifier.load failed: $e\n$stack');
    }
  }

  /// Call after admin saves so shop picks up new banner without restart.
  Future<void> refresh() async => load();
}
