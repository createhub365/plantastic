import 'package:flutter/foundation.dart';
import 'package:plantastic/config.dart';
import 'package:plantastic/models/home_banner_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads/writes singleton home hero row [shop_home_banner].
class HomeBannerService {
  HomeBannerService._();

  static Future<ShopHomeBannerConfig> fetchCurrent() async {
    if (!AppConfig.supabaseReady) return ShopHomeBannerConfig.fallback;
    try {
      final row = await Supabase.instance.client
          .from('shop_home_banner')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (row == null) return ShopHomeBannerConfig.fallback;
      return ShopHomeBannerConfig.fromRow(Map<String, dynamic>.from(row));
    } catch (e, stack) {
      final missingRelation =
          e.toString().contains('PGRST205') ||
          e.toString().contains('Could not find the table');
      if (missingRelation) {
        if (kDebugMode) {
          debugPrint(
            'HomeBannerService: table shop_home_banner not found — run '
            'plantastic/supabase/migrations/20260504220000_shop_home_banner.sql on Supabase.',
          );
        }
        return ShopHomeBannerConfig.fallback;
      }
      debugPrint('HomeBannerService.fetchCurrent: $e\n$stack');
      return ShopHomeBannerConfig.fallback;
    }
  }

  static Future<void> upsert(ShopHomeBannerConfig config) async {
    await Supabase.instance.client.from('shop_home_banner').upsert(config.toUpsertRow(), onConflict: 'id');
  }

  /// Apply gradient mode (clears stored media URL).
  static Future<void> resetToGradient({String titleOverlay = 'Grow your own garden 🌱'}) async {
    await upsert(
      ShopHomeBannerConfig(
        mediaKind: HomeBannerMediaKind.gradient,
        mediaUrl: null,
        titleOverlay: titleOverlay.trim().isEmpty ? ShopHomeBannerConfig.fallback.titleOverlay : titleOverlay.trim(),
        slides: const [],
      ).normalizedDimensions(),
    );
  }
}
