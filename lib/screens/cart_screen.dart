import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalog/catalog_assets.dart';
import '../data/seed_products.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../layout/plantastic_layout.dart';
import '../layout/responsive.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_notifier.dart';
import '../widgets/plantastic_app_bar.dart';
import '../widgets/plantastic_loading.dart';
import '../widgets/plantastic_scroll_behavior.dart';
import '../widgets/decode_aware_product_image.dart';
import '../widgets/shop_navigation_rail.dart';
import 'address_screen.dart';

/// Returns a shopper-facing message when checkout must be blocked.
String? checkoutBlockReason(CartNotifier cart, CatalogNotifier catalog) {
  for (final line in cart.lines) {
    final row = catalog.byId(line.product.id);
    if (row == null) {
      return 'Some items are no longer in the catalogue — update your cart.';
    }
    if (!row.availableForPurchase) {
      return !row.visibleInShop
          ? '"${row.title}" is hidden from the shop'
          : '"${row.title}" is out of stock';
    }
  }
  return null;
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final desktop = Responsive.isDesktop(context);

    Widget wrapBody(Widget child) {
      if (!desktop) return child;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ShopNavigationRail(section: ShopNavSection.cart),
          Expanded(child: child),
        ],
      );
    }

    return Scaffold(
      appBar: const PlantasticAppBar(showBack: true),
      body: wrapBody(
        Consumer2<CartNotifier, CatalogNotifier>(
          builder: (context, cart, catalog, _) {
          if (cart.lines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.22),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Browse seeds'),
                  ),
                ],
              ),
            );
          }

          final g = PlantasticLayout.gutter(context);
          final blockReason = checkoutBlockReason(cart, catalog);
          final n = cart.lines.length;

          if (desktop) {
            return PlantasticLayout.constrainedBody(
              context,
              child: Padding(
                padding: EdgeInsets.fromLTRB(g, 16, g, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: ListView.separated(
                        physics: plantasticViewportPhysics,
                        itemCount: n,
                        separatorBuilder: (context, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final line = cart.lines[index];
                          return _CartLineTile(
                            line: line,
                            cart: cart,
                            liveProduct:
                                catalog.byId(line.product.id) ?? line.product,
                          );
                        },
                      ),
                    ),
                    SizedBox(width: Responsive.sectionGap(context)),
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        physics: plantasticViewportPhysics,
                        child: _CartCheckoutColumn(
                          cart: cart,
                          blockReason: blockReason,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return PlantasticLayout.constrainedBody(
            context,
            child: ListView.builder(
              physics: plantasticViewportPhysics,
              padding: EdgeInsets.fromLTRB(g, 16, g, 24),
              itemCount: n + 1,
              itemBuilder: (context, index) {
                if (index < n) {
                  final line = cart.lines[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CartLineTile(
                      line: line,
                      cart: cart,
                      liveProduct:
                          catalog.byId(line.product.id) ?? line.product,
                    ),
                  );
                }

                return _CartCheckoutColumn(
                  cart: cart,
                  blockReason: blockReason,
                );
              },
            ),
          );
        },
      ),
      ),
    );
  }
}

/// Checkout summary block (trust strip + totals + CTA).
class _CartCheckoutColumn extends StatelessWidget {
  const _CartCheckoutColumn({
    required this.cart,
    required this.blockReason,
  });

  final CartNotifier cart;
  final String? blockReason;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CartTrustStrip(),
        Divider(
          height: 36,
          color: Theme.of(
            context,
          ).colorScheme.outline.withValues(alpha: 0.25),
        ),
        Text(
          'Review & checkout',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Confirm kits and totals, then enter delivery details.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.38,
              ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 360;
            final totalLabel = Text(
              'Total due',
              style: Theme.of(context).textTheme.titleLarge,
            );
            final totalAmt = Text(
              '₹${cart.grandTotal}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  totalLabel,
                  const SizedBox(height: 10),
                  totalAmt,
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [totalLabel, totalAmt],
            );
          },
        ),
        const SizedBox(height: 18),
        if (blockReason != null) ...[
          Text(
            blockReason!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.orangeAccent.withValues(alpha: 0.92),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 14),
        ],
        FilledButton(
          onPressed: blockReason != null
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddressScreen(),
                    ),
                  );
                },
          child: const Text('Continue to address'),
        ),
      ],
    );
  }
}

/// Shop reassurance row (mirrors tutorial “trust” block; themed for Plantastic).
class _CartTrustStrip extends StatelessWidget {
  const _CartTrustStrip();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget row(IconData icon, String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 22,
              color: cs.primary.withValues(alpha: 0.88),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.78),
                      height: 1.38,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row(Icons.verified_outlined, 'Fresh seeds guarantee'),
            row(Icons.local_shipping_outlined, 'Fast delivery'),
          ],
        ),
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.line,
    required this.cart,
    required this.liveProduct,
  });

  final CartLine line;
  final CartNotifier cart;

  /// Fresh row from catalogue (stock / visibility) while keeping cart qty.
  final Product liveProduct;

  @override
  Widget build(BuildContext context) {
    final Product p = liveProduct;
    final restricted = !p.availableForPurchase;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _CartLineThumb(product: p),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${line.kitLabel} · ₹${line.unitPrice} each',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: restricted ? 4 : 8),
                  if (restricted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        !p.visibleInShop
                            ? 'Hidden — remove or wait for listing'
                            : 'Out of stock — cannot raise quantity',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.orangeAccent.withValues(alpha: .85),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          cart.setQuantity(
                            p,
                            line.kitLineId,
                            line.quantity - 1,
                          );
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${line.quantity}'),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: restricted
                            ? null
                            : () {
                                cart.setQuantity(
                                  p,
                                  line.kitLineId,
                                  line.quantity + 1,
                                );
                              },
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: restricted
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.26)
                              : null,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${line.lineTotal}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 72² thumbnail matching [ProductShopCard] hero (same as review/cart strip).
class _CartLineThumb extends StatelessWidget {
  const _CartLineThumb({required this.product});

  final Product product;

  static const double _side = 72;

  Widget _loadingThumb(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.95),
      child: const Center(child: PlantasticLoading.thumbnail),
    );
  }

  Widget _fallback(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.95),
      child: Center(
        child: Icon(
          product.category == kCategoryFlowerSeed
              ? Icons.local_florist_outlined
              : Icons.spa_outlined,
          size: 36,
          color: cs.primary.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  /// Matches [ProductShopCard] hero (not kit-specific carousel order).
  String? _primaryRef() => product.effectiveShopCoverPrimaryRef;

  @override
  Widget build(BuildContext context) {
    final ref = _primaryRef();
    if (ref == null || ref.isEmpty) {
      return SizedBox.square(dimension: _side, child: _fallback(context));
    }

    if (CatalogAssets.looksLikeUsableShopRemoteUrl(ref)) {
      return SizedBox(
        width: _side,
        height: _side,
        child: DecodeAwareProductImage(
          image: NetworkImage(ref),
          width: _side,
          height: _side,
          alignment: Alignment.center,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox.square(
              dimension: _side,
              child: _loadingThumb(context),
            );
          },
          errorBuilder: (context, error, stackTrace) => _fallback(context),
        ),
      );
    }

    return SizedBox(
      width: _side,
      height: _side,
      child: DecodeAwareProductImage(
        image: AssetImage(ref),
        width: _side,
        height: _side,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) {
          final nu = product.effectiveNetworkCoverUrl?.trim();
          if (nu != null &&
              nu.isNotEmpty &&
              CatalogAssets.looksLikeUsableShopRemoteUrl(nu)) {
            return DecodeAwareProductImage(
              image: NetworkImage(nu),
              width: _side,
              height: _side,
              alignment: Alignment.center,
              errorBuilder: (c, e, s) => _fallback(context),
            );
          }
          return _fallback(context);
        },
      ),
    );
  }
}
