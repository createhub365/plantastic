import '../models/kit_catalog_item.dart';

/// Must match seeded rows in migration `plantastic_kit_catalog_items`.
abstract final class KitCatalogIds {
  static const seedPacket = '11111111-1111-4111-a111-000000000101';
  static const soilMix = '11111111-1111-4111-a111-000000000102';
  static const compost = '11111111-1111-4111-a111-000000000103';
  static const coconutCoir = '11111111-1111-4111-a111-000000000104';
  static const towel = '11111111-1111-4111-a111-000000000201';
  static const gloves = '11111111-1111-4111-a111-000000000202';
  static const scoop = '11111111-1111-4111-a111-000000000203';

  /// Default Starter checklist (shown when nothing selected offline).
  static const List<String> defaultStarterIds = [
    seedPacket,
    soilMix,
    compost,
    coconutCoir,
  ];

  /// Default Deluxe = starter bits + deluxe-only tools.
  static const List<String> defaultDeluxeIds = [
    seedPacket,
    soilMix,
    compost,
    coconutCoir,
    towel,
    gloves,
    scoop,
  ];

  /// Seed labels for fallback when Supabase is off (same order).
  static const Map<String, String> defaultLabelsById = {
    seedPacket: 'Selected seed packet',
    soilMix: 'Garden soil mix',
    compost: 'Organic compost',
    coconutCoir: 'Coconut coir',
    towel: 'Hand towel',
    gloves: 'Gardening gloves',
    scoop: 'Soil scoop',
  };

  /// Offline / fetch-fail fallback; same order as DB seed.
  static List<KitCatalogItem> seededItemsInOrder() => [
    KitCatalogItem(
      id: seedPacket,
      label: defaultLabelsById[seedPacket]!,
      sortOrder: 10,
    ),
    KitCatalogItem(
      id: soilMix,
      label: defaultLabelsById[soilMix]!,
      sortOrder: 20,
    ),
    KitCatalogItem(
      id: compost,
      label: defaultLabelsById[compost]!,
      sortOrder: 30,
    ),
    KitCatalogItem(
      id: coconutCoir,
      label: defaultLabelsById[coconutCoir]!,
      sortOrder: 40,
    ),
    KitCatalogItem(id: towel, label: defaultLabelsById[towel]!, sortOrder: 50),
    KitCatalogItem(
      id: gloves,
      label: defaultLabelsById[gloves]!,
      sortOrder: 60,
    ),
    KitCatalogItem(id: scoop, label: defaultLabelsById[scoop]!, sortOrder: 70),
  ];
}
