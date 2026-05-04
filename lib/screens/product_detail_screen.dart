import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalog/catalog_async_guard.dart';
import '../data/seed_products.dart';
import '../layout/plantastic_layout.dart';
import '../models/product.dart';
import '../models/highlight_tag.dart';
import '../models/product_kit_line.dart';
import '../providers/catalog_notifier.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../theme/highlight_detail_theme.dart';
import '../theme/highlight_icons.dart';
import '../theme/kit_inclusion_icons.dart';
import '../widgets/cart_strip_bar.dart';
import '../widgets/plantastic_app_bar.dart';
import '../widgets/plantastic_loading.dart';
import '../widgets/plantastic_scroll_behavior.dart';
import '../widgets/product_image_carousel.dart';

/// Snapshot for [ProductDetailScreen.draftPreview] (admin editor).
class ProductPreviewData {
  const ProductPreviewData({
    required this.product,
    this.carouselMemory = const {},
  });

  final Product product;

  /// Indices align with whatever URL list the detail screen passes to [ProductImageCarousel]
  /// (`urlsForDetailCarousel` in shop mode, or [Product.urlsForCarousel] when preview memory indices apply).
  final Map<int, Uint8List> carouselMemory;
}

class ProductDetailScreen extends StatefulWidget {
  /// Shop catalog — loads [productId] via [CatalogNotifier].
  const ProductDetailScreen({super.key, required this.productId})
    : previewDataBuilder = null,
      previewRevision = null;

  /// Admin product editor — full detail UX with swipe carousel; rebuilds live.
  const ProductDetailScreen.draftPreview({
    super.key,
    required this.previewDataBuilder,
    required this.previewRevision,
  }) : productId = '';
  final String productId;
  final ProductPreviewData Function()? previewDataBuilder;
  final ValueNotifier<int>? previewRevision;

  bool get _isDraftPreview =>
      previewDataBuilder != null && previewRevision != null;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedKitLineId;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      guardCatalogFuture(
        context.read<CatalogNotifier>().bootstrap(),
        'ProductDetail.bootstrap',
      );
      _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget._isDraftPreview &&
        widget.productId.isNotEmpty &&
        oldWidget.productId != widget.productId) {
      _selectedKitLineId = null;
      _entrance
        ..reset()
        ..forward();
    }
  }

  String _effectiveLineId(Product product) {
    final sel = _selectedKitLineId;
    if (sel != null && product.kitForLineMaybe(sel) != null) return sel;
    return product.kits.first.lineId;
  }

  @override
  Widget build(BuildContext context) {
    if (widget._isDraftPreview) {
      context.watch<CatalogNotifier>();
      return ValueListenableBuilder<int>(
        valueListenable: widget.previewRevision!,
        builder: (context, tick, _) {
          final catalog = context.watch<CatalogNotifier>();
          final data = widget.previewDataBuilder!();
          return _buildShoppingBody(
            context,
            catalog,
            data.product,
            draftPreview: true,
            carouselMemory: data.carouselMemory.isEmpty
                ? null
                : data.carouselMemory,
          );
        },
      );
    }

    final catalog = context.watch<CatalogNotifier>();
    final product = catalog.byId(widget.productId);

    if (catalog.loading && product == null) {
      return Scaffold(
        appBar: const PlantasticAppBar(showBack: true),
        body: Center(child: PlantasticLoading.detailHero),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: const PlantasticAppBar(showBack: true),
        body: const Center(child: Text('Product not found.')),
      );
    }

    if (!product.visibleInShop) {
      return Scaffold(
        appBar: const PlantasticAppBar(showBack: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 56,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Not available',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'This product is hidden from the shop.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildShoppingBody(
      context,
      catalog,
      product,
      draftPreview: false,
      carouselMemory: null,
    );
  }

  Widget _buildShoppingBody(
    BuildContext context,
    CatalogNotifier catalog,
    Product product, {
    required bool draftPreview,
    Map<int, Uint8List>? carouselMemory,
  }) {
    final kits = product.kits;
    if (kits.isEmpty) {
      return Scaffold(
        appBar: const PlantasticAppBar(showBack: true),
        body: const Center(child: Text('This product has no kits yet.')),
      );
    }

    final lineId = _effectiveLineId(product);
    final accent = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    final carouselUrls = carouselMemory == null
        ? product.urlsForDetailCarousel(lineId)
        : product.urlsForCarousel(lineId);
    final carouselBlock = ProductImageCarousel(
      urls: carouselUrls,
      side: PlantasticLayout.detailHeroSquareSide(context),
      autoInterval: const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(18),
      previewMemoryAtIndex: carouselMemory,
      categoryIconFallback: product.category == kCategoryFlowerSeed
          ? Icons.local_florist_outlined
          : Icons.spa_outlined,
    );

    return Scaffold(
      appBar: PlantasticAppBar(
        showBack: true,
        actions: draftPreview
            ? null
            : [
                IconButton(
                  tooltip: 'Cart',
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => Navigator.of(context).pushNamed('/cart'),
                ),
              ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                physics: plantasticViewportPhysics,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  PlantasticLayout.constrainedBody(
                    context,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        PlantasticLayout.gutter(context),
                        8,
                        PlantasticLayout.gutter(context),
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (draftPreview) ...[
                            Material(
                              color: AppTheme.goldAccent.withValues(
                                alpha: 0.16,
                              ),
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.swipe_rounded,
                                      size: 22,
                                      color: AppTheme.forestBright,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Live draft preview — swipe the gallery. '
                                        'Updates as you edit; cart is off.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.forest,
                                              fontWeight: FontWeight.w600,
                                              height: 1.35,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (!draftPreview)
                            Hero(
                              tag: AppTheme.heroProductCover(product.id),
                              child: Material(
                                color: Colors.transparent,
                                elevation: 10,
                                shadowColor: Colors.black.withValues(
                                  alpha: 0.22,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                clipBehavior: Clip.antiAlias,
                                child: carouselBlock,
                              ),
                            )
                          else
                            Material(
                              color: Colors.transparent,
                              elevation: 10,
                              shadowColor: Colors.black.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(18),
                              clipBehavior: Clip.antiAlias,
                              child: carouselBlock,
                            ),
                          const SizedBox(height: 18),
                          _DetailStagger(
                            animation: _entrance,
                            index: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailCategoryPill(category: product.category),
                                const SizedBox(height: 12),
                                Text(
                                  product.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        height: 1.12,
                                        letterSpacing: -0.35,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  product.subtitle,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.72,
                                        ),
                                        height: 1.52,
                                      ),
                                ),
                                if (!product.inStock) ...[
                                  const SizedBox(height: 16),
                                  _StockNoteBanner(colorScheme: cs),
                                ],
                                Builder(
                                  builder: (ctx) {
                                    final hl = catalog.highlightsForProduct(
                                      product,
                                    );
                                    if (hl.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 16),
                                        Text(
                                          'Highlights',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: accent,
                                                letterSpacing: 0.06,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: hl.map((tag) {
                                            final deco =
                                                highlightDetailDecoration(
                                                  tag.iconKey,
                                                );
                                            return DecoratedBox(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: deco.colorTop
                                                        .withValues(
                                                          alpha: 0.35,
                                                        ),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                type: MaterialType.transparency,
                                                child: InkWell(
                                                  onTap: () =>
                                                      _showHighlightDetailFloating(
                                                        ctx,
                                                        tag,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  child: Ink(
                                                    decoration: BoxDecoration(
                                                      gradient: deco.gradient(),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 7,
                                                          ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            highlightIcon(
                                                              tag.iconKey,
                                                            ),
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            tag.pillText,
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .labelLarge
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color: Colors
                                                                      .white,
                                                                  shadows: const [
                                                                    Shadow(
                                                                      color: Color(
                                                                        0x59000000,
                                                                      ),
                                                                      blurRadius:
                                                                          6,
                                                                      offset:
                                                                          Offset(
                                                                            0,
                                                                            1,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          _DetailStagger(
                            animation: _entrance,
                            index: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionHeading(
                                  text: 'Choose kit',
                                  accent: accent,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: kits.map((kit) {
                                    final selected = lineId == kit.lineId;
                                    return _KitPickTile(
                                      kit: kit,
                                      selected: selected,
                                      accent: accent,
                                      cs: cs,
                                      onTap: () => setState(
                                        () => _selectedKitLineId = kit.lineId,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          _DetailStagger(
                            animation: _entrance,
                            index: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionHeading(
                                  text: "What's inside",
                                  accent: accent,
                                ),
                                const SizedBox(height: 10),
                                _InclusionList(
                                  kitLineId: lineId,
                                  entries: product.inclusionEntriesForKit(
                                    lineId,
                                    catalog.kitCatalog,
                                  ),
                                  accent: accent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              maintainBottomViewPadding: true,
              child: _BottomBarEntrance(
                animation: _entrance,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: PlantasticLayout.contentMaxWidth(context),
                    ),
                    child: draftPreview
                        ? _draftPreviewBottomChrome(
                            context,
                            product,
                            lineId,
                            cs,
                            accent,
                          )
                        : Consumer<CartNotifier>(
                            builder: (context, cart, _) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (cart.itemCount > 0)
                                    CartStripBar(
                                      margin: EdgeInsets.fromLTRB(
                                        PlantasticLayout.gutter(context),
                                        0,
                                        PlantasticLayout.gutter(context),
                                        14,
                                      ),
                                    ),
                                  Material(
                                    color: cs.surface,
                                    elevation: 8,
                                    shadowColor: Colors.black.withValues(
                                      alpha: 0.12,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        PlantasticLayout.gutter(context),
                                        14,
                                        PlantasticLayout.gutter(context),
                                        14,
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 260,
                                        ),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        transitionBuilder: (child, anim) =>
                                            FadeTransition(
                                              opacity: anim,
                                              child: SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(0, 0.06),
                                                  end: Offset.zero,
                                                ).animate(anim),
                                                child: child,
                                              ),
                                            ),
                                        child: Builder(
                                          key: ValueKey<String>(
                                            '$lineId-${cart.findLine(product, lineId)?.quantity ?? 0}',
                                          ),
                                          builder: (context) {
                                            final qty =
                                                cart
                                                    .findLine(product, lineId)
                                                    ?.quantity ??
                                                0;
                                            final canBuy = product.inStock;
                                            final unit = product
                                                .priceForKitLine(lineId);
                                            final lineTotal = unit * qty;

                                            return Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        product
                                                            .kitForLine(lineId)
                                                            .label,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: cs
                                                                  .onSurfaceVariant,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      if (qty < 1)
                                                        Text(
                                                          '₹$unit',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .headlineSmall
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color: accent,
                                                                letterSpacing:
                                                                    -0.3,
                                                              ),
                                                        )
                                                      else
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              '₹$lineTotal',
                                                              style: Theme.of(context)
                                                                  .textTheme
                                                                  .headlineSmall
                                                                  ?.copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800,
                                                                    color:
                                                                        accent,
                                                                    letterSpacing:
                                                                        -0.3,
                                                                  ),
                                                            ),
                                                            Text(
                                                              '₹$unit each × $qty',
                                                              style: Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                    color: cs
                                                                        .onSurfaceVariant,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                if (qty < 1)
                                                  FilledButton(
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor: canBuy
                                                          ? accent
                                                          : null,
                                                      foregroundColor: Colors
                                                          .white
                                                          .withValues(
                                                            alpha: canBuy
                                                                ? 1.0
                                                                : 0.5,
                                                          ),
                                                      elevation: canBuy ? 2 : 0,
                                                      shadowColor: accent
                                                          .withValues(
                                                            alpha: 0.35,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 26,
                                                            vertical: 13,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed: canBuy
                                                        ? () {
                                                            cart.addOrIncrement(
                                                              product,
                                                              lineId,
                                                            );
                                                          }
                                                        : null,
                                                    child: Text(
                                                      canBuy
                                                          ? 'Add to cart'
                                                          : 'Sold out',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: 0.35,
                                                        color: canBuy
                                                            ? Colors.white
                                                            : null,
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  FoodQtyStepper(
                                                    quantity: qty,
                                                    incrementEnabled: canBuy,
                                                    onDecrement: () {
                                                      cart.setQuantity(
                                                        product,
                                                        lineId,
                                                        qty - 1,
                                                      );
                                                    },
                                                    onIncrement: () {
                                                      cart.setQuantity(
                                                        product,
                                                        lineId,
                                                        qty + 1,
                                                      );
                                                    },
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _draftPreviewBottomChrome(
    BuildContext context,
    Product product,
    String lineId,
    ColorScheme cs,
    Color accent,
  ) {
    final unit = product.priceForKitLine(lineId);
    final canBuy = product.inStock;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: cs.surface,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              PlantasticLayout.gutter(context),
              14,
              PlantasticLayout.gutter(context),
              14,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.kitForLine(lineId).label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹$unit',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: accent,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        canBuy
                            ? 'Cart is off in draft preview — save the product to shop it.'
                            : 'Shown as out of stock (as in editor).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailStagger extends StatelessWidget {
  const _DetailStagger({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.11).clamp(0.0, 0.72);
    final end = (start + 0.38).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final v = animation.value;
        final t = v <= start
            ? 0.0
            : v >= end
            ? 1.0
            : Curves.easeOutCubic.transform((v - start) / (end - start));

        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

class _BottomBarEntrance extends StatelessWidget {
  const _BottomBarEntrance({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        const start = 0.5;
        const end = 0.94;
        final v = animation.value;
        final t = v <= start
            ? 0.0
            : v >= end
            ? 1.0
            : Curves.easeOutCubic.transform((v - start) / (end - start));

        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 32 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

class _DetailCategoryPill extends StatelessWidget {
  const _DetailCategoryPill({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final flower = category == kCategoryFlowerSeed;
    final gradient = flower
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF5C8A), Color(0xFFFF8FA8), Color(0xFFFFB89C)],
            stops: [0.0, 0.45, 1.0],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.forestBright, AppTheme.leafDim, AppTheme.leaf],
            stops: const [0.0, 0.55, 1.0],
          );
    final icon = flower ? Icons.local_florist_rounded : Icons.eco_rounded;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: gradient,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: flower ? 0.12 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 7),
            Text(
              category,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accent, accent.withValues(alpha: 0.45)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.15,
          ),
        ),
      ],
    );
  }
}

class _StockNoteBanner extends StatelessWidget {
  const _StockNoteBanner({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.42),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 22,
              color: Colors.orange.shade300,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Currently out of stock. You can read the details below; '
                'purchase is paused until restocked.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.78),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitPickTile extends StatelessWidget {
  const _KitPickTile({
    required this.kit,
    required this.selected,
    required this.accent,
    required this.cs,
    required this.onTap,
  });

  final ProductKitLine kit;
  final bool selected;
  final Color accent;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.95),
                    accent.withValues(alpha: 0.78),
                  ],
                )
              : null,
          color: selected ? null : cs.surface.withValues(alpha: 0.92),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : cs.outline.withValues(alpha: 0.45),
            width: 1.1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                    spreadRadius: -2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 20,
              color: selected ? Colors.white : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              '${kit.label} — ',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : cs.onSurface,
              ),
            ),
            Text(
              '₹${kit.priceInr}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: selected ? Colors.white : accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InclusionList extends StatefulWidget {
  const _InclusionList({
    required this.kitLineId,
    required this.entries,
    required this.accent,
  });

  final String kitLineId;
  final List<KitInclusionEntry> entries;
  final Color accent;

  @override
  State<_InclusionList> createState() => _InclusionListState();
}

class _InclusionListState extends State<_InclusionList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  int get _count => widget.entries.length;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _durationFor(_count));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _InclusionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kitLineId != widget.kitLineId ||
        oldWidget.entries.length != widget.entries.length) {
      _ctrl.duration = _durationFor(_count);
      _ctrl.forward(from: 0);
    }
  }

  Duration _durationFor(int n) {
    if (n <= 0) return const Duration(milliseconds: 120);
    // Total time scales with rows; each row gets ~equal slice sequentially.
    return Duration(milliseconds: 220 + n * 115);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return Text(
        'No kit contents listed yet.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }

    final n = widget.entries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < n; i++)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final start = i / n;
              final end = (i + 1) / n;
              final t = Interval(
                start,
                end,
                curve: Curves.easeOutCubic,
              ).transform(_ctrl.value);
              final entry = widget.entries[i];

              return Transform.translate(
                offset: Offset(-18 * (1 - t), 0),
                child: Opacity(
                  opacity: t,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i == n - 1 ? 0 : 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          kitInclusionIcon(entry),
                          size: 22,
                          color: widget.accent.withValues(alpha: 0.94),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.label,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(height: 1.38),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

Future<void> _showHighlightDetailFloating(
  BuildContext context,
  HighlightTag tag,
) {
  final deco = highlightDetailDecoration(tag.iconKey);
  final bodyCopy = tag.body.trim();
  const emptyHint =
      'No extra details yet — add detail text for this highlight in Admin → Highlights.';

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    builder: (ctx) {
      final textTheme = Theme.of(ctx).textTheme;
      final mq = MediaQuery.of(ctx);
      final maxCardHeight = (mq.size.height - mq.padding.vertical - 32).clamp(
        180.0,
        mq.size.height * 0.92,
      );

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: maxCardHeight,
            ),
            child: SingleChildScrollView(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: deco.colorTop.withValues(alpha: 0.42),
                        blurRadius: 28,
                        spreadRadius: -4,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: deco.gradient(),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: ColoredBox(
                            color: Colors.white.withValues(alpha: 0.97),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: deco.gradient(),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: deco.colorBottom
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Icon(
                                            highlightIcon(tag.iconKey),
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          tag.title,
                                          style: textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            height: 1.15,
                                            color: deco.colorTop,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    bodyCopy.isEmpty ? emptyHint : bodyCopy,
                                    style: textTheme.bodyLarge?.copyWith(
                                      height: 1.52,
                                      color: const Color(0xFF37474F),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: Text(
                                        'Got it',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: deco.colorTop,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
