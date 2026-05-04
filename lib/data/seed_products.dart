import '../data/kit_catalog_ids.dart';
import '../data/kit_preset_ids.dart';
import '../models/product_kit_line.dart';
import '../models/product.dart';

/// Catalogue category labels (match [Product.category]).
const String kCategoryFlowerSeed = 'Flower seed';
const String kCategoryPlantSeed = 'Plant seed';

List<ProductKitLine> _kitsForSeed(String pid) => [
  ProductKitLine(
    lineId: '${pid}__stk',
    label: 'Starter kit',
    presetId: KitPresetIds.starterBundle,
    catalogIds: List<String>.from(KitCatalogIds.defaultStarterIds),
    priceInr: 499,
  ),
  ProductKitLine(
    lineId: '${pid}__dlx',
    label: 'Deluxe kit',
    presetId: KitPresetIds.deluxeBundle,
    catalogIds: List<String>.from(KitCatalogIds.defaultDeluxeIds),
    priceInr: 799,
  ),
];

/// Seed catalogue when Supabase is off or empty.
final List<Product> seedProducts = [
  Product(
    id: 'marigold-orange',
    title: 'Marigold Orange',
    subtitle: 'Bright, hardy annual — perfect for balconies and borders.',
    category: kCategoryFlowerSeed,
    kits: _kitsForSeed('marigold-orange'),
  ),
  Product(
    id: 'sunfolk-sunflower',
    title: 'Sunflower Dwarf',
    subtitle: 'Cheerful sunflowers — great for pots and pollinators.',
    category: kCategoryFlowerSeed,
    kits: _kitsForSeed('sunfolk-sunflower'),
  ),
  Product(
    id: 'petunia-mix',
    title: 'Petunia Cascade Mix',
    subtitle: 'Trailing blooms in mixed colours for hanging baskets.',
    category: kCategoryFlowerSeed,
    kits: _kitsForSeed('petunia-mix'),
  ),
  Product(
    id: 'zinnia-bright',
    title: 'Zinnia Cutting Mix',
    subtitle: 'Long stems for bouquets; loves full sun.',
    category: kCategoryFlowerSeed,
    kits: _kitsForSeed('zinnia-bright'),
  ),
  Product(
    id: 'tomato-cherry-balcony',
    title: 'Cherry Tomato Patio',
    subtitle: 'Compact cherry tomatoes for small spaces.',
    category: kCategoryPlantSeed,
    kits: _kitsForSeed('tomato-cherry-balcony'),
  ),
  Product(
    id: 'basil-genovese',
    title: 'Basil Genovese',
    subtitle: 'Aromatic herb seed for pesto and kitchen gardens.',
    category: kCategoryPlantSeed,
    kits: _kitsForSeed('basil-genovese'),
  ),
];
