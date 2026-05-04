import 'kit_catalog_item.dart';
import '../data/kit_catalog_ids.dart';

/// Resolved row for shopper "What's inside" (stable [catalogId] when known).
class KitInclusionEntry {
  const KitInclusionEntry({this.catalogId = '', required this.label});

  /// Empty for legacy [ProductKitLine.snapshotLines] only.
  final String catalogId;

  final String label;
}

/// One selling option on a product: label, ₹ price, catalogue item ids.
class ProductKitLine {
  const ProductKitLine({
    required this.lineId,
    required this.label,
    required this.catalogIds,
    required this.priceInr,
    this.presetId,
    this.snapshotLines = const [],
    this.imageUrls = const [],
  });

  /// Stable cart / order identity (persist in DB).
  final String lineId;

  /// Shown on product detail chips and checkout.
  final String label;

  /// Optional preset this row came from (admin).
  final String? presetId;

  /// Selected `kit_catalog_items.id`s in catalogue sort order resolved at save.
  final List<String> catalogIds;

  /// ₹ price for this kit.
  final int priceInr;

  /// Fallback display lines when [catalogIds] empty (legacy).
  final List<String> snapshotLines;

  /// Subset carousel images for this kit; empty ⇒ use whole product gallery order.
  final List<String> imageUrls;

  factory ProductKitLine.fromMap(Map<String, dynamic> map) {
    final lid = map['line_id'];
    final priceRaw = map['price_inr'];
    final price = priceRaw is int ? priceRaw : int.tryParse('$priceRaw') ?? 0;
    final pidRaw = map['preset_id'];

    List<String> ids(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => '$e'.trim()).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    List<String> snaps(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => '$e'.trim()).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    final imgs = ids(map['image_urls']);

    return ProductKitLine(
      lineId: lid == null ? '' : '$lid',
      label: (map['label'] as String? ?? 'Kit').trim(),
      presetId: pidRaw == null || '$pidRaw'.trim().isEmpty ? null : '$pidRaw',
      catalogIds: ids(map['catalog_ids']),
      priceInr: price,
      snapshotLines: snaps(map['snapshot_lines']),
      imageUrls: imgs,
    );
  }

  Map<String, dynamic> toJson() => {
    'line_id': lineId,
    'label': label.trim(),
    if (presetId != null && presetId!.trim().isNotEmpty) 'preset_id': presetId,
    'catalog_ids': catalogIds,
    'price_inr': priceInr,
    if (snapshotLines.isNotEmpty) 'snapshot_lines': snapshotLines,
    if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
  };

  List<KitInclusionEntry> inclusionEntries(List<KitCatalogItem> catalog) {
    final idsToUse = catalogIds.isNotEmpty ? catalogIds : <String>[];

    if (idsToUse.isEmpty) {
      if (snapshotLines.isNotEmpty) {
        return [
          for (final raw in snapshotLines)
            if (raw.trim().isNotEmpty) KitInclusionEntry(label: raw.trim()),
        ];
      }
      return [];
    }

    final orderIdx = <String, int>{
      for (var i = 0; i < catalog.length; i++)
        catalog[i].id: catalog[i].sortOrder,
    };
    final byId = Map<String, String>.from(KitCatalogIds.defaultLabelsById);
    for (final c in catalog) {
      final t = c.label.trim();
      if (t.isNotEmpty) byId[c.id] = t;
    }

    final ranked = [...idsToUse];
    ranked.sort(
      (a, b) => (orderIdx[a] ?? 99999).compareTo(orderIdx[b] ?? 99999),
    );

    return [
      for (final id in ranked)
        if ((byId[id] ?? '').trim().isNotEmpty)
          KitInclusionEntry(catalogId: id, label: byId[id]!.trim()),
    ];
  }

  List<String> inclusionLines(List<KitCatalogItem> catalog) => [
    for (final e in inclusionEntries(catalog)) e.label,
  ];

  ProductKitLine copyWith({
    String? lineId,
    String? label,
    String? presetId,
    List<String>? catalogIds,
    int? priceInr,
    List<String>? snapshotLines,
    List<String>? imageUrls,
    bool clearPreset = false,
  }) {
    return ProductKitLine(
      lineId: lineId ?? this.lineId,
      label: label ?? this.label,
      presetId: clearPreset ? null : (presetId ?? this.presetId),
      catalogIds: catalogIds ?? this.catalogIds,
      priceInr: priceInr ?? this.priceInr,
      snapshotLines: snapshotLines ?? this.snapshotLines,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}
