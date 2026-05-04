import '../catalog/catalog_assets.dart';
import 'gallery_slide_meta.dart';
import 'kit_catalog_item.dart';
import 'product_kit_line.dart';

/// Shop row from Supabase `products` (or local seed).
///
/// Selling options live in [kits]; legacy starter/dual columns are synced on save.
class Product {
  Product({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required List<ProductKitLine> kits,
    List<String> galleryUrls = const [],
    List<GallerySlideMeta> gallerySlideMeta = const [],
    this.coverImageUrl = '',
    this.inStock = true,
    this.visibleInShop = true,
    List<String> highlightTagIds = const [],
  }) : kits = List<ProductKitLine>.from(kits),
       galleryUrls = _sanitizeUrls(galleryUrls),
       gallerySlideMeta = List<GallerySlideMeta>.from(gallerySlideMeta),
       highlightTagIds = List<String>.from(highlightTagIds);

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final List<ProductKitLine> kits;
  final List<String> galleryUrls;
  final List<GallerySlideMeta> gallerySlideMeta;
  final String coverImageUrl;
  final bool inStock;

  /// When false, excluded from shopper home grid; admin listing still shows it.
  final bool visibleInShop;

  /// Assigned [highlight_tags.id]s (subset of global highlight catalogue).
  final List<String> highlightTagIds;

  /// Shoppers may add/increase qty only when in stock and listed in shop.
  bool get availableForPurchase => inStock && visibleInShop;

  static List<String> _sanitizeUrls(Iterable<String> raw) =>
      raw.map((e) => e.trim()).where((s) => s.isNotEmpty).toList();

  static List<String> _urlsFromMap(
    Map<String, dynamic> map,
    String primaryKey,
    Iterable<String> fallbacks,
  ) {
    final prim = map[primaryKey];
    if (prim is List && prim.isNotEmpty) {
      return _sanitizeUrls(prim.map((e) => '$e'));
    }
    for (final k in fallbacks) {
      final v = map[k];
      if (v is List && v.isNotEmpty) {
        return _sanitizeUrls(v.map((e) => '$e'));
      }
    }
    return [];
  }

  /// First **bundled** path for grid/card when present (preferred over network).
  String? get effectiveBundledCoverPath {
    final c = coverImageUrl.trim();
    if (CatalogAssets.isBundledRef(c)) return CatalogAssets.assetPath(c);
    for (final u in galleryUrls) {
      if (CatalogAssets.isBundledRef(u)) return CatalogAssets.assetPath(u);
    }
    return null;
  }

  /// First **`https`** cover for shop grid when nothing bundled is chosen.
  String? get effectiveNetworkCoverUrl {
    final c = coverImageUrl.trim();
    if (CatalogAssets.looksLikeUsableShopRemoteUrl(c)) return c;
    for (final u in galleryUrls) {
      if (CatalogAssets.looksLikeUsableShopRemoteUrl(u)) return u;
    }
    return null;
  }

  /// Same primary image as the shop grid card: bundled path first, else first usable remote.
  String? get effectiveShopCoverPrimaryRef {
    final b = effectiveBundledCoverPath?.trim();
    if (b != null && b.isNotEmpty) return b;
    final n = effectiveNetworkCoverUrl?.trim();
    if (n != null && n.isNotEmpty) return n;
    return null;
  }

  /// Product detail carousel: opens on [effectiveShopCoverPrimaryRef], then [urlsForCarousel] without repeating it.
  List<String> urlsForDetailCarousel(String lineId) {
    final tail = urlsForCarousel(lineId);
    final cover = effectiveShopCoverPrimaryRef?.trim();
    if (cover == null || cover.isEmpty) return List<String>.from(tail);
    final out = <String>[cover];
    for (final raw in tail) {
      final t = raw.trim();
      if (t.isEmpty || t == cover) continue;
      out.add(t);
    }
    return out;
  }

  /// Kit subset or whole gallery — bundled paths plus remote URLs for shop carousel.
  List<String> urlsForCarousel(String lineId) {
    final kit = kitForLineMaybe(lineId);
    if (kit != null && kit.imageUrls.isNotEmpty) {
      return CatalogAssets.shopRenderableImageRefs(kit.imageUrls);
    }
    return CatalogAssets.shopRenderableImageRefs(galleryUrls);
  }

  int get lowestKitPriceInr {
    if (kits.isEmpty) return 0;
    var m = kits.first.priceInr;
    for (var i = 1; i < kits.length; i++) {
      final q = kits[i].priceInr;
      if (q < m) m = q;
    }
    return m;
  }

  int get highestKitPriceInr => kits.isEmpty
      ? 0
      : kits.map((k) => k.priceInr).reduce((a, b) => a > b ? a : b);

  ProductKitLine kitForLine(String lineId) {
    return kits.firstWhere((k) => k.lineId == lineId);
  }

  ProductKitLine? kitForLineMaybe(String lineId) {
    for (final k in kits) {
      if (k.lineId == lineId) return k;
    }
    return null;
  }

  int priceForKitLine(String lineId) => kitForLine(lineId).priceInr;

  List<KitInclusionEntry> inclusionEntriesForKit(
    String lineId,
    List<KitCatalogItem> catalog,
  ) => kitForLine(lineId).inclusionEntries(catalog);

  List<String> inclusionLinesForKit(
    String lineId,
    List<KitCatalogItem> catalog,
  ) => kitForLine(lineId).inclusionLines(catalog);

  factory Product.fromMap(Map<String, dynamic> map) {
    final idRaw = map['id'];
    final ks = kitsFromPayload(map);

    final gallery = _urlsFromMap(map, 'gallery_urls', {'image_urls'});
    final cover = (map['cover_image_url'] as String?)?.trim() ?? '';

    return Product(
      id: idRaw == null ? '' : '$idRaw',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      category: map['category'] as String? ?? '',
      kits: ks,
      galleryUrls: gallery,
      gallerySlideMeta: _gallerySlideMetaList(map['gallery_slide_meta']),
      coverImageUrl: cover,
      inStock: map['in_stock'] as bool? ?? true,
      visibleInShop: map['visible_in_shop'] as bool? ?? true,
      highlightTagIds: _uuidList(map['highlight_tag_ids']),
    );
  }

  static List<ProductKitLine> kitsFromPayload(Map<String, dynamic> map) {
    final raw = map['kits'];
    if (raw is List && raw.isNotEmpty) {
      final out = <ProductKitLine>[];
      for (final e in raw) {
        if (e is! Map) continue;
        final k = ProductKitLine.fromMap(Map<String, dynamic>.from(e));
        if (k.lineId.isEmpty) continue;
        out.add(k);
      }
      if (out.isNotEmpty) return out;
    }
    return kitsFromLegacyColumns(map);
  }

  /// Backfills from `*_catalog_ids` rows before `kits` existed.
  static List<ProductKitLine> kitsFromLegacyColumns(Map<String, dynamic> map) {
    final idRaw = map['id'];
    final pid = idRaw == null ? 'p' : '$idRaw';
    final ps = map['price_starter_inr'];
    final pd = map['price_deluxe_inr'];
    final priceS = ps is int ? ps : int.tryParse('$ps') ?? 499;
    final priceD = pd is int ? pd : int.tryParse('$pd') ?? 799;

    final starterIds = _uuidList(map['starter_catalog_ids']);
    final deluxeIds = _uuidList(map['deluxe_catalog_ids']);
    final itemsStarter = starterIds.isEmpty
        ? _stringList(map['items_starter'])
        : <String>[];
    final itemsDeluxe = deluxeIds.isEmpty
        ? _stringList(map['items_deluxe'])
        : <String>[];

    return [
      ProductKitLine(
        lineId: '${pid}_starter',
        label: 'Starter kit',
        catalogIds: starterIds,
        priceInr: priceS,
        snapshotLines: itemsStarter,
      ),
      ProductKitLine(
        lineId: '${pid}_deluxe',
        label: 'Deluxe kit',
        catalogIds: deluxeIds,
        priceInr: priceD,
        snapshotLines: itemsDeluxe,
      ),
    ];
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => '$e'.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  static List<GallerySlideMeta> _gallerySlideMetaList(dynamic raw) {
    if (raw is List) {
      final out = <GallerySlideMeta>[];
      for (final e in raw) {
        if (e is! Map) continue;
        out.add(GallerySlideMeta.fromMap(Map<String, dynamic>.from(e)));
      }
      return out;
    }
    return [];
  }

  static List<String> _uuidList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => '$e'.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  Map<String, dynamic> toInsertMap({
    bool includeId = false,
    required List<String> starterLabelSnapshot,
    required List<String> deluxeLabelSnapshot,
  }) {
    final k0 = kits.isNotEmpty ? kits.first : null;
    final k1 = kits.length > 1 ? kits[1] : k0;

    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'title': title.trim(),
      'subtitle': subtitle.trim(),
      'category': category,
      'gallery_urls': galleryUrls,
      'gallery_slide_meta': [for (final m in gallerySlideMeta) m.toJson()],
      'cover_image_url': coverImageUrl.trim(),
      'image_urls': galleryUrls,
      'kits': [for (final k in kits) k.toJson()],
      'price_starter_inr': k0?.priceInr ?? 0,
      'price_deluxe_inr': k1?.priceInr ?? 0,
      'starter_catalog_ids': k0?.catalogIds ?? [],
      'deluxe_catalog_ids': k1?.catalogIds ?? [],
      'items_starter': starterLabelSnapshot,
      'items_deluxe': deluxeLabelSnapshot,
      'in_stock': inStock,
      'visible_in_shop': visibleInShop,
      'highlight_tag_ids': highlightTagIds,
    };
  }

  Product copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? category,
    List<ProductKitLine>? kits,
    List<String>? galleryUrls,
    List<GallerySlideMeta>? gallerySlideMeta,
    String? coverImageUrl,
    bool? inStock,
    bool? visibleInShop,
    List<String>? highlightTagIds,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      kits: kits ?? this.kits,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      gallerySlideMeta: gallerySlideMeta ?? this.gallerySlideMeta,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      inStock: inStock ?? this.inStock,
      visibleInShop: visibleInShop ?? this.visibleInShop,
      highlightTagIds: highlightTagIds ?? this.highlightTagIds,
    );
  }
}
