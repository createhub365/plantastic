import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../data/kit_catalog_ids.dart';
import '../data/seed_highlight_tags.dart';
import '../data/seed_products.dart';
import '../models/highlight_tag.dart';
import '../models/kit_catalog_item.dart';
import '../models/kit_preset.dart';
import '../models/product.dart';
import '../services/highlight_tag_service.dart';
import '../services/kit_catalog_service.dart';
import '../services/kit_preset_service.dart';

class CatalogNotifier extends ChangeNotifier {
  CatalogNotifier() {
    _products = List<Product>.from(seedProducts);
    _kitCatalog = KitCatalogIds.seededItemsInOrder();
    _highlightCatalog = SeedHighlightTags.catalog();
    _kitPresets = KitPreset.seededDefaults();
  }

  List<Product> _products = [];
  List<KitCatalogItem> _kitCatalog = [];
  List<HighlightTag> _highlightCatalog = [];
  List<KitPreset> _kitPresets = [];
  bool loading = false;
  String? lastError;

  List<Product> get products => List.unmodifiable(_products);

  /// Listed on the shopper home grid (admin may hide products).
  List<Product> get shopProducts =>
      List.unmodifiable(_products.where((p) => p.visibleInShop));

  List<KitCatalogItem> get kitCatalog => List.unmodifiable(_kitCatalog);

  List<HighlightTag> get highlightCatalog =>
      List.unmodifiable(_highlightCatalog);

  List<KitPreset> get kitPresets => List.unmodifiable(_kitPresets);

  Product? byId(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Highlight tags assigned to [p], in stored id order (omits stale ids).
  List<HighlightTag> highlightsForProduct(Product p) {
    if (p.highlightTagIds.isEmpty) return [];
    final byId = {for (final h in _highlightCatalog) h.id: h};
    return [
      for (final id in p.highlightTagIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  /// Ids in [catalog] sort order (only those in [selected]); use when saving.
  List<String> orderedHighlightIds(
    Set<String> selected,
    List<HighlightTag> catalog,
  ) => [
    for (final h in catalog)
      if (selected.contains(h.id)) h.id,
  ];

  /// Ids in [catalog] sort order (only those in [selected]).
  List<String> orderedSelectedIds(
    Set<String> selected,
    List<KitCatalogItem> catalog,
  ) {
    return [
      for (final c in catalog)
        if (selected.contains(c.id)) c.id,
    ];
  }

  /// Full reload; [silent] skips showing the global loading flag.
  /// When [warmShopCovers] is false, skips decoding hero thumbnails (faster UI after admin saves).
  Future<void> refresh({
    bool silent = false,
    bool warmShopCovers = true,
  }) async {
    lastError = null;
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    try {
      if (!AppConfig.supabaseReady) {
        _products = List<Product>.from(seedProducts);
        _kitCatalog = KitCatalogIds.seededItemsInOrder();
        _highlightCatalog = SeedHighlightTags.catalog();
        _kitPresets = KitPreset.seededDefaults();
        if (warmShopCovers) await _warmShopHeroCovers();
      } else {
        final data = await Supabase.instance.client
            .from('products')
            .select()
            .order('created_at', ascending: false);

        final rows = data as List<dynamic>;
        final list = <Product>[];
        for (final row in rows) {
          list.add(Product.fromMap(Map<String, dynamic>.from(row as Map)));
        }
        _products = list.isNotEmpty ? list : List<Product>.from(seedProducts);

        await _loadKitCatalogRemote();
        await _loadHighlightCatalogRemote();
        await _loadKitPresetsRemote();

        if (warmShopCovers) await _warmShopHeroCovers();
      }
    } catch (e) {
      lastError = '$e';
      _products = List<Product>.from(seedProducts);
      _kitCatalog = KitCatalogIds.seededItemsInOrder();
      _highlightCatalog = SeedHighlightTags.catalog();
      _kitPresets = KitPreset.seededDefaults();
    } finally {
      if (!silent) loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadKitCatalogRemote() async {
    try {
      final remote = await KitCatalogService.fetchAllOrdered();
      _kitCatalog = remote.isNotEmpty
          ? remote
          : KitCatalogIds.seededItemsInOrder();
    } catch (_) {
      _kitCatalog = KitCatalogIds.seededItemsInOrder();
    }
  }

  Future<void> _loadHighlightCatalogRemote() async {
    try {
      final remote = await HighlightTagService.fetchAllOrdered();
      _highlightCatalog = remote.isNotEmpty
          ? remote
          : SeedHighlightTags.catalog();
    } catch (_) {
      _highlightCatalog = SeedHighlightTags.catalog();
    }
  }

  Future<void> _loadKitPresetsRemote() async {
    try {
      final remote = await KitPresetService.fetchAllOrdered();
      _kitPresets = remote.isNotEmpty ? remote : KitPreset.seededDefaults();
    } catch (_) {
      _kitPresets = KitPreset.seededDefaults();
    }
  }

  Future<void> reloadKitPresets() async {
    if (!AppConfig.supabaseReady) {
      _kitPresets = KitPreset.seededDefaults();
      notifyListeners();
      return;
    }
    try {
      final remote = await KitPresetService.fetchAllOrdered();
      _kitPresets = remote.isNotEmpty ? remote : KitPreset.seededDefaults();
    } catch (_) {
      _kitPresets = KitPreset.seededDefaults();
    }
    notifyListeners();
  }

  Future<void> reloadKitCatalog() async {
    if (!AppConfig.supabaseReady) {
      _kitCatalog = KitCatalogIds.seededItemsInOrder();
      notifyListeners();
      return;
    }
    try {
      final remote = await KitCatalogService.fetchAllOrdered();
      _kitCatalog = remote.isNotEmpty
          ? remote
          : KitCatalogIds.seededItemsInOrder();
    } catch (_) {
      _kitCatalog = KitCatalogIds.seededItemsInOrder();
    }
    notifyListeners();
  }

  Future<void> reloadHighlightCatalog() async {
    if (!AppConfig.supabaseReady) {
      _highlightCatalog = SeedHighlightTags.catalog();
      notifyListeners();
      return;
    }
    await _loadHighlightCatalogRemote();
    notifyListeners();
  }

  Future<void> _waitForProviderFrame(ImageProvider provider) async {
    final cfg = ImageConfiguration.empty.copyWith(bundle: rootBundle);
    final stream = provider.resolve(cfg);
    final done = Completer<void>();
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo _, bool sync) {
        if (!done.isCompleted) done.complete();
        stream.removeListener(listener);
      },
      onError: (Object _, StackTrace? stackTrace) {
        if (!done.isCompleted) done.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    try {
      await done.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      stream.removeListener(listener);
    }
  }

  /// Decode first-frame shop covers so grids do not flicker once loading hides.
  Future<void> _warmShopHeroCovers() async {
    final urls = <String>{};
    final assets = <String>{};
    for (final p in _products.where((x) => x.visibleInShop)) {
      final nu = p.effectiveNetworkCoverUrl?.trim();
      if (nu != null &&
          (nu.startsWith('https://') || nu.startsWith('http://'))) {
        urls.add(nu);
      }
      final ap = p.effectiveBundledCoverPath;
      if (ap != null && ap.isNotEmpty) assets.add(ap);
    }
    const netCap = 15;
    const assetCap = 12;
    final tasks = <Future<void>>[
      ...urls.take(netCap).map((u) => _waitForProviderFrame(NetworkImage(u))),
      ...assets.take(assetCap).map((a) => _waitForProviderFrame(AssetImage(a))),
    ];
    if (tasks.isEmpty) return;
    await Future.wait(tasks, eagerError: false);
  }

  /// Passive sync — no global loading overlay (e.g. product detail drift fix).
  Future<void> bootstrap() => refresh(silent: true);
}
