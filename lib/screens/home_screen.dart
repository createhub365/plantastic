import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../catalog/catalog_async_guard.dart';
import '../config.dart';
import '../data/seed_products.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_notifier.dart';
import '../layout/plantastic_layout.dart';
import '../layout/responsive.dart';
import '../navigation/plantastic_navigation.dart';
import '../widgets/cart_strip_bar.dart';
import '../widgets/cart_toolbar_icon_button.dart';
import '../widgets/plantastic_app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/plantastic_loading.dart';
import '../widgets/plantastic_scroll_behavior.dart';
import '../widgets/product_shop_card.dart';
import '../widgets/shop_navigation_rail.dart';
import '../widgets/plant_search_delegate.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Highlight id for “Customer favourites” / “Favourite picks” (see [SeedHighlightTags]).
const String _kHighlightFavouritePicks =
    '00000000-0000-4000-8000-00000000000b';

enum _HomeBrowseKind {
  flower,
  plant,
  starterKits,
  bestSellers,
}

/// Prefer tiles with live photo URLs so branded/logo placeholders don’t lead the grid.
List<Product> _preferLikelyPhotoFirst(List<Product> products) {
  if (products.length <= 1) return products;
  int score(Product p) {
    final net = (p.effectiveNetworkCoverUrl ?? '').trim().isNotEmpty;
    var s = net ? 4 : 0;
    if (p.effectiveBundledCoverPath != null) s += 1;
    final path = '${p.effectiveBundledCoverPath ?? ''}${p.coverImageUrl}'.toLowerCase();
    if (path.contains('logo')) s -= 3;
    final t = p.title.toLowerCase();
    if (t.contains('plantastic') && t.length < 24) s -= 2;
    return s;
  }

  final copy = List<Product>.from(products)
    ..sort((a, b) => score(b).compareTo(score(a)));
  return copy;
}

List<Product> _visibleForBrowse(
  Iterable<Product> shop,
  _HomeBrowseKind kind,
) {
  switch (kind) {
    case _HomeBrowseKind.flower:
      return _preferLikelyPhotoFirst(
        shop.where((p) => p.category == kCategoryFlowerSeed).toList(),
      );
    case _HomeBrowseKind.plant:
      return _preferLikelyPhotoFirst(
        shop.where((p) => p.category == kCategoryPlantSeed).toList(),
      );
    case _HomeBrowseKind.starterKits:
      return _preferLikelyPhotoFirst(
        shop
            .where(
              (p) => p.kits.any(
                (kit) =>
                    kit.lineId.endsWith('__stk') ||
                    kit.label.toLowerCase().contains('starter'),
              ),
            )
            .toList(),
      );
    case _HomeBrowseKind.bestSellers:
      final tagged = shop
          .where((p) => p.highlightTagIds.contains(_kHighlightFavouritePicks))
          .toList();
      if (tagged.isNotEmpty) return _preferLikelyPhotoFirst(tagged);
      final fallback = shop.take(4).toList();
      return _preferLikelyPhotoFirst(
        fallback.isNotEmpty ? fallback : shop.toList(),
      );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _HomeBrowseKind _browseKind = _HomeBrowseKind.flower;

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
    final desktop = Responsive.isDesktop(context);

    Widget catalogShell(Widget child) {
      if (!desktop) return child;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ShopNavigationRail(section: ShopNavSection.shop),
          Expanded(child: child),
        ],
      );
    }

    return Scaffold(
      extendBody: !desktop,
      appBar: PlantasticAppBar(
        /// Light home body behind the bar — glass mode forces white chrome, which
        /// disappears on pale mint; keep dark foreground from [AppTheme.light].
        glassChrome: false,
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () {
              HapticFeedback.lightImpact();
              final catalog = context.read<CatalogNotifier>();
              showSearch<void>(
                context: context,
                delegate: PlantSearchDelegate(
                  List<Product>.from(catalog.shopProducts),
                ),
              );
            },
            icon: const Icon(Icons.search),
          ),
          if (!desktop) const CartToolbarIconButton(),
        ],
      ),
      body: catalogShell(
        Consumer<CatalogNotifier>(
          builder: (context, catalog, _) {
          final visibleProducts =
              _visibleForBrowse(catalog.shopProducts, _browseKind);

          final compact = PlantasticLayout.compactPhone(context);
          final gridCols = PlantasticLayout.shopGridCrossAxisCount(context);
          final spacing = PlantasticLayout.shopGridCrossSpacing(context);
          final rowGap = PlantasticLayout.shopGridMainSpacing(context);

          return Consumer<CartNotifier>(
            builder: (context, cart, _) {
              final showCartStrip =
                  !desktop && cart.itemCount > 0;
              final floatPadBottom = showCartStrip
                  ? (compact ? 104.0 : 112.0) + viewPaddingBottom
                  : math.max(
                      compact ? 28.0 : 32.0,
                      viewPaddingBottom + 16,
                    );
              return AnimatedOpacity(
                opacity: catalog.loading ? 0 : 1,
                duration: AppMotion.pageLoad,
                curve: AppMotion.easeOut,
                child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7F5),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFEEF4EF),
                            const Color(0xFFF5F7F5),
                          ],
                        ),
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
                          Expanded(
                            child: CustomScrollView(
                              physics: plantasticViewportPhysics,
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      PlantasticLayout.gutter(context),
                                      12,
                                      PlantasticLayout.gutter(context),
                                      0,
                                    ),
                                    child: _HomeHeroBanner(),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 16),
                                    child: _HomeCategoryStrip(
                                      browseKind: _browseKind,
                                      onSelect: (k) =>
                                          setState(() => _browseKind = k),
                                    ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      PlantasticLayout.gutter(context),
                                      20,
                                      PlantasticLayout.gutter(context),
                                      12,
                                    ),
                                    child: Text(
                                      'Trending plants',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                            letterSpacing: -0.2,
                                          ),
                                    ),
                                  ),
                                ),
                                if (visibleProducts.isEmpty)
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Center(
                                      child: Text(
                                        'Nothing to show for this browse filter yet.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  )
                                else if (gridCols == 1)
                                  SliverPadding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          PlantasticLayout.gutter(context),
                                    ),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, i) {
                                          final last =
                                              i >= visibleProducts.length - 1;
                                          final product = visibleProducts[i];
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: last ? 0 : rowGap,
                                            ),
                                            child: StaggerGridItem(
                                              index: i,
                                              child: ScaleTap(
                                                child: DesktopHoverScale(
                                                  child: ProductShopCard(
                                                    product: product,
                                                    heroTag:
                                                        AppTheme.heroProductCover(
                                                      product.id,
                                                    ),
                                                    onTap: () {
                                                      Navigator.of(context).push(
                                                        plantasticProductDetailRoute(
                                                          product.id,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        childCount: visibleProducts.length,
                                      ),
                                    ),
                                  )
                                else
                                  SliverPadding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          PlantasticLayout.gutter(context),
                                    ),
                                    sliver: SliverGrid(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: gridCols,
                                        crossAxisSpacing: spacing,
                                        mainAxisSpacing: rowGap,
                                        /// Taller cells when only 1–2 columns so titles +
                                        /// highlights fit without clipping the footer.
                                        childAspectRatio:
                                            gridCols <= 2 ? 0.56 : 0.62,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, i) {
                                          final product = visibleProducts[i];
                                          return StaggerGridItem(
                                            index: i,
                                            child: ScaleTap(
                                              child: DesktopHoverScale(
                                                child: ProductShopCard(
                                                  product: product,
                                                  heroTag:
                                                      AppTheme.heroProductCover(
                                                    product.id,
                                                  ),
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      plantasticProductDetailRoute(
                                                        product.id,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        childCount: visibleProducts.length,
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
                  if (showCartStrip)
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
              ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}

/// Hero strip — green lives here (not full-page).
class _HomeHeroBanner extends StatelessWidget {
  const _HomeHeroBanner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                ),
              ),
            ),
            GlassCard(
              borderRadius: 0,
              blur: true,
              sigma: 14,
              fillColor: Colors.white.withValues(alpha: 0.1),
              borderColor: Colors.white.withValues(alpha: 0.28),
              padding: const EdgeInsets.all(18),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Grow your own garden 🌱',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCategoryStrip extends StatelessWidget {
  const _HomeCategoryStrip({
    required this.browseKind,
    required this.onSelect,
  });

  final _HomeBrowseKind browseKind;
  final ValueChanged<_HomeBrowseKind> onSelect;

  static const double _outerRadius = 12;
  static const double _innerRadius = 8;

  @override
  Widget build(BuildContext context) {
    final g = PlantasticLayout.gutter(context);
    final cs = Theme.of(context).colorScheme;
    final maxTrayWidth = MediaQuery.sizeOf(context).width - 2 * g;

    const segments = <(_HomeBrowseKind, String)>[
      (_HomeBrowseKind.flower, 'Flower seeds 🌸'),
      (_HomeBrowseKind.plant, 'Plant seeds 🌱'),
      (_HomeBrowseKind.starterKits, 'Starter kits 🪴'),
      (_HomeBrowseKind.bestSellers, 'Best sellers 🔥'),
    ];

    BorderRadius segmentRadius(int index, int n) {
      if (n <= 1) return BorderRadius.circular(_innerRadius);
      if (index == 0) {
        return const BorderRadius.only(
          topLeft: Radius.circular(_innerRadius),
          bottomLeft: Radius.circular(_innerRadius),
        );
      }
      if (index == n - 1) {
        return const BorderRadius.only(
          topRight: Radius.circular(_innerRadius),
          bottomRight: Radius.circular(_innerRadius),
        );
      }
      return BorderRadius.zero;
    }

    Widget segment(int index) {
      final kind = segments[index].$1;
      final label = segments[index].$2;
      final selected = browseKind == kind;
      final radius = segmentRadius(index, segments.length);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelect(kind),
          borderRadius: radius,
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: radius,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? AppColors.primary
                        : cs.onSurface.withValues(alpha: 0.72),
                    height: 1.2,
                  ),
            ),
          ),
        ),
      );
    }

    const dividerColor = Color(0xFFE2E8E4);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: g),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxTrayWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_outerRadius),
              border: Border.all(color: dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.045),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < segments.length; i++) ...[
                      if (i > 0)
                        Container(
                          width: 1,
                          height: 26,
                          color: dividerColor,
                        ),
                      segment(i),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
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
    if (AppConfig.supabaseReady && catalog.lastError == null) {
      return const SizedBox.shrink();
    }

    final offline = !AppConfig.supabaseReady;
    final icon = offline ? Icons.cloud_outlined : Icons.refresh_rounded;

    final message = offline ? _offlineHint() : catalog.lastError!;

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: offline
              ? const Color(0xFFFFF8F0)
              : cs.errorContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: offline
                ? const Color(0xFFE8DDD0)
                : cs.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: offline ? const Color(0xFFB45309) : cs.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  offline ? message : 'Sync issue: $message',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.88),
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
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: catalog.loading
                      ? PlantasticLoading.inline
                      : const Text(
                          'Retry',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
