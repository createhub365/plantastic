import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalog/catalog_async_guard.dart';
import '../config.dart';
import '../data/seed_products.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_notifier.dart';
import '../layout/plantastic_layout.dart';
import '../widgets/cart_strip_bar.dart';
import '../widgets/plantastic_app_bar.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/plantastic_loading.dart';
import '../widgets/plantastic_scroll_behavior.dart';
import '../widgets/product_shop_card.dart';
import '../theme/app_theme.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _categoryFilter = kCategoryFlowerSeed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      guardCatalogFuture(
        context.read<CatalogNotifier>().refresh(),
        'HomeScreen.refresh',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewPaddingBottom = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      appBar: PlantasticAppBar(
        actions: [
          Consumer<CartNotifier>(
            builder: (context, cart, _) {
              return IconButton(
                tooltip: 'Shopping cart',
                onPressed: () {
                  Navigator.of(context).pushNamed('/cart');
                },
                icon: Badge(
                  isLabelVisible: cart.itemCount > 0,
                  label: Text('${cart.itemCount}'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CatalogNotifier>(
        builder: (context, catalog, _) {
          final visibleProducts = catalog.shopProducts
              .where((p) => p.category == _categoryFilter)
              .toList(growable: false);

          return Consumer<CartNotifier>(
            builder: (context, cart, _) {
              final floatPadBottom = cart.itemCount > 0
                  ? 112.0 + viewPaddingBottom
                  : 36.0;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.scaffoldGradient,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              PlantasticLayout.gutter(context),
                              2,
                              PlantasticLayout.gutter(context),
                              0,
                            ),
                            child: _CatalogStatusBanner(catalog: catalog),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              PlantasticLayout.gutter(context),
                              8,
                              PlantasticLayout.gutter(context),
                              12,
                            ),
                            child: SegmentedButton<String>(
                              expandedInsets: EdgeInsets.zero,
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment<String>(
                                  value: kCategoryFlowerSeed,
                                  label: Text('Flower seed'),
                                  icon: Icon(
                                    Icons.local_florist_outlined,
                                    size: 20,
                                  ),
                                ),
                                ButtonSegment<String>(
                                  value: kCategoryPlantSeed,
                                  label: Text('Plant seed'),
                                  icon: Icon(Icons.spa_outlined, size: 20),
                                ),
                              ],
                              selected: {_categoryFilter},
                              onSelectionChanged: (selection) {
                                setState(() {
                                  _categoryFilter = selection.first;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: CustomScrollView(
                              physics: plantasticViewportPhysics,
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      PlantasticLayout.gutter(context),
                                      0,
                                      PlantasticLayout.gutter(context),
                                      12,
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      switchInCurve: Curves.easeOutCubic,
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                            opacity: animation,
                                            child: SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(0, 0.05),
                                                end: Offset.zero,
                                              ).animate(animation),
                                              child: child,
                                            ),
                                          ),
                                      child: Align(
                                        key: ValueKey(_categoryFilter),
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          _categoryFilter == kCategoryFlowerSeed
                                              ? 'Flower seeds — pollinator-friendly picks; '
                                                    'multiple kits per product.'
                                              : 'Plant seeds — grow lush greens home; '
                                                    'multiple kits per product.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.72),
                                                height: 1.45,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (visibleProducts.isEmpty)
                                  const SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Center(
                                      child: Text(
                                        'No products in this category yet.',
                                      ),
                                    ),
                                  )
                                else
                                  SliverPadding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: PlantasticLayout.gutter(
                                        context,
                                      ),
                                    ),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, rowIndex) {
                                          final spacing = PlantasticLayout
                                              .shopGridCrossSpacing;
                                          final rowGap = PlantasticLayout
                                              .shopGridMainSpacing;
                                          final start = rowIndex * 2;
                                          final rows =
                                              (visibleProducts.length + 1) ~/ 2;
                                          final lastRow = rowIndex >= rows - 1;

                                          Widget cardAt(int i) {
                                            if (i >= visibleProducts.length) {
                                              return const SizedBox.shrink();
                                            }
                                            final product = visibleProducts[i];
                                            return StaggerGridItem(
                                              index: i,
                                              child: ProductShopCard(
                                                product: product,
                                                heroTag:
                                                    AppTheme.heroProductCover(
                                                      product.id,
                                                    ),
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute<void>(
                                                      builder: (_) =>
                                                          ProductDetailScreen(
                                                            productId:
                                                                product.id,
                                                          ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          }

                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: lastRow ? 0 : rowGap,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(child: cardAt(start)),
                                                SizedBox(width: spacing),
                                                Expanded(
                                                  child: cardAt(start + 1),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        childCount:
                                            (visibleProducts.length + 1) ~/ 2,
                                      ),
                                    ),
                                  ),
                                SliverToBoxAdapter(
                                  child: SizedBox(height: floatPadBottom),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 16 + viewPaddingBottom,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, t, child) {
                          final curved = Curves.easeOutCubic.transform(t);
                          return Opacity(
                            opacity: curved,
                            child: Transform.translate(
                              offset: Offset(0, 28 * (1 - curved)),
                              child: child,
                            ),
                          );
                        },
                        child: CartStripBar(
                          margin: EdgeInsets.symmetric(
                            horizontal: PlantasticLayout.gutter(context),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CatalogStatusBanner extends StatelessWidget {
  const _CatalogStatusBanner({required this.catalog});

  final CatalogNotifier catalog;

  static String _offlineHint() {
    if (AppConfig.envLoadError != null) {
      return '.env could not load — showing sample catalogue only.';
    }
    if (AppConfig.supabaseUrlMissing) {
      return 'Add SUPABASE_URL to bundled .env for live shop data.';
    }
    if (AppConfig.anonKeyProblemHint == 'empty') {
      return 'SUPABASE_ANON_KEY is blank — paste the anon public key in .env.';
    }
    if (AppConfig.anonKeyLength <= 20) {
      return 'Add a valid SUPABASE_ANON_KEY in .env for live products.';
    }
    if (AppConfig.supabaseInitError != null) {
      return 'Could not initialize Supabase — offline sample catalogue.';
    }
    return 'Live backend unavailable — showing sample catalogue.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (AppConfig.supabaseReady && catalog.lastError == null) {
      return const SizedBox.shrink();
    }

    final offline = !AppConfig.supabaseReady;
    final icon = offline ? Icons.cloud_outlined : Icons.refresh_rounded;
    final accent = offline
        ? AppTheme.forestBright.withValues(alpha: 0.88)
        : cs.error.withValues(alpha: 0.88);

    final message = offline ? _offlineHint() : catalog.lastError!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.surfaceBorder.withValues(alpha: 0.65),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  offline ? message : 'Sync issue: $message',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.82),
                    height: 1.38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!offline)
                TextButton(
                  onPressed: catalog.loading
                      ? null
                      : () => guardCatalogFuture(
                          context.read<CatalogNotifier>().refresh(),
                          'HomeScreen.retry',
                        ),
                  child: catalog.loading
                      ? PlantasticLoading.inline
                      : const Text('Retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
